local State = {}

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

  perBufferStateByBufferNumber = {},
}

function State.get()
  return runtimeState
end

function State.init()
  -- reserved for future init needs
end

function State.get_or_create_per_buffer(bufferNumber)
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

    hotspotVisitCountsByPositionKey = {},
  }

  runtimeState.perBufferStateByBufferNumber[bufferNumber] = created
  return created
end

return State
