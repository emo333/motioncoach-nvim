---@diagnostic disable
local Formatter = require('motioncoach-nvim.formatter')

describe('formatter.lua', function()
  it('format_keys_for_display returns concatenated string for given tokens', function()
    local tokens = { 'a', 'b', 'c' }
    local formatted = Formatter.format_keys_for_display(tokens)
    assert.is_string(formatted)
    assert(formatted:match('a'))
    assert(formatted:match('b'))
    assert(formatted:match('c'))
  end)
end)
