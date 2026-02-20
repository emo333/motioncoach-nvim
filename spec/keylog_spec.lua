local Keylog = require('motioncoach-nvim.keylog')

describe('keylog.lua', function()
  it('key_exists_in_keyring finds key', function()
    local keys = { 'a', 'b', 'c' }
    assert(Keylog.key_exists_in_keyring(keys, 'b'))
    assert(not Keylog.key_exists_in_keyring(keys, 'z'))
  end)
end)
