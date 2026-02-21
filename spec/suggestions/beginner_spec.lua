---@diagnostic disable
local beginner = require('motioncoach-nvim.suggestions.beginner')

describe('suggestions.beginner.lua', function()
  it('exists as a table', function()
    assert.is_table(beginner)
  end)
end)
