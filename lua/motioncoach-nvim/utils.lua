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

---@return number now_ms current time in milliseconds
function Utils.now_ms()
  local uv = vim.uv or vim.loop -- if older neovim version, use vim.loop
  local hrtime = uv and uv.hrtime and uv.hrtime() or nil
  -- print('[MOTIONCOACH DEBUG] vim.uv:', vim.uv, ', vim.loop:', vim.loop, ', hrtime:', hrtime)
  if hrtime then
    return math.floor(hrtime / 1e6)
  end
  error('No uv.hrtime() available (unsupported Neovim version?)')
end

return Utils
