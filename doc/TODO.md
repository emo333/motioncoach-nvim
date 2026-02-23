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

<!-- markdownlint-enable MD013 -->
