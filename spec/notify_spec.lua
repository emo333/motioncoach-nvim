---@diagnostic disable
local Notify = require('motioncoach-nvim.notify')

describe('notify.lua', function()
  it('format_message returns string', function()
    local message = Notify.format_message('hello')
    assert.is_string(message)
    assert(message:match('hello'))
  end)
end)
