--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class JumpList
local M = {}

local Utils = require('motioncoach-nvim.utils')

--  detection:
--  suggestion:
--
function M.jumplist_suggestion(episode, keys, perBufferState)
  local traveled = math.abs(episode.to.row - episode.from.row)
  -- + math.abs(episode.to.col - episode.from.col)  --<-- col travel relevent??
  -- TODO: add 40 to Config
  if traveled < 40 then
    return nil
  end

  local keyString = Utils.build_key_string(keys)
  local usedJumpKeys = keyString:find('<C%-o>')
    or keyString:find('<C%-i>')
    or keyString:find(' `` ')
    or keyString:find(" '' ")
  if usedJumpKeys then
    return nil
  end

  -- NOTE: increment count for buffer of times Homie has been given this suggestion.  This will be used for 'Plugin Recomendations'
  perBufferState.evidenceCounters.jumpBacktrackingEvidenceCount = perBufferState.evidenceCounters.jumpBacktrackingEvidenceCount
    + 1

  return ' --JUMPLIST SUGGESTION--\n\n ` <C-o> ` backward | ` <C-i> ` forward | ` `` ` toggle'
end

return M
