# **{ THIS PLUGIN IS NOT IN A PRODUCTION STATE !!! }**

![Danger](.github/assets/skull.png)

# `motioncoach-nvim`

`motioncoach-nvim` is a pure **Lua** Neovim plugin that watches your navigation and editing **episodes** and suggests more efficient Vim motions and techniques.

It is designed as a _coach_, not a linter or a tutorial. Suggestions are:

- contextual
- rate-limited
- undo-aware
- layered
  so beginner peeps aren’t overwhelmed and advanced peeps aren't annoyed.

All suggestions are delivered via a _"wrapped"_ **`vim.notify`**.

---

## Coaching Levels

`motioncoach-nvim` has **three coaching levels**:

- **Level 0** — Off
- **Level 1** — Beginner coaching
- **Level 2** — Advanced coaching
  - Includes deeper motion advice
  - Shows a formatted **“You typed:”** line for reflection

Beginner advice is always preferred over advanced advice, even at level 2.

---

## Features

### Beginner Coaching (Level 1+)

- Count compression (`10j`, `5k`)
- Scroll suggestions (`<C-d>`, `<C-u>`)
- Line landmarks (`0`, `^`, `$`)
- Large jump hints (`gg`, `G`)
- Horizontal efficiency (`w`, `b` vs `llll`)

---

### Advanced Coaching (Level 2)

- Key pattern analysis (via `vim.on_key`)
- State-diff validation (cursor movement, operators, undo)
- Text object suggestions:
  - `ciw`, `di"`, `ci(`, `dap`, etc.
- Register coaching:
  - `"_d`, `"0p`, `"+y`, `"+p`
- Marks & jumplist coaching:
  - `ma`, `'a`, `` `a ``
  - `<C-o>` / `<C-i>`
- Yank history capture (local, in-memory)
- Delimiter / surround coaching
- Optional Treesitter textobject hints
- Configurable plugin recommendations

Only **advanced mode** shows the formatted key history.

---

## Installation

### lazy.nvim

```lua
{
  "emo333/motioncoach-nvim",
  config = function()
    require("motioncoach-nvim").setup({
      coachingLevel = 1,
    })
  end
}
```

---

## Commands

`:MotionCoachOff`

`:MotionCoachBeginner`

`:MotionCoachAdvanced`

`:MotionCoachToggle`

`:MotionCoachLevel 0|1|2`

---

## Suggested Keymaps

```lua
vim.keymap.set("n", "<leader>mc", function()
  require("motioncoach-nvim").toggle()
end, { desc = "MotionCoach cycle level" })

vim.keymap.set("n", "<leader>m0", function()
  require("motioncoach-nvim").set_level(0)
end)

vim.keymap.set("n", "<leader>m1", function()
  require("motioncoach-nvim").set_level(1)
end)

vim.keymap.set("n", "<leader>m2", function()
  require("motioncoach-nvim").set_level(2)
end)
```

---

## Configuration

`motioncoach-nvim` is configured via:

```lua
require("motioncoach-nvim").setup({
  -- options
})
```

### Notification Configuration (Optional)

- either add this to your snacks.nvim configuration or;
  add this as a plugin (eg. `snacks.lua`):

```lua
return {
  {
    "folke/snacks.nvim",
    config = function(_, opts)
      require("snacks").setup(opts)

      local original_notify = Snacks.notifier.notify
      ---@diagnostic disable-next-line: duplicate-set-field
      Snacks.notifier.notify = function(msg, level, notify_opts)
        notify_opts = notify_opts or {}

        -- Custom logic: If msg has "Motion" in it, set timeout to 10 seconds
        if msg:find("Motion") then
          notify_opts.timeout = 10000
        end

        return original_notify(msg, level, notify_opts)
      end
    end,
    opts = {
      notifier = {
        -- Set the maximum width for notifications before they wrap/expand
        width = { min = 40, max = 0.4 }, -- max can be a percentage of screen width
        -- Default is 3000ms (3 seconds)
        -- timeout = 5000, -- Increase this value (in milliseconds)
        -- Return true to keep the notification on screen
        keep = function(notif)
          local severity = vim.log.levels
          return notif.level == severity.ERROR or notif.level == severity.WARN
        end,
      },
      styles = {
        notification = {
          wo = {
            wrap = true, -- Enable line wrapping for long messages
          },
        },
      },
    },
  },
}

```

---

## Privacy

By default, `motioncoach-nvim`:

❌ Does not capture command-line input (: / ?)

❌ Does not capture insert-mode keys

✅ Uses a small rolling ring buffer for key patterns

✅ Captures yank contents locally only

❌ Never displays yank contents

❌ Never writes anything to disk

❌ Never sends data externally

You can override these if you want:

```lua
require("motioncoach-nvim").setup({
captureCommandLineKeys = false,
captureInsertModeKeys = false,
})

```

### Typed Keys Display (Advanced Only)

- In advanced mode, notifications include:

```
You typed: j×12 w d i w
```

### Yank History

`motioncoach-nvim` captures yank events via `TextYankPost` and stores them in a per-buffer yank ring.

- This is used only to improve coaching quality

- Yank contents are never displayed

- Yank contents never leave memory

---

## The formatter

- filters noise (<Plug>, mouse events, etc.)

- collapses repeats (j×12)

- truncates long histories

Configure it like this:

```lua
require("motioncoach-nvim").setup({
  typedKeysFormatter = {
    maxTokens = 25,
    collapseRepeats = true,
    repeatMarker = "×",
  }
})
```

---

## Plugin Recommendations { WORK IN PROGRESS }

`motioncoach.nvim` can suggest plugins only after repeated evidence and only in advanced mode.

- Recommendations are:
  - Fully configurable

  - Evidence-based

  - Designed to evolve over time

### Optional

- Disable all plugin recommendations:

```lua
require("motioncoach-nvim").setup({
pluginRecommendations = {
enabled = false,
}
})
```

- Disable a single recommendation:

```lua
require("motioncoach-nvim").setup({
pluginRecommendations = {
items = {
surround = { enabled = false },
}
}
})
```

---

## Provider Hook { WORK IN PROGRESS }

For long-term evolution, you can supply a provider function that decides recommendations dynamically:

```lua
require("motioncoach-nvim").setup({
pluginRecommendations = {
provider = function(evidenceCounters, context)
if (evidenceCounters.surroundLikeEvidenceCount or 0) >= 6 then
evidenceCounters.surroundLikeEvidenceCount = 0
return "Plugin idea: consider mini.surround or nvim-surround."
end
return nil
end
}
})
```

- The provider runs before built-in defaults.

---

## Dev Notes

- Key logging is lightweight and deferred

- Heavy analysis happens only at episode boundaries

- Undo actions temporarily suppress suggestions

- Mappings and plugins may affect key visibility — state diffs are always preferred

- Suggestions are intentionally conservative

---

## Philosophy

- Learn the next better motion — not the perfect one.

- `motioncoach-nvim` is meant to grow with you and once you got your Vim Motions down, remove it :)

---

## About the Author (emo333)

- I am not a professional programmer.
- I have been programming most of my life;
  either as side duties inherent to work or as hobby at home.
- Vim/NeoVim/Lua are all new to me ( started delving into these around November 2025 ).
- I started this project based on my own desire to have something "inside" NeoVim to remind/assist/suggest/coach me learning Vim motions.
- I used ai to assist me developing this. ( about 50/50(impressed/disappointed) on the ai results ).

---

## Contributions

Hell yeah! Bring em!

---

## License

MIT(ch) <-- I crack me up ;)

---
