local Config = require('motioncoach-nvim.config')
local State = require('motioncoach-nvim.state')
local Keylog = require('motioncoach-nvim.keylog')
local Episodes = require('motioncoach-nvim.episodes')

local MotionCoachNvim = {}

function MotionCoachNvim.setup(userConfig)
  Config.apply(userConfig or {})
  State.init()
  Keylog.install_if_needed()

  Episodes.install_autocmds()
  Episodes.set_coaching_level(Config.get().coachingLevel)
end

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
