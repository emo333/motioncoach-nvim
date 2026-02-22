--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

--  INFO: Formatting helper for messages in notifications
---@class Formatter
local M = {}

local Config = require('motioncoach-nvim.config')

local formatterConfig = Config.get().typedKeysFormatter

---@param token string
local function should_display_token(token)
  if not formatterConfig.enabled then
    return true
  end
  if not formatterConfig.filterNoise then
    return true
  end

  for _, pattern in ipairs(formatterConfig.noisePatterns or {}) do
    if token:match(pattern) then
      return false
    end
  end
  return true
end

---@param rawKeyTokens {} the keys Homie typed that led to this suggestion
function M.format_keys_for_display(rawKeyTokens)
  if not formatterConfig.enabled then
    return table.concat(rawKeyTokens, ' ')
  end

  local filtered = {}

  for _, token in ipairs(rawKeyTokens) do
    if should_display_token(token) then
      table.insert(filtered, token)
    end
  end

  local collapsed = {}
  if formatterConfig.collapseRepeats then
    local lastToken, repeatCount = nil, 0
    local function flush()
      if not lastToken then
        return
      end
      if repeatCount <= 1 then
        table.insert(collapsed, lastToken)
      else
        table.insert(
          collapsed,
          ('%s%s%d'):format(lastToken, formatterConfig.repeatMarker or '×', repeatCount)
        )
      end
    end

    for _, token in ipairs(filtered) do
      if token == lastToken then
        repeatCount = repeatCount + 1
      else
        flush()
        lastToken = token
        repeatCount = 1
      end
    end
    flush()
  else
    collapsed = filtered
  end

  local maxTokens = tonumber(formatterConfig.maxTokens) or 25
  if #collapsed > maxTokens then
    local startIndex = #collapsed - maxTokens + 1
    local tail = {}
    for i = startIndex, #collapsed do
      table.insert(tail, collapsed[i])
    end
    return '… ' .. table.concat(tail, ' ')
  end

  return table.concat(collapsed, ' ')
end

return M
