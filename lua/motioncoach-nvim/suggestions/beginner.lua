local Beginner = {}

local function first_nonblank_col(lineText)
  local _, endingIndex = lineText:find('^%s*')
  return (endingIndex or 0)
end

function Beginner.suggest(episode, context)
  local from, to = episode.from, episode.to
  local lineDelta = to.row - from.row
  local colDelta = to.col - from.col
  local absLineDelta, absColDelta = math.abs(lineDelta), math.abs(colDelta)

  local destinationLineText = context.get_line(episode.bufferNumber, to.row)

  if absLineDelta == 0 then
    if to.col == 0 then
      return 'Try `0` to jump to start of line.'
    end

    local fnc = first_nonblank_col(destinationLineText)
    if destinationLineText:match('%S') and to.col == fnc then
      return 'Try `^` to jump to first non-blank on the line.'
    end

    if #destinationLineText > 0 and to.col >= (#destinationLineText - 1) then
      return 'Try `$` to jump to end of line.'
    end
  end

  if absLineDelta >= 6 and absLineDelta < 60 then
    local motion = (lineDelta > 0) and 'j' or 'k'
    return ('Try `%d%s` to move %d lines in one go.'):format(absLineDelta, motion, absLineDelta)
  end

  if absLineDelta >= vim.api.nvim_win_get_height(0) then
    local scroll = (lineDelta > 0) and '<C-d>' or '<C-u>'
    return ('Big move: try `%s` to scroll a screenful (then adjust).'):format(scroll)
  end

  if absLineDelta == 0 and absColDelta >= 8 then
    return 'For long horizontal moves, try a count (`10l`) or move by words with `w`/`b`.'
  end

  if absLineDelta >= 200 then
    local which = (lineDelta > 0) and '`G` (end of file)' or '`gg` (top of file)'
    return ('Huge move: consider %s when navigating far.'):format(which)
  end

  return nil
end

return Beginner
