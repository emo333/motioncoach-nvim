--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class Yanks
local M = {}

--  detection: Homie has yanked in buffer
--  suggestion: Yo Homie! You got stuff you have yanked in registers.  Remember, if you delete things, your yank registers can be overwritten!
--
function M.yank_ring_suggestion(perBufferState)
  -- HACK: temp disable yank suggestion for debugging
  if true then
    return nil
  end

  if not perBufferState.yankRing or #perBufferState.yankRing == 0 then
    return nil
  end

  local latest = perBufferState.yankRing[1]
  if not latest or not latest.text then
    return nil
  end
  -- TODO: check for existing keymap vim.keymap.set("x", "<leader>p", '"_dP') , if exists suggest "_dP
  return 'Recent yanks -—Remember ` "0p ` for last yank. (Your default Vim Register can be overwritten by deletes.)'
end

return M
