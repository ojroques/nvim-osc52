# nvim-osc52

A Neovim plugin to copy text to the system clipboard using the ANSI OSC52
sequence.

The plugin wraps a piece of text inside an OSC52 sequence and writes it to
Neovim's stderr. When your terminal detects the OSC52 sequence, it will copy the
text into the system clipboard.

This is totally location-independent, you can copy text from anywhere including
from remote SSH sessions. The only requirement is that your terminal must
support OSC52 which is the case for most modern terminal emulators.

nvim-osc52 is basically a rewrite of
[vim-oscyank](https://github.com/ojroques/vim-oscyank) in Lua.

## Installation
With [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {'ojroques/nvim-osc52'}
```

**If you are using tmux**, run these steps first: [enabling OSC52 in
tmux](https://github.com/tmux/tmux/wiki/Clipboard#quick-summary). Then make sure
`set-clipboard` is set to `on`: `set -s set-clipboard on`.

## Usage
Add this to your config (assuming Neovim 0.7+):
```lua
vim.keymap.set('n', '<leader>c', require('osc52').copy_operator, {expr = true})
vim.keymap.set('n', '<leader>cc', '<leader>c_', {remap = true})
vim.keymap.set('x', '<leader>c', require('osc52').copy_visual)
```

Using these mappings:
* In normal mode, <kbd>\<leader\>c</kbd> is an operator that will copy the given
  text to the clipboard.
* In normal mode, <kbd>\<leader\>cc</kbd> will copy the current line.
* In visual mode, <kbd>\<leader\>c</kbd> will copy the current selection.

## Configuration
The default options are:
```lua
require('osc52').setup {
  max_length = 0,  -- Maximum length of selection (0 for no limit)
  silent = false,  -- Disable message on successful copy
  trim = false,    -- Trim text before copy
}
```

## Advanced usage
The following methods are also available:
* `require('osc52').copy(text)`: copy text `text`
* `require('osc52').copy_register(register)`: copy text from register `register`

For instance, to automatically copy text that was yanked into register `c`:
```lua
function copy()
  if vim.v.event.operator == 'y' and vim.v.event.regname == 'c' then
    require('osc52').copy_register('c')
  end
end

vim.api.nvim_create_autocmd('TextYankPost', {callback = copy})
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

Note that if you set your clipboard provider like the example above, copying
text from outside Neovim and pasting with <kbd>p</kbd> won't work. But you can
still use the paste shortcut of your terminal emulator (usually
<kbd>ctrl+shift+v</kbd>).
