local motioncoachnvim_config = require('motioncoach-nvim.config').get()

---@diagnostic disable
describe('neovim plugin', function()
  it('work as expect', function()
    local result = motioncoachnvim_config
    assert.is_table(result)
  end)
end)
