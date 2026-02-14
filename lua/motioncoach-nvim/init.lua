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
      vim.keymap.set('n', '<leader>m', '[M]otion Coach -->')
      vim.keymap.set('n', '<leader>m0', function()
        require('motioncoach-nvim').set_level(0)
      end, { desc = 'MotionCoach Disable[0]' })
      vim.keymap.set('n', '<leader>m1', function()
        require('motioncoach-nvim').set_level(1)
      end, { desc = 'MotionCoach Beginner Level[1]' })
      vim.keymap.set('n', '<leader>m2', function()
        require('motioncoach-nvim').set_level(2)
      end, { desc = 'MotionCoach Advanced Level[2]' })
      Keylog.install_if_needed()
      -- Episodes.set_coaching_level(Config.get().coachingLevel)
      vim.notify(
        'Motion Coach is here!\n\n   `<leader>m`   to disable or set level\n\n',
        2,
        { title = 'motioncoach' }
      )
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
