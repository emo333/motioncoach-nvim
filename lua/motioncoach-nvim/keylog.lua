local Config = require('motioncoach-nvim.config')
local State = require('motioncoach-nvim.state')

local Keylog = {}

local function now_ms()
  return math.floor(vim.loop.hrtime() / 1e6)
end

local function normalize_key(rawKeyBytes)
  return vim.keytrans(rawKeyBytes)
end

local function should_capture_key(normalizedKeyToken)
  local config = Config.get()
  local currentMode = vim.api.nvim_get_mode().mode

  if config.coachingLevel == 0 then
    return false
  end
  if (not config.captureInsertModeKeys) and currentMode == 'i' then
    return false
  end
  if (not config.captureCommandLineKeys) and currentMode == 'c' then
    return false
  end
  if not normalizedKeyToken or normalizedKeyToken == '' then
    return false
  end

  return true
end

local function ring_push(normalizedKeyToken)
  local config = Config.get()
  local runtimeState = State.get()

  local timestamp = now_ms()
  local writeIndex = runtimeState.keyRingHeadIndex

  runtimeState.keyRingBuffer[writeIndex] = { t = timestamp, k = normalizedKeyToken }
  runtimeState.keyRingHeadIndex = (writeIndex % config.keyRingBufferSize) + 1
  runtimeState.keyRingLength = math.min(config.keyRingBufferSize, runtimeState.keyRingLength + 1)
end

function Keylog.get_recent_keys(windowMilliseconds)
  local config = Config.get()
  local runtimeState = State.get()

  local keys = {}
  local cutoff = now_ms() - windowMilliseconds

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

function Keylog.install_if_needed()
  local runtimeState = State.get()
  if runtimeState.onKeyHookInstalled then
    return
  end
  runtimeState.onKeyHookInstalled = true

  vim.on_key(function(rawKeyBytes)
    local normalized = normalize_key(rawKeyBytes)
    if should_capture_key(normalized) then
      ring_push(normalized)
    end
  end, runtimeState.namespace)
end

function Keylog.uninstall_if_needed()
  local runtimeState = State.get()
  if not runtimeState.onKeyHookInstalled then
    return
  end
  runtimeState.onKeyHookInstalled = false
  vim.on_key(nil, runtimeState.namespace)
end

return Keylog
