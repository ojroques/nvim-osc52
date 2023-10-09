# nvim-osc52

A Neovim plugin to copy text to the system clipboard using the ANSI OSC52
sequence.

The plugin wraps a piece of text inside an OSC52 sequence and writes it to
Neovim's stderr. When your terminal detects the OSC52 sequence, it will copy the
text into the system clipboard.

This is totally location-independent, you can copy text from anywhere including
from remote SSH sessions. The only requirement is that your terminal must
support OSC52 which is the case for most modern terminal emulators.

nvim-osc52 is a rewrite of
[vim-oscyank](https://github.com/ojroques/vim-oscyank) in Lua.

## Installation
With [packer.nvim](https://github.com/wbthomason/packer.nvim) for instance:
```lua
use {'ojroques/nvim-osc52'}
```

### Configuration for tmux

If you are using tmux, run these steps first: [enabling OSC52 in
tmux](https://github.com/tmux/tmux/wiki/Clipboard#quick-summary).

Then, you can use the tmux option `set-clipboard on` or `allow-passthrough on`.

For tmux versions before 3.3a, you will need to use the `set-clipboard` option:
`set -s set-clipboard on`

For tmux versions starting with 3.3a, you can configure tmux to allow passthrough
of escape sequences (`set -g allow-passthrough on`). With this option you can leave
`set-clipboard` to its default (`external`).
The allow-passthrough option works well for nested tmux sessions or when running
tmux on both the local and remote servers. When using allow-passthrough, be sure
to enable `tmux_passthrough` for this plugin.

## Usage
Add this to your config (assuming Neovim 0.7+):
```lua
vim.keymap.set('n', '<leader>c', require('osc52').copy_operator, {expr = true})
vim.keymap.set('n', '<leader>cc', '<leader>c_', {remap = true})
vim.keymap.set('v', '<leader>c', require('osc52').copy_visual)
```

Using these mappings:
* In normal mode, <kbd>\<leader\>c</kbd> is an operator that will copy the given
  text to the clipboard.
* In normal mode, <kbd>\<leader\>cc</kbd> will copy the current line.
* In visual mode, <kbd>\<leader\>c</kbd> will copy the current selection.

## Configuration
The available options with their default values are:
```lua
require('osc52').setup {
  max_length = 0,           -- Maximum length of selection (0 for no limit)
  silent = false,           -- Disable message on successful copy
  trim = false,             -- Trim surrounding whitespaces before copy
  tmux_passthrough = false, -- Use tmux passthrough (requires tmux: set -g allow-passthrough on)
}
```

## Advanced usage
The following methods are also available:
* `require('osc52').copy(text)`: copy text `text`
* `require('osc52').copy_register(register)`: copy text from register `register`

For instance, to automatically copy text that was yanked into register `+`:
```lua
function copy()
  if vim.v.event.operator == 'y' and vim.v.event.regname == '+' then
    require('osc52').copy_register('+')
  end
end

vim.api.nvim_create_autocmd('TextYankPost', {callback = copy})
```

## Using nvim-osc52 as clipboard provider
You can use the plugin as your clipboard provider, see `:h provider-clipboard`
for more details. Simply add these lines to your config:
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
