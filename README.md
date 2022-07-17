# nvim-oscyank

nvim-oscyank is a rewrite of
[vim-oscyank](https://github.com/ojroques/vim-oscyank) in Lua for Neovim 0.7+.
It is deliberately minimalistic and featureless.

## Installation
With [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {'ojroques/nvim-oscyank'}
```

## Usage
Add this to your Neovim config:
```lua
require('oscyank').setup {}
vim.keymap.set('n', '<leader>c', require('oscyank').operator_copy, {expr = true})
vim.keymap.set('n', '<leader>cc', '<leader>c_', {remap = true})
vim.keymap.set('x', '<leader>c', require('oscyank').visual_copy)
```

In normal mode, `<leader>c` is an operator that will copy the given text to the
clipboard. In visual mode, `<leader>c` will copy the current selection.

## Configuration
The default options are:
```lua
require('oscyank').setup {
  max_length = 1000000,  -- Maximum length of selection
  silent = false,        -- Disable message on successful copy
  trim = true,           -- Trim text
}
```

## License
[LICENSE](./LICENSE)
