--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class Advanced
local M = {}

local Config = require('motioncoach-nvim.config')
local CountCompression = require('motioncoach-nvim.suggestions.advanced.countcompression')
local JumpList = require('motioncoach-nvim.suggestions.advanced.jumplist')
local Keylog = require('motioncoach-nvim.keylog')
local Marks = require('motioncoach-nvim.suggestions.advanced.marks')
local Plugins = require('motioncoach-nvim.suggestions.plugins')
local Surround = require('motioncoach-nvim.suggestions.advanced.surround')
local TextObject = require('motioncoach-nvim.suggestions.advanced.textobject')
local Treesitter = require('motioncoach-nvim.suggestions.advanced.treesitter')
local VimRegister = require('motioncoach-nvim.suggestions.advanced.vimregister')
local Yanks = require('motioncoach-nvim.suggestions.advanced.yanks')

-- TODO: suggest using `f`/`F` (maybe this is where a plugin check is done to see if Homie has flash.nvim installed and only if so, suggest using `s`+{a-Z0-9})

-- INFO: THE MAIN FUNCTION OF ADVANCED MODE COACHING SUGGESTIONS
--
---@param episode {}
---@param context {}
---@return string|nil, {} -- returns the actual suggestion text for a notification OR returns nil if no suggestions were twiggered, and a table of recent keys.
function M.suggest(episode, context)
  local config = Config.get()
  local runtimeState = context.runtimeState
  local perBufferState = context.perBufferState
  local recentKeys = Keylog.get_recent_keys(config.keyPatternWindowMilliseconds)

  local sugg1 = CountCompression.count_compression(recentKeys)
  if sugg1 then
    return sugg1, recentKeys
  end

  local sugg2 = TextObject.text_object_suggestion(recentKeys, context.get_line, perBufferState)
  if sugg2 then
    perBufferState.evidenceCounters.textObjectNeedEvidenceCount = perBufferState.evidenceCounters.textObjectNeedEvidenceCount
      + 1
    return sugg2, recentKeys
  end

  if Surround.detect_surround_like(recentKeys) then --
    perBufferState.evidenceCounters.surroundLikeEvidenceCount = perBufferState.evidenceCounters.surroundLikeEvidenceCount
      + 1
    return 'Surround: use text objects like `ci"`, `ci(`, `ci{` (and `ca...`).', recentKeys
  end

  local sugg3 = VimRegister.vimregister_suggestion(recentKeys, perBufferState, runtimeState)
  if sugg3 then
    return sugg3, recentKeys
  end

  local sugg4 = JumpList.jumplist_suggestion(episode, recentKeys, perBufferState)
  if sugg4 then
    return sugg4, nil
  end

  local sugg5 = Marks.marks_suggestion(episode, recentKeys, perBufferState, config)
  if sugg5 then
    return sugg5, recentKeys
  end

  local sugg6 = Treesitter.treesitter_suggestion(episode, perBufferState)
  if sugg6 then
    return sugg6, recentKeys
  end

  local sugg7 = Yanks.yank_ring_suggestion(perBufferState)
  if sugg7 then
    return sugg7, recentKeys
  end

  -- TODO: This will be pretty complex.  Just a simple start for now.
  if config.pluginRecommendations.enabled then
    local sugg8 = Plugins.recommend(perBufferState, context)
    if sugg8 then
      return sugg8, recentKeys
    end
  end

  -- TODO: Add PROVIDER HOOKS { FUTURE }

  return nil, recentKeys
end

return M
