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
  local allowed = { j = true, k = true, h = true, l = true, w = true, b = true, e = true }
  local lastToken, repeatCount = nil, 0

  for _, token in ipairs(keys) do
    if allowed[token] then
      if token == lastToken then
        repeatCount = repeatCount + 1
      else
        lastToken, repeatCount = token, 1
      end
    else
      lastToken, repeatCount = nil, 0
    end
  end

  if lastToken and repeatCount >= 10 then
    return ('You pressed ` %s ` %d times. Try ` %d%s ` (count + motion).'):format(
      lastToken,
      repeatCount,
      repeatCount,
      lastToken
    )
  end

  return nil
end

return M
