--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class Config
local M = {}

--  TODO: reconsider (get opinions of avid vim users) all these defaults before publishing

local defaultConfig = {
  --- The coaching level on start of NeoVim session
  --- default 1 (Beginner)
  coachingLevel = 1,
  --- The logging level of notifications
  --- default INFO(2)
  notifyLogLevel = vim.log.levels.INFO,
  --- Time between an Episode finalizing and a new Episode starting
  --- default 700ms
  episodeGapMilliseconds = 700,
  --- The minimum distance (eg. from start column to end column OR from start row to end row) before a suggestion check will occur
  --- default 8
  minimumNaiveCostToCoach = 8,
  --- The time from last suggestion that must elapse before a new suggestion can occur
  --- default 2500ms
  suggestionCooldownMilliseconds = 2500,
  --- The time after an Undo command has occurred that must elapse before a new suggestion can occur
  --- default 3000ms
  undoSuppressionMilliseconds = 3000,
  --- The maximum keys (each key the user has pressed in a given Episode) that will be stored in the keyRing
  --- default 260
  keyRingBufferSize = 260,
  --- The time within that a "patern" of keys will be analyzed
  --- default 2000ms
  keyPatternWindowMilliseconds = 4000,
  --- Capture command keys (eg. i a p o x d c r y u ...) -- If this is true, a lot more Advanced suggestions are enabled
  --- default false
  captureCommandLineKeys = false,
  --- Capture keys while in INSERT mode -- If this is true, al lot more Advanced suggestions are enabled. {if captureCommandLineKeys = false, this is already disabled}
  --- default false
  captureInsertModeKeys = false,
  ---
  --- default 3
  hotspotRevisitThreshold = 3,
  --- Display very descriptive suggestions (lenthy messages)
  --- default false
  longSuggestMessages = false,

  --- Configuration for the Formatter(which is a helper for formatting the actual notification messages)
  typedKeysFormatter = {
    enabled = true,
    maxTokens = 25,
    collapseRepeats = true,
    repeatMarker = 'x',
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

  --- TODO: For future use of PLUGIN RECOMENDATIONS
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
function M.get()
  return activeConfig
end

---Apply Homie's custom configuration to the Active Configuration
---@param userConfig {} Homie's custom configuration
function M.apply(userConfig)
  activeConfig = vim.tbl_deep_extend('force', activeConfig, userConfig)
end

return M
