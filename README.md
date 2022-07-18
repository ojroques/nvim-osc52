# nvim-osc52

A Neovim plugin to copy text to the system clipboard from anywhere using the
ANSI OSC52 sequence.

When this sequence is emitted by Neovim, the terminal will copy the given text
into the system clipboard. This is totally location-independent, users can copy
from anywhere including from remote SSH sessions. The only requirement is that
your terminal must support OSC52 which is the case for most modern terminal
emulators.

nvim-osc52 is basically a rewrite of
[vim-oscyank](https://github.com/ojroques/vim-oscyank) in Lua.

## Installation
With [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {'ojroques/nvim-osc52'}
```

## Usage
Add this to your config (assuming Neovim 0.7+):
```lua
vim.keymap.set('n', '<leader>c', require('osc52').copy_operator, {expr = true})
vim.keymap.set('n', '<leader>cc', '<leader>c_', {remap = true})
vim.keymap.set('x', '<leader>c', require('osc52').copy_visual)
```

Using these settings, in normal mode `<leader>c` is an operator that will copy
the given text to the clipboard. In visual mode `<leader>c` will copy the
current selection.

## Configuration
The default options are:
```lua
require('osc52').setup {
  max_length = 1000000,  -- Maximum length of selection
  silent = false,        -- Disable message on successful copy
  trim = true,           -- Trim text before copy
}
```

## Using nvim-osc52 as clipboard provider
You can use the plugin as your clipboard provider, see `:h provider-clipboard`
for more details. Simply add these lines to your Neovim config:
```lua
local function copy(lines, _)
  require('osc52').copy(table.concat(lines, '\n'))
end

local function paste()
  return {vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('')}
end

vim.g.clipboard = {
  name = 'osc52',
  copy = {['+'] = copy, ['*'] = copy},
  paste = {['+'] = paste, ['*'] = paste},
}

-- Now the '+' register will copy to system clipboard using OSC52
vim.keymap.set('n', '<leader>c', '"+y')
vim.keymap.set('n', '<leader>cc', '"+yy')
```
