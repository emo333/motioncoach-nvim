--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

local M = {}

---@alias Episode {value: table, context: {row: number, col: number}}
---@alias Context {value: table, context: {row: number, col: number}}

---@class Beginner
---@field suggest (fun(episode: Episode, context: Context): string?)

local Config = require('motioncoach-nvim.config')
local Keylog = require('motioncoach-nvim.keylog')

---@return {} | nil
local function detect_last_operator_range() --- Gets the range of the last operator and puts it in a nice little table
  local startPos = vim.fn.getpos("'^")
  local endPos = vim.fn.getpos("']")
  if not startPos or not endPos then
    return nil
  end
  if startPos[2] == 0 or endPos[2] == 0 then
    return nil
  end

  return {
    bufferNumber = startPos[1],
    startRow = startPos[2],
    startCol = startPos[3] - 1,
    endRow = endPos[2],
    endCol = endPos[3] - 1,
  }
end

--  TODO: may not need these functions in this module... only need it if we going to send Homie his keystrokes.
--
-- local function build_key_string(keys)
--   return ' ' .. table.concat(keys, ' ') .. ' '
-- end
--
-- local function has_any_key(keys, keySet) --- Do it have keys??
--   for _, k in ipairs(keys) do
--     if keySet[k] then
--       return true
--     end
--   end
--   return false
-- end
--
-- ---@function --turns concurrent keys into single string.  example: `h`,`h`,`h`,`h` ~ `4h`
-- ---@return string | nil
-- local function count_compression(keys)
--   local allowed = { j = true, k = true, h = true, l = true, w = true, b = true, e = true }
--   local lastToken, repeatCount = nil, 0
--
--   for _, token in ipairs(keys) do
--     if allowed[token] then
--       if token == lastToken then
--         repeatCount = repeatCount + 1
--       else
--         lastToken, repeatCount = token, 1
--       end
--     else
--       lastToken, repeatCount = nil, 0
--     end
--   end
--
--   if lastToken and repeatCount >= 5 then
--     return ('You pressed `%s` %d times. Try `%d%s` (count + motion).'):format(
--       lastToken,
--       repeatCount,
--       repeatCount,
--       lastToken
--     )
--   end
--   return nil
-- end

---@param lineText string
---@return number | nil
local function first_nonblank_col(lineText)
  local _, endingIndex = lineText:find('^%s*')

  return (endingIndex or 0)
end

---@return string | nil # The suggestion message | nil
function M.suggest(episode, context)
  local config = Config.get()
  -- local runtimeState = context.runtimeState
  -- local perBufferState = context.perBufferState
  local recentKeys = Keylog.get_recent_keys(config.keyPatternWindowMilliseconds)
  local from, to = episode.from, episode.to
  local lineDelta = to.row - from.row
  local colDelta = to.col - from.col
  local absLineDelta, absColDelta = math.abs(lineDelta), math.abs(colDelta)

  -------------------- HORIZONTAL MOTIONS

  local destinationLineText = context.get_line(episode.bufferNumber, to.row)

  if absLineDelta == 0 then
    if to.col == 0 then
      if not Keylog.key_exists_in_keyring(recentKeys, '0') then
        return 'Try ` 0 ` to jump to start of line'
      end
    end

    local first_nonblank_col_in_line = first_nonblank_col(destinationLineText)
    if destinationLineText:match('%S') and to.col == first_nonblank_col_in_line then
      return 'Try ` ^ ` to jump to first non-blank character of line'
    end

    if #destinationLineText > 0 and to.col >= (#destinationLineText - 1) then
      return 'Try ` $ ` to jump to end of line'
    end
  end

  -- TODO: make user configurable 7
  if absLineDelta == 0 and absColDelta >= 7 then
    return 'For long horizontal moves, you can move by words with:\n ` w ` or ` b ` or ` e `\n ( ` W ` or ` B ` or ` E `\n  Or Can prefix count (` 8h ` or ` 16l `)'
    -- TODO: for advanvced mode suggest using `f`/`F` (maybe this is where a plugin check is done to see if Homie has flash.nvim installed and only if so, suggest using `s`+{a-Z0-9})
  end

  -------------------- VERTICAL MOTIONS

  -- TODO: check for folds(closed) between from.row and to.row and subtract folddelta from delta

  local total_lines = vim.api.nvim_buf_line_count(0)
  if total_lines == to.row or to.row == 1 then
    if absLineDelta >= 10 then
      local which = (lineDelta > 0) and '` G ` to move to end of file'
        or '` gg ` to move to top of file'

      return ('Consider using %s'):format(which)
    end
  end

  -- vim.notify(vim.inspect(recentKeys))

  -- TODO: make user configurable 6 and 60
  if absLineDelta >= 6 and absLineDelta < 60 then
    local motion = (lineDelta > 0) and 'j' or 'k'
    local formattedMotion = ('Try ` %d%s ` to move %d lines'):format(
      absLineDelta + 1,
      motion,
      absLineDelta + 1
    )
    local rln = ''
    if not vim.wo.relativenumber then
      rln = '\n\n'
        .. [[  * Consider using 'Relative Line Numbers'

    - to see the count of lines from the line your are on]]
    end

    return formattedMotion .. rln
  end

  if absLineDelta >= 200 then
    local which = (lineDelta > 0) and '` / ` (search downward)' or '` ? ` (search upward)'

    return ('Huge move: consider %s for your target text'):format(which)
  end

  if absLineDelta >= vim.api.nvim_win_get_height(0) then
    -- FIX: if last keys{from keylogger} were NOT '<C-d>' or '<C-u>'
    -- NOTE: possibly handle this by finalizing episode on detection of '<C-d>' or '<C-u>'
    local scroll = (lineDelta > 0) and ' <C-d> ' or ' <C-u> '

    return ('Big move: try `%s` to scroll'):format(scroll)
  end

  return nil
end

return M
