--                __  _                             __
--    __ _  ___  / /_(_)__  ___  _______  ___ _____/ /
--   /  ' \/ _ \/ __/ / _ \/ _ \/ __/ _ \/ _ `/ __/ _ \
--  /_/_/_/\___/\__/_/\___/_//_/\__/\___/\_,_/\__/_//_/
--  ---------------------------------------------------

local MotionCoachNvim = {}

local Config = require('motioncoach-nvim.config')
local Episodes = require('motioncoach-nvim.episodes')
local Keylog = require('motioncoach-nvim.keylog')
-- local State = require('motioncoach-nvim.state')

---@param userConfig {} | nil --the default config if Homie has no custom config
function MotionCoachNvim.setup(userConfig)
  Config.apply(userConfig or {})
  -- State.init()
  if Config.get().coachingLevel > 0 then
    Episodes.install_autocmds()
  end
  vim.api.nvim_create_autocmd('VimEnter', {
    group = 'MotionCoach',
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
      -- Episodes.set_coaching_level(Config.get().coachingLevel)

      -- Commands
      vim.api.nvim_create_user_command('MotionCoachOff', function()
        Episodes.set_coaching_level(0)
      end, {})
      vim.api.nvim_create_user_command('MotionCoachBeginner', function()
        Episodes.set_coaching_level(1)
      end, {})
      vim.api.nvim_create_user_command('MotionCoachAdvanced', function()
        Episodes.set_coaching_level(2)
      end, {})
      vim.api.nvim_create_user_command('MotionCoachLevel', function(opts)
        Episodes.set_coaching_level(tonumber(opts.args))
      end, {
        nargs = 1,
        complete = function()
          return { '0', '1', '2' }
        end,
      })
      vim.notify(' [Enabled]  ` <leader>m ` to disable or set level', 2, { title = 'motioncoach' })
    end,
  })
  Keylog.install_if_needed()
end

---@param level number 0 = off | 1 = Beginner | 2 = Advanced
function MotionCoachNvim.set_level(level)
  Episodes.set_coaching_level(level)
end

function MotionCoachNvim.level()
  return Config.get().coachingLevel
end

-- using for testing the issue with jj or kk quickly returning a g
-- vim.opt.timeoutlen = 300 -- Set to 300ms or lower

return MotionCoachNvim
