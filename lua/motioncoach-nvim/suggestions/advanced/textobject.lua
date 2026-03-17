--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

---@class TextObject
local M = {}

local Utils = require('motioncoach-nvim.utils')
local Config = require('motioncoach-nvim.config')

--  detection:
--    1. Homie deletes a char, word, or block(chunk
--      a. Did Homie paste in deleted row/col?
--  suggestion: {word} "Yo Homie, you can use 'diw'(think: [d]elete [i]nside [w]ord) to delete the word your cursor within on regardless where your cursor is within the word"
--  suggestion: {block} "Yo Homie, you can use 'di' + " or [ or { or ( ---think: [d]elete [i]nside "quotes or [braces or {brackets or (parenthesis--- to delete the block your cursor is within regardless where your cursor is within the block"
--      b. Did Homie use v + w/e/b prior to delete?
--  suggestion: "Yo Homie, you can use 'yi' "
--     2. Homie yanks a word, or block(chunk)
--       a. Did Homie use v + w/e/b prior to yank?
--  suggestion:
--
---@param keys {}
---@param get_line function
function M.text_object_suggestion(keys, get_line, perBufferState)
  local operatorRange = Utils.detect_last_operator_range()

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

  -- TODO: implement brief/long suggestion messages for every suggestion
  local longMsg = Config.get().longSuggestMessages

  if operatorRange.startRow == operatorRange.endRow then
    -- local lineText = get_line(operatorRange.bufferNumber, operatorRange.startRow)
    -- local a = Utils.clampNumber(operatorRange.startCol + 1, 1, #lineText)
    -- local b = Utils.clampNumber(operatorRange.endCol + 1, 1, #lineText)
    -- if b < a then
    --   a, b = b, a
    -- end
    -- if a > 1 then
    --   a = a - 1
    -- end
    -- if b < #lineText - 1 then
    --   b = b + 1
    -- end

    -- local segment = lineText:sub(a, b)
    local segment = perBufferState.yankRing[1].text

    -- ldskfj a sldkjf asdl  l skdfjh ) kalsjdhf (jdhfjh)  askdfkkk  hhhhj sk
    -- NOTE: WORDS ciw diw yiw caw daw yaw
    if segment:match('^%w[%w_]*$') then -- does segment contain a string with no spaces or special characters (_ is not a special char)
      if longMsg then
        return [[
    --Text Object--

    to operate on a word use:

    ` ciw ` [c]hange [i]nside [w]ord
    ` diw ` [d]elete [i]nside [w]ord
    ` yiw ` [y]ank [i]nside [w]ord
    ` caw ` [c]hange [a]round [w]ord
    ` daw ` [d]elete [a]round [w]ord
    ` yaw ` [y]ank [a]round [w]ord
          ]]
      else
        return 'Text Object:\n  try ` ciw ` ` diw ` ` yiw ` ` caw ` ` daw ` ` yaw `\n to operate on a word.'
      end
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

return M
