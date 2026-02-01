local Config = require('motioncoach-nvim.config')
local Keylog = require('motioncoach-nvim.keylog')
local Plugins = require('motioncoach-nvim.suggestions.plugins')

local Advanced = {}

local function build_key_string(keys)
  return ' ' .. table.concat(keys, ' ') .. ' '
end

local function has_any_key(keys, keySet)
  for _, k in ipairs(keys) do
    if keySet[k] then
      return true
    end
  end
  return false
end

local function clampNumber(value, minimum, maximum)
  if value < minimum then
    return minimum
  end
  if value > maximum then
    return maximum
  end
  return value
end

local function detect_last_operator_range()
  local startPos = vim.fn.getpos("'[")
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
    return ('You pressed `%s` %d times. Try `%d%s` (count + motion).'):format(
      lastToken,
      repeatCount,
      repeatCount,
      lastToken
    )
  end
  return nil
end

local function text_object_suggestion(keys, operatorRange, get_line)
  if not operatorRange then
    return nil
  end
  local keyString = build_key_string(keys)

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
    local a = clampNumber(operatorRange.startCol + 1, 1, #lineText)
    local b = clampNumber(operatorRange.endCol + 1, 1, #lineText)
    if b < a then
      a, b = b, a
    end
    local segment = lineText:sub(a, b)

    if segment:match('^%w[%w_]*$') then
      return 'Text object tip: try `ciw` / `diw` / `yiw` to operate on the word.'
    end
    if segment:find('"') then
      return 'Text object tip: inside double-quotes use `ci"` / `di"` (or `ca"`).'
    end
    if segment:find("'") then
      return "Text object tip: inside single-quotes use `ci'` / `di'` (or `ca'`)."
    end
    if segment:find('%(') or segment:find('%)') then
      return 'Text object tip: inside parentheses use `ci(` / `di(` (or `ca(`).'
    end
    if segment:find('%[') or segment:find('%]') then
      return 'Text object tip: inside brackets use `ci[` / `di[` (or `ca[`).'
    end
    if segment:find('%{') or segment:find('%}') then
      return 'Text object tip: inside braces use `ci{` / `di{` (or `ca{`).'
    end
  end

  local lines = math.abs(operatorRange.endRow - operatorRange.startRow) + 1
  if lines >= 3 then
    return 'Text object tip: for paragraphs use `dip`/`cip` or `dap`/`cap`.'
  end

  return nil
end

local function detect_surround_like(keys, operatorRange)
  if not operatorRange then
    return false
  end
  local keyString = build_key_string(keys)

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

local function register_suggestion(keys, perBufferState, runtimeState)
  local keyString = build_key_string(keys)

  if
    (keyString:find(' d ') or keyString:find(' c '))
    and (vim.loop.hrtime() and (os.clock() or true))
  then
    -- Use suppression timestamp heuristic (reliable enough)
    if vim.loop.hrtime() and (runtimeState.suppressSuggestionsUntilMilliseconds or 0) then
      -- We'll just check window:
      if
        math.floor(vim.loop.hrtime() / 1e6)
        < (
          runtimeState.suppressSuggestionsUntilMilliseconds
          + Config.get().undoSuppressionMilliseconds
        )
      then
        perBufferState.evidenceCounters.yankHuntingEvidenceCount = perBufferState.evidenceCounters.yankHuntingEvidenceCount
          + 1
        return 'Register tip: use `"_d` / `"_c` to avoid overwriting your yank when deleting/changing.'
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
    perBufferState.evidenceCounters.yankHuntingEvidenceCount = perBufferState.evidenceCounters.yankHuntingEvidenceCount
      + 1
    return 'Register tip: `"0p` pastes your most recent yank.'
  end

  if yankCount >= 4 then
    return 'Clipboard tip: `"+y` yanks to system clipboard and `"+p` pastes.'
  end

  return nil
end

local function jumplist_suggestion(episode, keys, perBufferState)
  local traveled = math.abs(episode.to.row - episode.from.row)
    + math.abs(episode.to.col - episode.from.col)
  if traveled < 40 then
    return nil
  end

  local keyString = build_key_string(keys)
  local usedJumpKeys = keyString:find('<C%-o>')
    or keyString:find('<C%-i>')
    or keyString:find(' `` ')
    or keyString:find(" '' ")
  if usedJumpKeys then
    return nil
  end

  perBufferState.evidenceCounters.jumpBacktrackingEvidenceCount = perBufferState.evidenceCounters.jumpBacktrackingEvidenceCount
    + 1
  return 'Navigation tip: use jumplist — `<C-o>` back, `<C-i>` forward. Also ```` returns to last jump.'
end

local function marks_suggestion(episode, keys, perBufferState, config)
  local keyString = build_key_string(keys)
  if keyString:find(' m') or keyString:find(" '") or keyString:find(' `') then
    return nil
  end

  local key = ('%d:%d:%d'):format(episode.bufferNumber, episode.to.row, episode.to.col)
  perBufferState.hotspotVisitCountsByPositionKey[key] = (
    perBufferState.hotspotVisitCountsByPositionKey[key] or 0
  ) + 1

  if perBufferState.hotspotVisitCountsByPositionKey[key] >= config.hotspotRevisitThreshold then
    return "Marks tip: set a mark with `ma`, jump with `'a` (line) or `` `a `` (exact)."
  end

  return nil
end

local function treesitter_hint(episode, perBufferState)
  local movedLines = math.abs(episode.to.row - episode.from.row)
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

  perBufferState.evidenceCounters.treesitterMotionEvidenceCount = perBufferState.evidenceCounters.treesitterMotionEvidenceCount
    + 1
  return 'Tip: with Treesitter textobjects, you can jump/select functions/classes.'
end

local function yank_ring_hint(perBufferState)
  -- If we have history, hint that a yank ring exists (in our plugin) and registers 0/" may help.
  if not perBufferState.yankRing or #perBufferState.yankRing == 0 then
    return nil
  end
  local latest = perBufferState.yankRing[1]
  if not latest or not latest.text then
    return nil
  end

  -- Keep this subtle: don’t print content (privacy), just remind about registers.
  return 'Yank tip: you have recent yanks—remember `"0p` for last yank. (Your default register can be overwritten by deletes.)'
end

function Advanced.suggest(episode, context)
  local config = Config.get()
  local runtimeState = context.runtimeState
  local perBufferState = context.perBufferState

  local recentKeys = Keylog.get_recent_keys(config.keyPatternWindowMilliseconds)

  local s1 = count_compression(recentKeys)
  if s1 then
    return s1, recentKeys
  end

  local operatorRange = detect_last_operator_range()

  local s2 = text_object_suggestion(recentKeys, operatorRange, context.get_line)
  if s2 then
    perBufferState.evidenceCounters.textObjectNeedEvidenceCount = perBufferState.evidenceCounters.textObjectNeedEvidenceCount
      + 1
    return s2, recentKeys
  end

  if detect_surround_like(recentKeys, operatorRange) then
    perBufferState.evidenceCounters.surroundLikeEvidenceCount = perBufferState.evidenceCounters.surroundLikeEvidenceCount
      + 1
    return 'Delimiter tip: use text objects like `ci"`, `ci(`, `ci{` (and `ca...`).', recentKeys
  end

  local s3 = register_suggestion(recentKeys, perBufferState, runtimeState)
  if s3 then
    return s3, recentKeys
  end

  local s4 = jumplist_suggestion(episode, recentKeys, perBufferState)
  if s4 then
    return s4, recentKeys
  end

  local s5 = marks_suggestion(episode, recentKeys, perBufferState, config)
  if s5 then
    return s5, recentKeys
  end

  local s6 = treesitter_hint(episode, perBufferState)
  if s6 then
    return s6, recentKeys
  end

  local yankHint = yank_ring_hint(perBufferState)
  if yankHint then
    return yankHint, recentKeys
  end

  local s7 = Plugins.recommend(perBufferState, context)
  if s7 then
    return s7, recentKeys
  end

  return nil, recentKeys
end

return Advanced
