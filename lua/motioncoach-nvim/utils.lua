-- INFO: Utility Functions (named it utils "Utuls" only from hearing ThePrimagen say it. LOL!)
--
local Utils = {}

---Clamp <-- sounds better than Restrict ;) a number given between a min-max range
---@param value number
---@param minimum number
---@param maximum number
---@return number
local function clampNumber(value, minimum, maximum)
  if value < minimum then
    return minimum
  end
  if value > maximum then
    return maximum
  end
  return value
end

function Utils.clampNumber(value, minimum, maximum)
  return clampNumber(value, minimum, maximum)
end

return Utils
