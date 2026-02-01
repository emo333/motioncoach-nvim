-- INFO: An Episode is a tracked series of cursor movements (Vim Motions) and/or key strokes
-- the premise is to limit the count of key strokes to achieve the movement of the cursor (Vim Motion).
local Advanced = require('motioncoach-nvim.suggestions.advanced')
local Beginner = require('motioncoach-nvim.suggestions.beginner')
local Config = require('motioncoach-nvim.config')
local Episodes = {}
local Formatter = require('motioncoach-nvim.formatter')
local Keylog = require('motioncoach-nvim.keylog')
local Notify = require('motioncoach-nvim.notify')
local Registers = require('motioncoach-nvim.registers')
local State = require('motioncoach-nvim.state')

---@return number ... current time in milliseconds
local function now_ms()
  return math.floor(vim.uv.hrtime() / 1e6)
end

-- TODO: Need to handle this for other notifiers (plugins) besides snacks.notify
local function notify(message)
  Notify.send('MotionCoach: ' .. message, Config.get().notifyLogLevel)
end

local function get_line(bufferNumber, row1)
  return vim.api.nvim_buf_get_lines(bufferNumber, row1 - 1, row1, false)[1] or ''
end

local function clampNumber(value, minimum, maximum)
  if value < minimum then
    return minimum
  end
  if value > maximum then
    return maximum
  end
  return value
end

---@return boolean ... Is mode n/v/V/<C-v>/o ?
local function is_motion_mode(modeString)
  return modeString == 'n'
    or modeString == 'v'
    or modeString == 'V'
    or modeString == '\22' -- <C-v>
    or modeString == 'o'
end

local function get_cursor()
  local c = vim.api.nvim_win_get_cursor(0)
  return { row = c[1], col = c[2] }
end

local function estimate_naive_cost(episode)
  local dl = math.abs(episode.to.row - episode.from.row)
  local dc = math.abs(episode.to.col - episode.from.col)
  if dl == 0 then
    return dc
  end
  return dl
end

local function can_suggest(runtimeState)
  local config = Config.get()
  if config.coachingLevel == 0 then
    return false
  end
  local t = now_ms()
  if t < runtimeState.suppressSuggestionsUntilMilliseconds then
    return false
  end
  if
    (t - runtimeState.lastSuggestionTimestampMilliseconds) < config.suggestionCooldownMilliseconds
  then
    return false
  end
  return true
end

local function emit(message, typedKeys)
  local config = Config.get()
  local runtimeState = State.get()
  runtimeState.lastSuggestionTimestampMilliseconds = now_ms()

  if config.coachingLevel >= 2 and typedKeys and #typedKeys > 0 then
    local formatted = Formatter.format_keys_for_display(typedKeys)
    notify(message .. '\nYou typed: ' .. formatted)
  else
    notify(message)
  end
end

local function update_undo_suppression(bufferNumber)
  local config = Config.get()
  local runtimeState = State.get()
  local perBufferState = State.get_or_create_per_buffer(bufferNumber)

  local undoTree = vim.fn.undotree()
  local currentSeq = undoTree and undoTree.seq_cur or nil
  if not currentSeq then
    return
  end

  if perBufferState.lastUndoSequenceNumber == nil then
    perBufferState.lastUndoSequenceNumber = currentSeq
    return
  end

  if currentSeq < perBufferState.lastUndoSequenceNumber then
    runtimeState.suppressSuggestionsUntilMilliseconds = now_ms()
      + config.undoSuppressionMilliseconds
  end

  perBufferState.lastUndoSequenceNumber = currentSeq
end

local function finalize_episode()
  local config = Config.get()
  local runtimeState = State.get()
  local episode = runtimeState.currentEpisode
  runtimeState.currentEpisode = nil
  if not episode then
    return
  end
  if config.coachingLevel == 0 then
    return
  end
  if not can_suggest(runtimeState) then
    return
  end

  local naive = estimate_naive_cost(episode)
  if naive < config.minimumNaiveCostToCoach then
    return
  end

  local context = {
    runtimeState = runtimeState,
    perBufferState = State.get_or_create_per_buffer(episode.bufferNumber),
    get_line = get_line,
  }

  -- Always try beginner first (even in advanced) to avoid “too fancy too soon”
  local beginnerTip = Beginner.suggest(episode, context)
  if beginnerTip then
    emit(beginnerTip, nil)
    return
  end

  if config.coachingLevel >= 2 then
    local advancedTip, typedKeys = Advanced.suggest(episode, context)
    if advancedTip then
      emit(advancedTip, typedKeys)
      return
    end
  end
end

local function start_episode(bufferNumber, cursorPos, currentTimeMs, modeString)
  local runtimeState = State.get()
  runtimeState.currentEpisode = {
    bufferNumber = bufferNumber,
    from = cursorPos,
    to = cursorPos,
    timeFromMs = currentTimeMs,
    timeToMs = currentTimeMs,
    mode = modeString,
  }
end

-- INFO: When Homie moves the cursor, do all this...
local function on_cursor_moved()
  local config = Config.get()
  local runtimeState = State.get()

  if config.coachingLevel == 0 then
    finalize_episode()
    return
  end

  local currentMode = vim.api.nvim_get_mode().mode
  if not is_motion_mode(currentMode) then
    finalize_episode()
    return
  end

  if (not config.captureInsertModeKeys) and currentMode == 'i' then
    finalize_episode()
    return
  end

  local bufferNumber = vim.api.nvim_get_current_buf()
  update_undo_suppression(bufferNumber)

  local currentTimeMs = now_ms()
  local cursorPos = get_cursor()

  if not runtimeState.currentEpisode then
    start_episode(bufferNumber, cursorPos, currentTimeMs, currentMode)
    return
  end

  ---@class episode
  ---@field bufferNumber number
  ---@field to {}
  ---@field timeToMs number
  local episode = runtimeState.currentEpisode
  if
    episode.bufferNumber ~= bufferNumber
    or (currentTimeMs - episode.timeToMs) > config.episodeGapMilliseconds
  then
    finalize_episode()
    start_episode(bufferNumber, cursorPos, currentTimeMs, currentMode)
    return
  end

  episode.to = cursorPos
  episode.timeToMs = currentTimeMs
end

function Episodes.set_coaching_level(level)
  level = tonumber(level) or 0
  level = clampNumber(level, 0, 2)

  local config = Config.get()
  config.coachingLevel = level

  if level == 0 then
    Keylog.uninstall_if_needed()
    finalize_episode()
    notify('Coaching OFF (level 0).')
  elseif level == 1 then
    Keylog.install_if_needed()
    notify('Beginner coaching ON (level 1).')
  else
    Keylog.install_if_needed()
    notify('Advanced coaching ON (level 2).')
  end
end

function Episodes.toggle_level()
  local config = Config.get()
  Episodes.set_coaching_level((config.coachingLevel + 1) % 3)
end

function Episodes.install_autocmds()
  local augroup = vim.api.nvim_create_augroup('MotionCoach', { clear = true })

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = augroup,
    callback = function()
      if (not Config.get().captureInsertModeKeys) and vim.api.nvim_get_mode().mode == 'i' then
        return
      end
      on_cursor_moved()
    end,
  })

  vim.api.nvim_create_autocmd({ 'ModeChanged', 'BufLeave', 'WinLeave' }, {
    group = augroup,
    callback = function()
      finalize_episode()
    end,
  })

  vim.api.nvim_create_autocmd('TextYankPost', {
    group = augroup,
    callback = function(ev)
      Registers.capture_yank(ev)
    end,
  })

  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'TextChangedP' }, {
    group = augroup,
    callback = function(args)
      update_undo_suppression(args.buf)
    end,
  })

  -- Commands
  vim.api.nvim_create_user_command('MotionCoachOff', function()
    Episodes.set_coaching_level(0)
  end, {})
  vim.api.nvim_create_user_command('MotionCoachBeginner', function()
    Episodes.set_coaching_level(1)
  end, {})
  vim.api.nvim_create_user_command('MotionCoachAdvanced', function()
    Episodes.set_coaching_level(2)
  end, {})
  vim.api.nvim_create_user_command('MotionCoachToggle', function()
    Episodes.toggle_level()
  end, {})
  vim.api.nvim_create_user_command('MotionCoachLevel', function(opts)
    Episodes.set_coaching_level(opts.args)
  end, {
    nargs = 1,
    complete = function()
      return { '0', '1', '2' }
    end,
  })
end

return Episodes
