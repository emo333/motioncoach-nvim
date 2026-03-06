--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------
-- INFO: Utility Functions (named it utils "Utuls" only from hearing ThePrimagen say it. LOL!)
--
local M = {}

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

function M.clampNumber(value, minimum, maximum)
  return clampNumber(value, minimum, maximum)
end

---@return number now_ms current time in milliseconds
function M.now_ms()
  local uv = vim.uv or vim.loop -- if older neovim version, use vim.loop
  local hrtime = uv and uv.hrtime and uv.hrtime() or nil
  -- print('[MOTIONCOACH DEBUG] vim.uv:', vim.uv, ', vim.loop:', vim.loop, ', hrtime:', hrtime)
  if hrtime then
    return math.floor(hrtime / 1e6)
  end
  error('No uv.hrtime() available (unsupported Neovim version?)')
end

function M.build_key_string(keys)
  return ' ' .. table.concat(keys, ' ') .. ' '
end

---@return {} | nil
function M.detect_last_operator_range()
  -- vim.fn.getpos("'[") gets starting position of last operation (eg. y c d x )
  local startPos = vim.fn.getpos("'[")
  -- local startPos = vim.fn.getpos("'^")
  local endPos = vim.fn.getpos("']")
  -- vim.notify(
  --   vim.inspect(startPos)
  --     .. ' : '
  --     .. vim.inspect(endPos)
  --     .. ' -- from Utils.detect_last_operator_range'
  -- )
  if not startPos or not endPos then
    return nil
  end
  if startPos[2] == 0 or endPos[2] == 0 then
    return nil
  end
  -- vim.fn.getjumplist() gets jummplist as a {} with each jump as a sub table
  -- local jumps, last_idx = unpack(vim.fn.getjumplist())
  -- print('vim.inspect(jumps): ' .. vim.inspect(jumps))

  return {
    bufferNumber = startPos[1],
    startRow = startPos[2],
    startCol = startPos[3] - 1,
    endRow = endPos[2],
    endCol = endPos[3] - 1,
  }
end

-- ----------------------------------------------------------------
-- ----------------------------------------------------------------
-- got the following from https://github.com/ThePrimeagen/harpoon/blob/harpoon2/lua/harpoon/utils.lua
function M.trim(str)
  return str:gsub('^%s+', ''):gsub('%s+$', '')
end
function M.remove_duplicate_whitespace(str)
  return str:gsub('%s+', ' ')
end

function M.split(str, sep)
  if sep == nil then
    sep = '%s'
  end
  local t = {}
  for s in string.gmatch(str, '([^' .. sep .. ']+)') do
    table.insert(t, s)
  end

  return t
end

function M.is_white_space(str)
  return str:gsub('%s', '') == ''
end
-- ----------------------------------------------------------------
-- ----------------------------------------------------------------

return M
