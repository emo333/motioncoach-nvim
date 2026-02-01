local Config = require('motioncoach-nvim.config')

local Notify = {}

local function get_wrap_width()
  local wrapConfig = Config.get().notificationWrap or {}
  if wrapConfig.width and wrapConfig.width > 20 then
    return wrapConfig.width
  end
  local margin = wrapConfig.margin or 10
  local columns = vim.o.columns or 80
  return math.max(30, math.min(90, columns - margin))
end

local function wrap_one_line(line, width)
  if #line <= width then
    return { line }
  end

  local out = {}
  local i = 1
  while i <= #line do
    local remaining = line:sub(i)
    if #remaining <= width then
      table.insert(out, remaining)
      break
    end

    -- Take a slice and find last whitespace within width
    local slice = remaining:sub(1, width)
    local cut = slice:match('^.*()%s') -- last whitespace position
    if cut and cut > 1 then
      table.insert(out, slice:sub(1, cut - 1))
      i = i + cut
      -- skip additional whitespace
      while i <= #line and line:sub(i, i):match('%s') do
        i = i + 1
      end
    else
      -- No whitespace found; hard break
      table.insert(out, slice)
      i = i + width
    end
  end

  return out
end

function Notify.format_message(message)
  local wrapConfig = Config.get().notificationWrap or {}
  if not wrapConfig.enabled then
    return message
  end

  local width = get_wrap_width()

  local resultLines = {}
  for _, line in ipairs(vim.split(message, '\n', { plain = true })) do
    if line == '' then
      table.insert(resultLines, '')
    else
      local wrapped = wrap_one_line(line, width)
      for _, w in ipairs(wrapped) do
        table.insert(resultLines, w)
      end
    end
  end

  return table.concat(resultLines, '\n')
end

function Notify.send(message, logLevel)
  local formatted = Notify.format_message(message)
  vim.notify(formatted, logLevel)
end

return Notify
