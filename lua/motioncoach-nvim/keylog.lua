local Config = require('motioncoach-nvim.config')
local State = require('motioncoach-nvim.state')

local Keylog = {}

local function now_ms()
  return math.floor(vim.loop.hrtime() / 1e6)
end

local function ring_push(token)
  local config = Config.get()
  local runtimeState = State.get()

  local timestamp = now_ms()
  local writeIndex = runtimeState.keyRingHeadIndex

  runtimeState.keyRingBuffer[writeIndex] = { t = timestamp, k = token }
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
    -- Be maximally defensive: ignore anything unexpected.
    if type(rawKeyBytes) ~= 'string' or rawKeyBytes == '' then
      return
    end

    -- keytrans itself can throw in rare cases; protect it.
    local ok, normalized = pcall(vim.keytrans, rawKeyBytes)
    if not ok or type(normalized) ~= 'string' or normalized == '' then
      return
    end

    -- No mode checks, no notify, no vim.api calls here. Just store.
    ring_push(normalized)
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
