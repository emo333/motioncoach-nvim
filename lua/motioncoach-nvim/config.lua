---Configuration Module
local Config = {}

-- TODO: reconsider (get opinions of avid vim users) all these defaults before publishing
local defaultConfig = {
  --- default 1 (Beginner)
  coachingLevel = 1,
  --- default INFO
  notifyLogLevel = vim.log.levels.INFO,

  --- default 700ms
  episodeGapMilliseconds = 700,
  --- default 8
  minimumNaiveCostToCoach = 5,
  --- default 2500ms
  suggestionCooldownMilliseconds = 2000,
  --- default 3000ms
  undoSuppressionMilliseconds = 3000,

  --- default 260
  keyRingBufferSize = 260,
  --- default 2000ms
  keyPatternWindowMilliseconds = 4000,

  --- default false
  captureCommandLineKeys = false,
  --- default false
  captureInsertModeKeys = false,

  --- default 3
  hotspotRevisitThreshold = 3,

  typedKeysFormatter = {
    enabled = true,
    maxTokens = 25,
    collapseRepeats = true,
    repeatMarker = 'Ã',
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
    enabled = false,
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

-- deepcopy this so nothing funky happens to default config while this instance of nvim is open
local activeConfig = vim.deepcopy(defaultConfig)

---Get the Active Configuration
---@function
---@return {} activeConfig The Active Configuration table
function Config.get()
  return activeConfig
end

---Apply Homie's custom configuration to the Active Configuration
---@param userConfig {} Homie's custom configuration
function Config.apply(userConfig)
  activeConfig = vim.tbl_deep_extend('force', activeConfig, userConfig)
end

return Config
