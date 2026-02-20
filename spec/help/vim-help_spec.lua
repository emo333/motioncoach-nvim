local vim_help = require('motioncoach-nvim.help.vim-help')

describe('help.vim-help.lua', function()
  it('exists as a table', function()
    assert.is_table(vim_help)
  end)
end)
