-- INFO: Plugin suggestions
-- e.g. "Homie, you are doing a lot of jumping around.  A good plugin to consider for jumping around is 'Harpoon2'"
-- e.g. "Homie, you are searching your butt off.  A good plugin to consider for searching around is 'Telescope'"

local Plugins = {}

local Config = require('motioncoach-nvim.config')

function Plugins.recommend(perBufferState, context)
  local pluginConfig = Config.get().pluginRecommendations
  if not pluginConfig or not pluginConfig.enabled then
    return nil
  end

  -- Provider hook wins (lets you update recommendations externally without touching core logic)
  if type(pluginConfig.provider) == 'function' then
    local ok, result = pcall(pluginConfig.provider, perBufferState.evidenceCounters, context)
    if ok and type(result) == 'string' and result ~= '' then
      return result
    end
  end

  -- Default evidence-based recommendations
  local items = pluginConfig.items or {}
  for _, item in pairs(items) do
    if item.enabled then
      local evidenceKey = item.evidenceKey
      local threshold = tonumber(item.threshold) or tonumber(pluginConfig.thresholdDefault) or 10
      local currentEvidence = perBufferState.evidenceCounters[evidenceKey] or 0
      if currentEvidence >= threshold then
        perBufferState.evidenceCounters[evidenceKey] = 0
        return item.message
      end
    end
  end

  return nil
end

return Plugins
