--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class Treesitter
---@field Treesitter.get_buf_tree function
local M = {}

local Config = require('motioncoach-nvim.config')
local State = require('motioncoach-nvim.state')
local Utils = require('motioncoach-nvim.utils')

-- TODO: work on Treesitter implemnntation
function M.get_buf_tree(bufnr)
  return bufnr
end

return M
