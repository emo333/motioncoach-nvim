---@diagnostic disable
local plugin = require('motioncoach-nvim')

describe('init.lua', function()
  it('setup is callable', function()
    assert.is_function(plugin.setup)
  end)
  it('level returns an integer', function()
    local lv = plugin.level()
    assert(type(lv) == 'number')
  end)
end)
