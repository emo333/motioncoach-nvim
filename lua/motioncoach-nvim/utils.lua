-- INFO: Utility Functions (named it utils "Utuls" only from hearing ThePrimagen say it. LOL!)
--
local Utils = {}

local function clampNumber(value, minimum, maximum)
  if value < minimum then
    return minimum
  end
  if value > maximum then
    return maximum
  end

  vim.notify('Utils.clampNumber: ' .. value, 3)

  return value
end

function Utils.clampNumber(value, minimum, maximum)
  return clampNumber(value, minimum, maximum)
end

return Utils
