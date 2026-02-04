local MotionCoachNvim = {}

local Config = require('motioncoach-nvim.config')
local Episodes = require('motioncoach-nvim.episodes')
local Keylog = require('motioncoach-nvim.keylog')
local State = require('motioncoach-nvim.state')

function MotionCoachNvim.setup(userConfig)
  Config.apply(userConfig or {})
  State.init()
  Episodes.install_autocmds()
  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function()
      Keylog.install_if_needed()
      Episodes.set_coaching_level(Config.get().coachingLevel)
    end,
  })
end

---@param level number 0 = off | 1 = Beginner | 2 = Advanced
function MotionCoachNvim.set_level(level)
  Episodes.set_coaching_level(level)
end

function MotionCoachNvim.toggle()
  Episodes.toggle_level()
end

function MotionCoachNvim.level()
  return Config.get().coachingLevel
end

return MotionCoachNvim
