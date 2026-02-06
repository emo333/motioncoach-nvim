-- lua/motioncoach/registers.lua
-- Captures yank contents (TextYankPost) into a per-buffer yank ring for coaching.
local Registers = {}

local State = require('motioncoach-nvim.state')
local Utils = require('motioncoach-nvim.utils')

local function normalize_register_name(regname)
  if regname == nil or regname == '' then
    return '"'
  end
  return regname
end

local function get_register_text(registerName)
  local ok, regInfo = pcall(vim.fn.getreginfo, registerName)
  if not ok or not regInfo then
    return nil
  end

  local content = regInfo.regcontents
  if type(content) == 'table' then
    content = table.concat(content, '\n')
  end
  if type(content) ~= 'string' or content == '' then
    return nil
  end
  return content
end

function Registers.capture_yank(event)
  local bufferNumber = vim.api.nvim_get_current_buf()
  local perBufferState = State.get_or_create_per_buffer(bufferNumber)

  local registerName = normalize_register_name(event.regname)
  local registerText = get_register_text(registerName)
  if not registerText then
    return
  end

  table.insert(perBufferState.yankRing, 1, {
    reg = registerName,
    text = registerText,
    timeMs = Utils.now_ms(),
    operator = event.operator, -- "y", "d", "c" etc (may be nil)
    regtype = event.regtype, -- "v", "V", "\022" etc
  })

  if #perBufferState.yankRing > perBufferState.yankRingMaxItems then
    table.remove(perBufferState.yankRing)
  end
end

return Registers
