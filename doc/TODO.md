<!-- markdownlint-disable MD013 -->

# TODO: Items to add to motioncoach-nvim

- create suggestion model @class and break out suggewstions into a lua table

- handle other windows ( like explorer type windows ) disabling motioncoach while inside those windows

- get file #lines and use for suggestions based on the length of the file
  (eg. exclude "big move" and "huge move" suggestion checks)

- iterate installed plugins(and if enabled) and use for suggestion determinations

- detect if mouse is enabled and suggest disabling

- detect if moving to/from same files and suggest using marks

- detect file type and check for nvim-lsp installed, suggest using LSP commands/keymaps

- detect if folds exist in file and suggest using the folds (if `z` {fold related keymap eg. `c`} has not been used in keyring)

- detect existing diagnostics in buffer and suggest diagnostic navigation keymaps (if installed)

- create key combination patterns for various suggestions
  - dwbdw = deleted word while in middle of word then moved to begin of word and deleted
    - suggest "use `diw` (delete inside word) to delete words. Also can use `daw` (delete around word) to delete word AND the surrounding characters (spaces/quotes/parens/braces/brackets). You can also use `di` + `"` to delete everything inside quotation marks OR `di` + `(` to delete everything inside parens etc...

  - hvwy OR lvby = moved in word to get to end or begin then visual select word to yank
  <!-- markdownlint-enable MD013 -->
