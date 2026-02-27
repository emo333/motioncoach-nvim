--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class Marks
local M = {}

local Utils = require('motioncoach-nvim.utils')

--  detection: if Homie's cursor is positioned at same row/col x times (hotspotRevisitThreshold in Config) in same buffer
--  suggestion: Yo Homie!  Use marks!
--
function M.marks_suggestion(episode, keys, perBufferState, config)
  local keyString = Utils.build_key_string(keys)
  if keyString:find(' m') or keyString:find(" '") or keyString:find(' `') then
    return nil
  end

  local key = ('%d:%d:%d'):format(episode.bufferNumber, episode.to.row, episode.to.col)
  perBufferState.hotspotVisitCountsByPositionKey[key] = (
    perBufferState.hotspotVisitCountsByPositionKey[key] or 0
  ) + 1

  if perBufferState.hotspotVisitCountsByPositionKey[key] >= config.hotspotRevisitThreshold then
    return "Marks tip: set a mark with ` ma `, jump with ` 'a ` (line) or `` `a `` (exact)."
  end

  return nil
end

return M
