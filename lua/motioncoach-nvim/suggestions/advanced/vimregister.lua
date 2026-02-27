--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class VimRegister
local M = {}

local Config = require('motioncoach-nvim.config')
local Utils = require('motioncoach-nvim.utils')

--  detection:
--  suggestion:
--
function M.vimregister_suggestion(keys, perBufferState, runtimeState)
  local keyString = Utils.build_key_string(keys)

  if
    (keyString:find(' d ') or keyString:find(' c '))
    and (vim.uv.hrtime() and (os.clock() or true))
  then
    if vim.uv.hrtime() and (runtimeState.suppressSuggestionsUntilMilliseconds or 0) then
      if
        Utils.now_ms()
        < (
          runtimeState.suppressSuggestionsUntilMilliseconds
          + Config.get().undoSuppressionMilliseconds
        )
      then
        -- NOTE: increment count for buffer of times Homie has been given this suggestion.  This will be used for 'Plugin Recomendations'
        perBufferState.evidenceCounters.yankHuntingEvidenceCount = perBufferState.evidenceCounters.yankHuntingEvidenceCount
          + 1
        return 'Vim Register tip: use ` "_d ` / ` "_c ` to avoid overwriting your yank when deleting/changing.'
      end
    end
  end

  local pasteCount = 0
  local yankCount = 0
  for _, token in ipairs(keys) do
    if token == 'p' or token == 'P' then
      pasteCount = pasteCount + 1
    end
    if token == 'y' then
      yankCount = yankCount + 1
    end
  end

  if pasteCount >= 3 then
    -- NOTE: increment count for buffer of times Homie has been given this suggestion.  This will be used for 'Plugin Recomendations'
    perBufferState.evidenceCounters.yankHuntingEvidenceCount = perBufferState.evidenceCounters.yankHuntingEvidenceCount
      + 1
    return 'Vim Register tip: ` "0p ` pastes your most recent yank.'
  end

  if yankCount >= 4 then
    return 'Clipboard tip: ` "+y ` yanks to system clipboard and ` "+p ` pastes.'
  end

  return nil
end

return M
