# motioncoach.nvim

motioncoach.nvim is a pure-Lua Neovim plugin that watches your navigation and editing **episodes** and suggests more efficient Vim motions and techniques.

It is designed as a _coach_, not a linter: suggestions are contextual, rate-limited, undo-aware, and layered so beginners aren’t overwhelmed.

All output is delivered via **`vim.notify`**.

---

## Coaching Levels

motioncoach has **three coaching levels**:

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
  "yourname/motioncoach-nvim",
  config = function()
    require("motioncoach-nvim").setup({
      coachingLevel = 1,
    })
  end
}
```

## Commands

- Commands are intentionally simple and stable:

  `:MotionCoachOff`

  `:MotionCoachBeginner`

  `:MotionCoachAdvanced`

:MotionCoachToggle

:MotionCoachLevel 0|1|2

Suggested Keymaps

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

## Configuration

motioncoach is configured via:

```lua
require("motioncoach-nvim").setup({
  -- options
})
```

## Privacy Defaults

By default, motioncoach:

❌ Does not capture command-line input (: / ?)

❌ Does not capture insert-mode keys

✅ Uses a small rolling ring buffer for key patterns

✅ Captures yank contents locally only

❌ Never displays yank contents

❌ Never writes anything to disk

❌ Never sends data externally

You can override these if you want:

require("motioncoach-nvim").setup({
captureCommandLineKeys = false,
captureInsertModeKeys = false,
})

Typed Keys Display (Advanced Only)

In advanced mode, notifications include:

You typed: j×12 w d i w

The formatter:

filters noise (<Plug>, mouse events, etc.)

collapses repeats (j×12)

truncates long histories

Configure it like this:

require("motioncoach-nvim").setup({
typedKeysFormatter = {
maxTokens = 25,
collapseRepeats = true,
repeatMarker = "×",
}
})

### Plugin Recommendations

motioncoach can suggest plugins only after repeated evidence and only in advanced mode.

Recommendations are:

Fully configurable

Evidence-based

Designed to evolve over time

### Optional

Disable all plugin suggestions:

require("motioncoach-nvim").setup({
pluginRecommendations = {
enabled = false,
}
})

Disable a single recommendation:

require("motioncoach-nvim").setup({
pluginRecommendations = {
items = {
surround = { enabled = false },
}
}
})

### Provider Hook (Recommended)

For long-term evolution, you can supply a provider function that decides recommendations dynamically:

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

The provider runs before built-in defaults.

### Yank History

motioncoach captures yank events via TextYankPost and stores them in a per-buffer yank ring.

This is used only to improve coaching quality

Yank contents are never displayed

Yank contents never leave memory

Design Notes

Key logging is lightweight and deferred

Heavy analysis happens only at episode boundaries

Undo actions temporarily suppress suggestions

Mappings and plugins may affect key visibility — state diffs are always preferred

Suggestions are intentionally conservative

Philosophy

Teach the next better motion — not the perfect one.

motioncoach is meant to grow with you, not shame you, and once you got your Vim Motions down, remove it :)

## License

MIT
