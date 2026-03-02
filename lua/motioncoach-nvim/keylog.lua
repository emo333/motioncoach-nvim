--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class KeyLog
---@field Keylog.get_recent_keys function
---@field Keylog.install_if_needed function
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

  runtimeState.keyRingBuffer[writeIndex] = { t = timestamp, k = token }
  runtimeState.keyRingHeadIndex = (writeIndex % config.keyRingBufferSize) + 1
  runtimeState.keyRingLength = math.min(config.keyRingBufferSize, runtimeState.keyRingLength + 1)
end

---@param windowMilliseconds number
---@return table
function M.get_recent_keys(windowMilliseconds)
  local config = Config.get()
  local runtimeState = State.get()

  local keys = {}
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
      table.insert(keys, 1, item.k)
    else
      break
    end
  end

  return keys
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

    local ctrl_u = vim.api.nvim_replace_termcodes('<C-u>', true, true, true)
    local ctrl_d = vim.api.nvim_replace_termcodes('<C-d>', true, true, true)
    local scrollwheelup = vim.api.nvim_replace_termcodes('<ScrollwheelUp>', true, true, true)
    local scrollwheeldown = vim.api.nvim_replace_termcodes('<ScrollwheelDown>', true, true, true)
    local g = vim.api.nvim_replace_termcodes('g', true, true, true)
    local z = vim.api.nvim_replace_termcodes('<z>', true, true, true)
    if key == ctrl_u then
      vim.schedule(function()
        -- print('Logged: <C-u> p')
      end)
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

    -- Use vim.fn.keytrans to turn raw bytes into readable <C-a> style strings
    local readable = vim.fn.keytrans(key)

    if readable:find('^<t') then
      return
    end

    -- FIX: IF SAME ts exists in keyring then return (exclude)

    -- print(string.format('Raw (LHS): %s | Typed: %s', readable, typed))
    -- ring_push(key)
    ring_push('key: ' .. key .. ' typed: ' .. typed .. ' readable: ' .. readable)
  end, runtimeState.namespace)
  -- vim.on_key(function(key, typed)
  --   if typed ~= "" then
  --     -- This was physically pressed by the user
  --   end
  -- end)
  --   vim.on_key(function(key, rawKeyBytes)
  --     -- Be maximally defensive: ignore anything unexpected.
  --     if type(rawKeyBytes) ~= 'string' or rawKeyBytes == '' then
  --       return
  --     end
  --     -- TEST:
  --     -- vim.notify(rawKeyBytes)
  --
  --     -- keytrans itself can throw in rare cases; protect it.
  --     local ok, normalized = pcall(vim.keytrans, rawKeyBytes)
  --     -- if not ok or type(normalized) ~= 'string' or normalized == '' then
  --     --   return
  --     -- end
  --     -- vim.notify('normalized: ' .. normalized)
  --     -- No mode checks, no notify, no vim.api calls here. Just store.
  --     -- ring_push(normalized)
  --     ring_push(rawKeyBytes)
  --   end, runtimeState.namespace)
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
---@param keys {} table of strings representing keys
---@param key string key to be compared
---@return boolean
function M.key_exists_in_keyring(keys, key)
  for _, v in ipairs(keys) do
    if v == key then
      return true
    end
  end
  return false
end

return M
