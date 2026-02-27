--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class Treesitter
local M = {}

--  detection: Homie moved over 40 lines (and has Treesitter installed)
--  suggestion: Yo Homie!  You got Treesitter... Use it!
--
function M.treesitter_suggestion(episode, perBufferState)
  local movedLines = math.abs(episode.to.row - episode.from.row)
  -- TODO: Add 40 to Config
  if movedLines < 40 then
    return nil
  end

  local okTs = pcall(require, 'vim.treesitter')
  if not okTs then
    return nil
  end

  local okParser = pcall(vim.treesitter.get_parser, episode.bufferNumber)
  if not okParser then
    return nil
  end

  -- NOTE: increment count for buffer of times Homie has been given this suggestion.  This will be used for 'Plugin Recomendations'
  perBufferState.evidenceCounters.treesitterMotionEvidenceCount = perBufferState.evidenceCounters.treesitterMotionEvidenceCount
    + 1

  return 'Use Treesitter, you can jump/select functions/classes.'
end

return M
