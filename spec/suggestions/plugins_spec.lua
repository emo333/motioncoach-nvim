local plugins = require('motioncoach-nvim.suggestions.plugins')

describe('suggestions.plugins.lua', function()
  it('exists as a table', function()
    assert.is_table(plugins)
  end)
end)
