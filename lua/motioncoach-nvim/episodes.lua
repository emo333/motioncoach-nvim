--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------
--
-- INFO: An Episode is a tracked series of cursor movements (Vim Motions) and/or key strokes
-- the premise is to limit the count of key strokes to achieve the movement of the cursor (Vim Motion).

local M = {}

local Advanced = require('motioncoach-nvim.suggestions.advanced')
local Beginner = require('motioncoach-nvim.suggestions.beginner')
local Config = require('motioncoach-nvim.config')
local Formatter = require('motioncoach-nvim.formatter')
local Keylog = require('motioncoach-nvim.keylog')
local Logger = require('motioncoach-nvim.logger')
local Notify = require('motioncoach-nvim.notify')
local VimRegisters = require('motioncoach-nvim.vimregisters')
local State = require('motioncoach-nvim.state')
local Utils = require('motioncoach-nvim.utils')

-- TODO: Need to handle this for other notifiers (plugins) besides snacks.notify
local function notify(message)
  Notify.send(message, Config:get().notifyLogLevel)
end

local function get_line(bufferNumber, row1)
  return vim.api.nvim_buf_get_lines(bufferNumber, row1 - 1, row1, false)[1] or ''
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
  local t = Utils.now_ms()
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

---@param message string the suggested message to dsiplay
---@param typedKeys {} the keys Homie typed that led to this suggestion
---@function nil # Sends the suggested message notification.
---# EMIT  IT BABAYYYY!!!
local function emit(message, typedKeys)
  local config = Config.get()
  local runtimeState = State.get()
  runtimeState.lastSuggestionTimestampMilliseconds = Utils.now_ms()

  if config.coachingLevel >= 2 and typedKeys and #typedKeys > 0 then
    local formatted = Formatter.format_keys_for_display(typedKeys)
    notify(message .. '\nYou typed: ' .. formatted)
  else
    notify(message)
  end
end

---@param bufferNumber integer
---@return nil
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
    runtimeState.suppressSuggestionsUntilMilliseconds = Utils.now_ms()
      + config.undoSuppressionMilliseconds
  end

  perBufferState.lastUndoSequenceNumber = currentSeq
end

-- Finalizes the episode, if all requirements are met, by emitting a notification with respective suggestion.
local function finalize_episode()
  local config = Config.get()
  local runtimeState = State.get()
  -- local bufferNumber = vim.api.nvim_get_current_buf()
  -- local perBufferState = State.get_or_create_per_buffer(bufferNumber)

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
  -- vim.notify(tostring(naive))
  if naive < config.minimumNaiveCostToCoach then
    return
  end

  local context = {
    runtimeState = runtimeState,
    perBufferState = State.get_or_create_per_buffer(episode.bufferNumber),
    get_line = get_line,
  }

  if config.coachingLevel == 1 then
    local beginnerTip = Beginner.suggest(episode, context)
    if beginnerTip then
      -- Logger:log('BeginnerTip:', beginnerTip, beginnerTip, vim.cmd('split'))
      emit(beginnerTip, nil)
      -- Logger:show()
      return
    end
  end

  if config.coachingLevel >= 2 then
    local advancedTip, typedKeys = Advanced.suggest(episode, context)
    if advancedTip then
      emit(advancedTip, typedKeys)
      return
    end
  end
end

-- 💩
local function start_episode(bufferNumber, cursorPos, currentTimeMs, modeString)
  --
  -- TEST: Get info for the current window
  -- vim.notify(vim.inspect(vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]))
  -- TEST: Get info for the current buffer
  -- local current_buffer_info = vim.fn.getbufinfo(vim.api.nvim_get_current_buf())[1]
  -- vim.notify(vim.inspect(vim.fn.getbufinfo(vim.api.nvim_get_current_buf())[1]))

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

local function restart_episode(bufferNumber, cursorPos, currentTimeMs, modeString)
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

  local currentTimeMs = Utils.now_ms()
  local cursorPos = get_cursor()

  if not runtimeState.currentEpisode then
    start_episode(bufferNumber, cursorPos, currentTimeMs, currentMode)
    -- BUG: This may be a problem.  Might need to return here
    -- return
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

  local function has_exclude_match(recentKeys, excludeKeys)
    local lookup = {}
    for _, value in pairs(excludeKeys) do
      lookup[value] = true
    end

    for _, value in pairs(recentKeys) do
      if lookup[value] then
        return value
      end
    end

    return nil
  end

  -- TODO: refactor the key check into keylog.lua

  local excludeKeys = {
    '\27',
    'w',
    'W',
    'b',
    'B',
    'e',
    'E',
    'o',
    'f',
    'q',
    '0',
    '$',
    'g',
    'G',
    '\4', --??
    '\21', -- ??
    '\18', -- ??
    '^[', -- <Esc>
    '<C-u>',
    '<80><fc>\\4D',
    '\4D',
    '<80><fc>K', -- ScrollWheelUp
    '<80><fc>L', -- ScrollWheelDown
    '<ScrollWheelUp>',
    '<ScrollWheelDown>',
  }
  -- local config = Config.get()

  currentMode = vim.api.nvim_get_mode().mode
  local keys = Keylog.get_recent_keys(config.keyPatternWindowMilliseconds)
  -- TEST:
  -- vim.notify('lastKey: ' .. vim.inspect(keys))
  -- vim.notify('excludeKeys: ' .. vimpect(excludeKeys))
  -- vim.notify('keys: ' .. vim.inspect(keys))

  local match = has_exclude_match(keys, excludeKeys)
  if match then
    vim.notify(match .. ' key ::::::::::::EXCLUSION')
    start_episode(bufferNumber, cursorPos, currentTimeMs, currentMode)
    return
  end

  episode.to = cursorPos
  episode.timeToMs = currentTimeMs
end

---@param level number | nil 0 = off | 1 = Beginner | 2 = Advanced
function M.set_coaching_level(level)
  level = tonumber(level) or 0
  level = Utils.clampNumber(level, 0, 2)

  local config = Config.get()
  config.coachingLevel = level

  if level == 0 then
    Keylog.uninstall_if_needed()
    finalize_episode()
    notify('Coaching OFF')
  elseif level == 1 then
    Keylog.install_if_needed()
    notify('Beginner coaching ON (level 1).')
  else
    Keylog.install_if_needed()
    notify('Advanced coaching ON (level 2).')
  end
end

function M.install_autocmds()
  local augroup = vim.api.nvim_create_augroup('MotionCoach', { clear = true })

  vim.api.nvim_create_autocmd({ 'WinEnter', 'BufWinEnter' }, {
    group = augroup,
    callback = function()
      vim.keymap.set('n', '<ScrollWheelUp>', function()
        vim.notify_once('Scrolling with mouse is cheating...')
        return '<ScrollWheelUp>'
      end, { expr = true, noremap = true, buffer = true })
      vim.keymap.set('n', '<ScrollWheelDown>', function()
        vim.notify_once('Scrolling with mouse is cheating...')
        return '<ScrollWheelDown>'
      end, { expr = true, noremap = true, silent = true, buffer = true })
    end,
  })

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
      vim._notify_once_cache = {}
    end,
  })

  vim.api.nvim_create_autocmd('TextYankPost', {
    group = augroup,
    callback = function(ev)
      VimRegisters.capture_yank(ev)
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
    M.set_coaching_level(0)
  end, {})
  vim.api.nvim_create_user_command('MotionCoachBeginner', function()
    M.set_coaching_level(1)
  end, {})
  vim.api.nvim_create_user_command('MotionCoachAdvanced', function()
    M.set_coaching_level(2)
  end, {})
  vim.api.nvim_create_user_command('MotionCoachLevel', function(opts)
    M.set_coaching_level(tonumber(opts.args))
  end, {
    nargs = 1,
    complete = function()
      return { '0', '1', '2' }
    end,
  })
end

return M
