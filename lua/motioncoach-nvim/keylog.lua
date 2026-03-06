--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class KeyLog
---@field Keylog.get_recent_keys function
---@field Keylog.uninstall_if_needed function
---@field Keylog.key_exists_in_keyring function
local M = {}

local Config = require('motioncoach-nvim.config')
local State = require('motioncoach-nvim.state')
local Utils = require('motioncoach-nvim.utils')

local function ring_push(token)
  local config = Config.get()
  local runtimeState = State.get()
  if config.coachingLevel == 0 then
    runtimeState.keyRingBuffer = {}
    return
  end

  local timestamp = Utils.now_ms()
  local writeIndex = runtimeState.keyRingHeadIndex
  local c = vim.api.nvim_win_get_cursor(0)
  local cursorPos = { row = c[1], col = c[2] }

  runtimeState.keyRingBuffer[writeIndex] =
    { t = timestamp, k = token, c = c, bufnr = vim.api.nvim_get_current_buf() }
  runtimeState.keyRingHeadIndex = (writeIndex % config.keyRingBufferSize) + 1
  runtimeState.keyRingLength = math.min(config.keyRingBufferSize, runtimeState.keyRingLength + 1)
end

---@function
---@param windowMilliseconds number
---@return {} -- keys typed between now and however many {windowMilliseconds} ago
function M.get_recent_keys(windowMilliseconds)
  local config = Config.get()
  local runtimeState = State.get()

  local recentKeys = {}
  local cutoff = Utils.now_ms() - windowMilliseconds

  local itemCount = runtimeState.keyRingLength
  local headIndex = runtimeState.keyRingHeadIndex

  for i = 1, itemCount do
    local idx = headIndex - i
    if idx <= 0 then
      idx = idx + config.keyRingBufferSize
    end
    local item = runtimeState.keyRingBuffer[idx]
    if item and item.t >= cutoff then
      table.insert(recentKeys, 1, item.k)
    else
      break
    end
  end

  return recentKeys
end

-- TODO: NEED TO TEST with kickstart-nvim and bare bones nvim before removimg testing code below

-- Hook in the Keylogger
function M.install_if_needed()
  local runtimeState = State.get()
  if runtimeState.onKeyHookInstalled then
    return
  end
  runtimeState.onKeyHookInstalled = true

  -- TODO: handle double taps of j and k (they are getting remapped to g)
  vim.on_key(function(key, typed)
    -- only log for certain buffer types:
    if vim.bo.bh ~= '' then
      return
    end
    -- vim.notify(vim.fn.keytrans(typed))
    local ctrl_u = vim.api.nvim_replace_termcodes('<C-u>', true, true, true)
    local ctrl_d = vim.api.nvim_replace_termcodes('<C-d>', true, true, true)
    local scrollwheelup = vim.api.nvim_replace_termcodes('<ScrollwheelUp>', true, true, true)
    local scrollwheeldown = vim.api.nvim_replace_termcodes('<ScrollwheelDown>', true, true, true)
    local g = vim.api.nvim_replace_termcodes('g', true, true, true)
    local z = vim.api.nvim_replace_termcodes('<z>', true, true, true)
    if key == ctrl_u or key == ctrl_d then
      return
    end
    if key == scrollwheeldown or key == scrollwheelup then
      return
    end
    if key == g and (typed == 'j' or typed == 'k') then
      return
    end
    if key == g then
      key = 'g'
    end

    -- ignore anything unexpected
    if type(key) ~= 'string' or key == '' then
      -- return
    end

    -- Use vim.fn.keytrans to turn raw bytes into readable <C-a> style strings
    -- keytrans itself can throw in rare cases; protect it with a pcall()
    local ok, readable = pcall(vim.fn.keytrans, typed)
    if not ok or type(readable) ~= 'string' or readable == '' then
      return
    end
    -- local readable = vim.fn.keytrans(key)
    if readable:find('^<t') then
      return
    end
    if key:find('^<t') and typed ~= ' ' then
      -- return
    end
    if
      readable:find('<LeftDrag>')
      or readable:find('<LeftRelease>')
      or readable:find('<LeftMouse>')
      or readable:find('<RightMouse>')
      or readable:find('<RightDrag>')
      or readable:find('<RightRelease>')
      or readable:find('<MouseMove>')
    then
      return
    end
    if readable == 'g' and key ~= 'g' then
      return
    end
    if readable:find('<Space>') and readable ~= '<Space>' then
      return
    end
    -- vim.notify(readable)
    -- FIX: IF SAME ts exists in keyring then return (exclude)

    ring_push(readable)
    -- ring_push('key: ' .. key .. ' typed: ' .. typed .. ' readable: ' .. readable)
  end, runtimeState.namespace)
end

-- UnHook the Keylogger
function M.uninstall_if_needed()
  local runtimeState = State.get()
  if not runtimeState.onKeyHookInstalled then
    return
  end
  runtimeState.onKeyHookInstalled = false
  vim.on_key(nil, runtimeState.namespace)
end

---@function
---@param keys {} | nil table of strings representing keys OR nil to uise default recent keys
---@param key string key to be compared
---@return boolean
function M.key_exists_in_keyring(keys, key)
  if keys == nil then
    local config = Config.get()
    keys = M.get_recent_keys(config.keyPatternWindowMilliseconds)
  end
  for _, v in ipairs(keys) do
    if v == key then
      return true
    end
  end
  return false
end

---@function given a table of keys to exclude, comapres to "recent keys"
---@param excludeKeys {} table of strings representing keys to match(exclude) against
---@return string | nil returns either the first key matched or nil (no match)
function M.has_exclude_match(excludeKeys)
  local config = Config.get()
  local recentKeys = M.get_recent_keys(config.keyPatternWindowMilliseconds)
  local lookup = {}
  for _, value in pairs(excludeKeys) do
    lookup[value] = true
  end

  for _, value in pairs(recentKeys) do
    if lookup[value] then
      return value
    end
  end

  return nil
end

return M
