local VimRegisters = require('motioncoach-nvim.vimregisters')

describe('vimregisters.lua', function()
  it('exists as a table', function()
    assert.is_table(VimRegisters)
  end)
end)
