--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class CountComression
local M = {}

--  detection: Homie hammers same letter (jkhlwbe)  times
--  suggestion: Yo Homie use a count with your movements!
--
function M.count_compression(keys)
  local config = require('motioncoach-nvim.config').get()
  local limit = config.countCompressionThreshold or 5

  local allowed = { j = true, k = true, h = true, l = true, w = true, b = true, e = true }
  
  local currentToken, currentCount = nil, 0
  local maxToken, maxCount = nil, 0

  for _, token in ipairs(keys) do
    if allowed[token] then
      if token == currentToken then
        currentCount = currentCount + 1
      else
        currentToken, currentCount = token, 1
      end
    else
      currentToken, currentCount = nil, 0
    end

    if currentCount > maxCount then
      maxCount = currentCount
      maxToken = currentToken
    end
  end

  if maxToken and maxCount >= limit then
    return ('You pressed ` %s ` %d times. Try ` %d%s ` (count + motion).'):format(
      maxToken,
      maxCount,
      maxCount,
      maxToken
    )
  end

  return nil
end

return M
