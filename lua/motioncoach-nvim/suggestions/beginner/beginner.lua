--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class Beginner
local M = {}

-- local Config = require('motioncoach-nvim.config')
local Keylog = require('motioncoach-nvim.keylog')

---@param lineText string
---@return number | nil
local function first_nonblank_col(lineText)
  local _, endingIndex = lineText:find('^%s*')

  return (endingIndex or 0)
end

---@param episode {}
---@param context {}
---@return string | nil # The suggestion message | nil
function M.suggest(episode, context)
  -- local config = Config.get()
  -- local runtimeState = context.runtimeState
  -- local perBufferState = context.perBufferState
  -- local recentKeys = Keylog.get_recent_keys(config.keyPatternWindowMilliseconds)
  local from, to = episode.from, episode.to
  local lineDelta = to.row - from.row
  local colDelta = to.col - from.col
  local absLineDelta, absColDelta = math.abs(lineDelta), math.abs(colDelta)

  -------------------- HORIZONTAL MOTIONS

  local destinationLineText = context.get_line(episode.bufferNumber, to.row)

  if absLineDelta == 0 then
    if to.col == 0 then
      if not Keylog.key_exists_in_keyring(nil, '0') then
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
