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
  local config = require('motioncoach-nvim.config').get()
  local traveled = math.abs(episode.to.row - episode.from.row)
  
  if traveled < (config.jumpListDistanceThreshold or 40) then
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

  -- Check for inefficient movement (e.g. mostly single-line motions)
  local small_motions = 0
  for _, k in ipairs(keys) do
    if k == 'j' or k == 'k' then small_motions = small_motions + 1 end
  end

  if small_motions > (config.jumpListSmallMotionThreshold or 10) then
    -- NOTE: increment count for buffer of times Homie has been given this suggestion.
    perBufferState.evidenceCounters.jumpBacktrackingEvidenceCount = perBufferState.evidenceCounters.jumpBacktrackingEvidenceCount
      + 1
      
    return 'Long distance traveled with repetitive motions.\nTry ` <C-u> ` / ` <C-d> ` or ` G ` / ` gg `\nor use Jump List: ` <C-o> ` / ` <C-i> `'
  end

  return nil
end

return M
