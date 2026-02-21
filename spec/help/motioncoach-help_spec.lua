---@diagnostic disable
local motioncoach_help = require('motioncoach-nvim.help.motioncoach-help')

describe('help.motioncoach-help.lua', function()
  it('exists as a table', function()
    assert.is_table(motioncoach_help)
  end)
end)
