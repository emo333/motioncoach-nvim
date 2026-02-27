--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class Surround
local M = {}

local Utils = require('motioncoach-nvim.utils')

local function has_any_key(keys, keySet)
  for _, k in ipairs(keys) do
    if keySet[k] then
      return true
    end
  end
  return false
end

---@param keys {}?
---@return boolean
function M.detect_surround_like(keys)
  local operatorRange = Utils.detect_last_operator_range()
  if not operatorRange then
    return false
  end
  if not keys then
    return false
  end
  local keyString = Utils.build_key_string(keys)

  if keyString:find(' ci') or keyString:find(' di') or keyString:find(' yi') then
    return false
  end

  local usedHunting =
    has_any_key(keys, { ['f'] = true, ['F'] = true, ['t'] = true, ['T'] = true, ['%'] = true })
  local usedChangeOrDelete = (
    keyString:find(' c ')
    or keyString:find(' s ')
    or keyString:find(' d ')
  ) ~= nil
  return usedHunting and usedChangeOrDelete
end

return M
