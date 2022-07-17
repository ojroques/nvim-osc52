# nvim-oscyank

[vim-oscyank](https://github.com/ojroques/vim-oscyank) rewritten in Lua for
Neovim 0.7+. It is deliberately minimalistic and featureless.

## Installation
With [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {'ojroques/nvim-oscyank'}
```

## Usage
Add this to your Neovim config:
```lua
require('oscyank').setup {}
vim.keymap.set('n', '<leader>c', require('oscyank').copy, {expr = true})
vim.keymap.set('n', '<leader>cc', '<leader>c_', {remap = true})
```

## Configuration
The default options are:
```lua
require('oscyank').setup {
  max_length = 1000000,  -- Maximum length of selection
  silent = false,        -- Disable message on successful copy
}
```

## License
[LICENSE](./LICENSE)
