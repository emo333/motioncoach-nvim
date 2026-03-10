--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class State
local M = {}

local pluginNamespace = vim.api.nvim_create_namespace('motioncoach-nvim')

local runtimeState = {
  namespace = pluginNamespace,
  lastSuggestionTimestampMilliseconds = 0,
  suppressSuggestionsUntilMilliseconds = 0,
  onKeyHookInstalled = false,
  keyRingBuffer = {},
  keyRingHeadIndex = 1,
  keyRingLength = 0,
  currentEpisode = nil,
  perBufferStateByBufferNumber = {
    [1] = {
      lastUndoSequenceNumber = nil,
      yankRing = {},
      yankRingMaxItems = 20,
      evidenceCounters = {
        surroundLikeEvidenceCount = 0,
        yankHuntingEvidenceCount = 0,
        jumpBacktrackingEvidenceCount = 0,
        textObjectNeedEvidenceCount = 0,
        treesitterMotionEvidenceCount = 0,
      },
      lastLineOperatedOn = {
        rowNumber = 0,
        cursorCol = 0,
        lineBeforeOperation = '',
      },
      hotspotVisitCountsByPositionKey = {},
    },
  },
}

function M.get()
  return runtimeState
end
-- klaj
--- does nothing, do not use
function M.init()
  -- didn't need this but leaving it here in case have a need later
end

function M.get_or_create_per_buffer(bufferNumber)
  if not vim.api.nvim_buf_is_valid(bufferNumber) then
    return
  end
  if vim.bo[bufferNumber].bh ~= '' then --vim.bo.bh == '' then
    return
  end
  local existing = runtimeState.perBufferStateByBufferNumber[bufferNumber]
  if existing then
    return existing
  end

  local created = {
    lastUndoSequenceNumber = nil,
    yankRing = {},
    yankRingMaxItems = 20,
    evidenceCounters = {
      surroundLikeEvidenceCount = 0,
      yankHuntingEvidenceCount = 0,
      jumpBacktrackingEvidenceCount = 0,
      textObjectNeedEvidenceCount = 0,
      treesitterMotionEvidenceCount = 0,
    },
    lastLineOperatedOn = {
      rowNumber = 0,
      cursorCol = 0,
      lineBeforeOperation = '',
    },
    hotspotVisitCountsByPositionKey = {},
  }

  runtimeState.perBufferStateByBufferNumber[bufferNumber] = created
  return created
end

return M
