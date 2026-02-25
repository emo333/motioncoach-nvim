--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class Advanced
local M = {}

local Config = require('motioncoach-nvim.config')
local Keylog = require('motioncoach-nvim.keylog')
local Plugins = require('motioncoach-nvim.suggestions.plugins')
local Utils = require('motioncoach-nvim.utils')

---@return {} | nil
local function detect_last_operator_range()
  -- local startPos = vim.fn.getpos("'[")
  local startPos = vim.fn.getpos("'^")
  local endPos = vim.fn.getpos("']")
  if not startPos or not endPos then
    return nil
  end
  if startPos[2] == 0 or endPos[2] == 0 then
    return nil
  end

  return {
    bufferNumber = startPos[1],
    startRow = startPos[2],
    startCol = startPos[3] - 1,
    endRow = endPos[2],
    endCol = endPos[3] - 1,
  }
end

-- INFO: COUNT COMPRESSION SUGGESTION
--
--  detection: Homie hammers same letter (jkhlwbe) 5 times
--  suggestion: Yo Homie use a count with your movements!
--
---@param keys {}
local function count_compression(keys)
  local allowed = { j = true, k = true, h = true, l = true, w = true, b = true, e = true }
  local lastToken, repeatCount = nil, 0
  for _, token in ipairs(keys) do
    if allowed[token] then
      if token == lastToken then
        repeatCount = repeatCount + 1
      else
        lastToken, repeatCount = token, 1
      end
    else
      lastToken, repeatCount = nil, 0
    end
  end

  if lastToken and repeatCount >= 5 then
    return ('You pressed ` %s ` %d times. Try ` %d%s ` (count + motion).'):format(
      lastToken,
      repeatCount,
      repeatCount,
      lastToken
    )
  end

  -- vim.notify('returning nil from count_compression')

  return nil
end

-- ============================================================================
-- INFO: TEXT OBJECT SUGGESTION
--
--  detection:
--    1. Homie deletes a char, word, or block(chunk)
--      a. Did Homie paste in deleted row/col?
--  suggestion: {word} "Yo Homie, you can use 'diw'(think: [d]elete [i]nside [w]ord) to delete the word your cursor within on regardless where your cursor is within the word"
--  suggestion: {block} "Yo Homie, you can use 'di' + " or [ or { or ( ---think: [d]elete [i]nside "quotes or [braces or {brackets or (parenthesis--- to delete the block your cursor is within regardless where your cursor is within the block"
--      b. Did Homie use v + w/e/b prior to delete?
--  suggestion: "Yo Homie, you can use 'yi' "
--     2. Homie yanks a word, or block(chunk)
--       a. Did Homie use v + w/e/b prior to yank?
--  suggestion:
--
local function text_object_suggestion(keys, operatorRange, get_line)
  if not operatorRange then
    return nil
  end
  local keyString = Utils.build_key_string(keys)
  local usedOperator = (keyString:find(' d ') or keyString:find(' c ') or keyString:find(' y '))
    ~= nil
  local usedVisual = (keyString:find(' v ') or keyString:find(' V ') or keyString:find('<C%-v>'))
    ~= nil
  if not usedOperator and not usedVisual then
    return nil
  end

  if
    keyString:find(' iw ')
    or keyString:find(' aw ')
    or keyString:find(' ip ')
    or keyString:find(' ap ')
    or keyString:find(' i%(')
    or keyString:find(' a%(')
    or keyString:find(' i%[')
    or keyString:find(' a%[')
    or keyString:find(' i%{')
    or keyString:find(' a%{')
    or keyString:find(' i"')
    or keyString:find(' a"')
    or keyString:find(" i'")
    or keyString:find(" a'")
  then
    return nil
  end

  if operatorRange.startRow == operatorRange.endRow then
    local lineText = get_line(operatorRange.bufferNumber, operatorRange.startRow)
    local a = Utils.clampNumber(operatorRange.startCol + 1, 1, #lineText)
    local b = Utils.clampNumber(operatorRange.endCol + 1, 1, #lineText)
    if b < a then
      a, b = b, a
    end
    local segment = lineText:sub(a, b)

    -- NOTE: WORDS ciw diw yiw caw daw yaw
    if segment:match('^%w[%w_]*$') then
      return 'Text Object:\n  try ` ciw ` ` diw ` ` yiw ` ` caw ` ` daw ` ` yaw `\n to operate on a word.'
    end

    -- NOTE: DOUBLE QUOTES ci" di" yi"
    if segment:find('"') then
      return 'Text Object:\n  inside double-quotes use ` ci" ` ` di" ` ` yi `'
    end

    -- NOTE: SINGLE QUOTES ci' di' yi'
    if segment:find("'") then
      return "Text Object:\n  inside single-quotes use ` ci' ` ` di' ` ` yi `"
    end

    -- NOTE: PARENTHESES ci( di( yi(
    if segment:find('%(') or segment:find('%)') then
      return 'Text Object:\n  inside parentheses use ` ci( ` ` di( ` ` yi( `'
    end

    -- NOTE: BRACKETS ci[ di[ yi[
    if segment:find('%[') or segment:find('%]') then
      return 'Text Object:\n  inside brackets use ` ci[ ` ` di[ ` ` yi[ `'
    end

    -- NOTE: BRACES ci{ di{ yi{
    if segment:find('%{') or segment:find('%}') then
      return 'Text Object:\n  inside braces use ` ci{ ` ` di{ ` ` yi{ `'
    end
  end

  -- NOTE: PARAGRAPHS dip cip yip
  local lines = math.abs(operatorRange.endRow - operatorRange.startRow) + 1
  if lines >= 3 then
    return 'Text Object:\n  for paragraphs use ` dip ` ` cip ` ` yip `'
  end

  return nil
end
-- ============================================================================

local function has_any_key(keys, keySet)
  for _, k in ipairs(keys) do
    if keySet[k] then
      return true
    end
  end
  return false
end

---@param keys {}?
---@param operatorRange {}?
---@return boolean
local function detect_surround_like(keys, operatorRange)
  if not operatorRange then
    return false
  end
  if not keys then
    return false
  end
  local keyString = Utils.build_key_string(keys)

  if keyString:find(' ci') or keyString:find(' di') or keyString:find(' yi') then
    return false
  end

  local usedHunting =
    has_any_key(keys, { ['f'] = true, ['F'] = true, ['t'] = true, ['T'] = true, ['%'] = true })
  local usedChangeOrDelete = (
    keyString:find(' c ')
    or keyString:find(' s ')
    or keyString:find(' d ')
  ) ~= nil
  return usedHunting and usedChangeOrDelete
end

-- INFO: VIMREGISTER SUGGESTION
--
--  detection:
--  suggestion:
--
local function vimregister_suggestion(keys, perBufferState, runtimeState)
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

-- INFO: JUMPLIST SUGGESTION
--
--  detection:
--  suggestion:
--
local function jumplist_suggestion(episode, keys, perBufferState)
  local traveled = math.abs(episode.to.row - episode.from.row)
  -- + math.abs(episode.to.col - episode.from.col)  --<-- col travel relevent??
  -- TODO: add 40 to Config
  if traveled < 40 then
    return nil
  end

  local keyString = Utils.build_key_string(keys)
  local usedJumpKeys = keyString:find('<C%-o>')
    or keyString:find('<C%-i>')
    or keyString:find(' `` ')
    or keyString:find(" '' ")
  if usedJumpKeys then
    return nil
  end

  -- NOTE: increment count for buffer of times Homie has been given this suggestion.  This will be used for 'Plugin Recomendations'
  perBufferState.evidenceCounters.jumpBacktrackingEvidenceCount = perBufferState.evidenceCounters.jumpBacktrackingEvidenceCount
    + 1

  return ' --JUMPLIST SUGGESTION--\n\n ` <C-o> ` backward | ` <C-i> ` forward | ` `` ` toggle'
end

-- INFO: MARKS SUGGESTION
--
--  detection: if Homie's cursor is positioned at same row/col x times (hotspotRevisitThreshold in Config) in same buffer
--  suggestion: Yo Homie!  Use marks!
--
local function marks_suggestion(episode, keys, perBufferState, config)
  local keyString = Utils.build_key_string(keys)
  if keyString:find(' m') or keyString:find(" '") or keyString:find(' `') then
    return nil
  end

  local key = ('%d:%d:%d'):format(episode.bufferNumber, episode.to.row, episode.to.col)
  perBufferState.hotspotVisitCountsByPositionKey[key] = (
    perBufferState.hotspotVisitCountsByPositionKey[key] or 0
  ) + 1

  if perBufferState.hotspotVisitCountsByPositionKey[key] >= config.hotspotRevisitThreshold then
    return "Marks tip: set a mark with ` ma `, jump with ` 'a ` (line) or `` `a `` (exact)."
  end

  return nil
end

-- INFO: TREESITTER TEXT OBJECTS SUGGESTION
--
--  detection: Homie moved over 40 lines (and has Treesitter installed)
--  suggestion: Yo Homie!  You got Treesitter... Use it!
--
local function treesitter_hint(episode, perBufferState)
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

-- INFO: YANKS EXIST SUGGESTION
--
--  detection: Homie has yanked in buffer
--  suggestion: Yo Homie! You got stuff you have yanked in registers.  Remember, if you delete things, your yank registers can be overwritten!
--
local function yank_ring_hint(perBufferState)
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

-- ----------------------------------------------------------------------------
--
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

  local sugg1 = count_compression(recentKeys)
  if sugg1 then
    return sugg1, recentKeys
  end

  local operatorRange = detect_last_operator_range()
  local sugg2 = text_object_suggestion(recentKeys, operatorRange, context.get_line)
  if sugg2 then
    perBufferState.evidenceCounters.textObjectNeedEvidenceCount = perBufferState.evidenceCounters.textObjectNeedEvidenceCount
      + 1
    return sugg2, recentKeys
  end
  if detect_surround_like(recentKeys, operatorRange) then --
    perBufferState.evidenceCounters.surroundLikeEvidenceCount = perBufferState.evidenceCounters.surroundLikeEvidenceCount
      + 1
    --   return 'Delimiter tip: use text objects like `ci"`, `ci(`, `ci{` (and `ca...`).', recentKeys
  end

  local sugg3 = vimregister_suggestion(recentKeys, perBufferState, runtimeState)
  if sugg3 then
    return sugg3, recentKeys
  end

  local sugg4 = jumplist_suggestion(episode, recentKeys, perBufferState)
  if sugg4 then
    return sugg4, nil
  end

  local sugg5 = marks_suggestion(episode, recentKeys, perBufferState, config)
  if sugg5 then
    return sugg5, recentKeys
  end

  local sugg6 = treesitter_hint(episode, perBufferState)
  if sugg6 then
    return sugg6, recentKeys
  end

  local sugg7 = yank_ring_hint(perBufferState)
  if sugg7 then
    return sugg7, recentKeys
  end

  -- NOTE: This will be pretty complex.  Just a simple start for now.
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
