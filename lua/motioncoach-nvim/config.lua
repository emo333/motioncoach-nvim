local Config = {}

local defaultConfig = {
  coachingLevel = 1,
  notifyLogLevel = vim.log.levels.INFO,

  episodeGapMilliseconds = 700,
  minimumNaiveCostToCoach = 8,
  suggestionCooldownMilliseconds = 2500,
  undoSuppressionMilliseconds = 3000,

  keyRingBufferSize = 260,
  keyPatternWindowMilliseconds = 2000,

  captureCommandLineKeys = false,
  captureInsertModeKeys = false,

  hotspotRevisitThreshold = 3,

  typedKeysFormatter = {
    enabled = true,
    maxTokens = 25,
    collapseRepeats = true,
    repeatMarker = '×',
    filterNoise = true,
    noisePatterns = {
      '^<Ignore>$',
      '^<Plug>.*',
      '^<SNR>%d+_.*',
      '^<LeftMouse>$',
      '^<RightMouse>$',
      '^<MiddleMouse>$',
      '^<ScrollWheelUp>$',
      '^<ScrollWheelDown>$',
      '^<ScrollWheelLeft>$',
      '^<ScrollWheelRight>$',
      '^<MouseMove>$',
      '^<LeftDrag>$',
      '^<LeftRelease>$',
      '^<RightDrag>$',
      '^<RightRelease>$',
      '^<MiddleDrag>$',
      '^<MiddleRelease>$',
    },
  },

  pluginRecommendations = {
    enabled = true,
    thresholdDefault = 10,
    -- provider(perBufferEvidenceCounters, context) -> string|nil
    provider = nil,

    items = {
      yank_history = {
        enabled = true,
        evidenceKey = 'yankHuntingEvidenceCount',
        threshold = 10,
        message = 'Plugin idea: if you often hunt old yanks, consider a yank-history/yank-ring workflow (often integrates with Telescope).',
      },
      surround = {
        enabled = true,
        evidenceKey = 'surroundLikeEvidenceCount',
        threshold = 10,
        message = "Plugin idea: for fast surround edits (change/add/delete quotes/parens), consider a 'surround' plugin.",
      },
      treesitter_textobjects = {
        enabled = true,
        evidenceKey = 'treesitterMotionEvidenceCount',
        threshold = 10,
        message = 'Plugin idea: consider Treesitter + textobjects for function/class motions and selections.',
      },
    },
  },
}

local activeConfig = vim.deepcopy(defaultConfig)

function Config.get()
  return activeConfig
end

function Config.apply(userConfig)
  activeConfig = vim.tbl_deep_extend('force', activeConfig, userConfig)
end

return Config
