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

  local timestamp = Utils.now_ms()
  local writeIndex = runtimeState.keyRingHeadIndex

  runtimeState.keyRingBuffer[writeIndex] = { t = timestamp, k = token }
  runtimeState.keyRingHeadIndex = (writeIndex % config.keyRingBufferSize) + 1
  runtimeState.keyRingLength = math.min(config.keyRingBufferSize, runtimeState.keyRingLength + 1)
  -- vim.notify('here in ring_push')
  -- vim.notify(#runtimeState.keyRingBuffer)
  -- local msg = tostring(vim.fn.bufnr())
  -- TEST:
  -- vim.notify('runtimeState.keyRingBuffer' .. msg)
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
  -- TEST:
  -- vim.notify(vim.inspect(keys), 4)
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
  local ctrl_u = vim.api.nvim_replace_termcodes('<C-u>', true, true, true)
  local ctrl_d = vim.api.nvim_replace_termcodes('<C-d>', true, true, true)
  local scrollwheelup = vim.api.nvim_replace_termcodes('<ScrollwheelUp>', true, true, true)
  local scrollwheeldown = vim.api.nvim_replace_termcodes('<ScrollwheelDown>', true, true, true)
  local g = vim.api.nvim_replace_termcodes('g', true, true, true)
  local z = vim.api.nvim_replace_termcodes('<z>', true, true, true)
  vim.on_key(function(key, typed)
    if key == ctrl_u then
      vim.schedule(function()
        print('Logged: <C-u> pressed')
      end)
    end
    if key == ctrl_d then
      vim.schedule(function()
        print('Logged: <C-d> pressed')
      end)
    end
    if key == scrollwheelup then
      vim.schedule(function()
        print('Logged: <ScrollwheelUp> pressed')
      end)
    end
    if key == scrollwheeldown then
      vim.schedule(function()
        print('Logged: <ScrollwheelDown> pressed')
      end)
    end
    if typed == g then
      vim.schedule(function()
        print('Logged: g pressed')
      end)
    end
    if key == z then
      vim.schedule(function()
        print('Logged: z pressed')
      end)
    end
    -- Use vim.fn.keytrans to turn raw bytes into readable <C-a> style strings
    local readable = vim.fn.keytrans(key)
    print(string.format('Raw (LHS): %s | Typed: %s', readable, typed))
    ring_push(key)
  end)
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
