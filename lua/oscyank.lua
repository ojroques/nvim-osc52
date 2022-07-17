-------------------- VARIABLES -----------------------------
local base64 = require('base64')
local fmt = string.format
local commands = {
  operator = {block = "`[\\<C-v>`]y", char = "`[v`]y", line = "'[V']y"},
  visual = {['V'] = "y", ['v'] = "y", [''] = "y"},
}
local options = {
  max_length = 1000000,  -- Maximum length of selection
  silent = false,        -- Disable message on successful copy
  trim = true,           -- Trim text
}
local M = {}

-------------------- CORE ----------------------------------
local function echo(text, hl_group)
  vim.api.nvim_echo({{fmt('[oscyank] %s', text), hl_group or 'Normal'}}, false, {})
end

local function get_text(mode, type)
  local command = fmt('noautocmd keepjumps normal! %s', commands[mode][type])
  local text = ''

  -- Save user settings
  local clipboard = vim.go.clipboard
  local selection = vim.go.selection
  local register = vim.fn.getreginfo('"')
  local visual_marks = {vim.fn.getpos("'<"), vim.fn.getpos("'>")}

  -- Retrieve text
  vim.go.clipboard = ''
  vim.go.selection = 'inclusive'
  vim.cmd(fmt('silent execute "%s"', command))
  text = vim.fn.getreg('"')

  -- Trim text
  if options.trim then
    text = vim.trim(text)
  end

  -- Restore user settings
  vim.go.clipboard = clipboard
  vim.go.selection = selection
  vim.fn.setreg('"', register)
  vim.fn.setpos("'<", visual_marks[1])
  vim.fn.setpos("'>", visual_marks[2])

  return text
end

local function osc52(text)
  if #text > options.max_length then
    echo(fmt('Selection is too big: length is %d, limit is %d', #text, options.max_length), 'WarningMsg')
    return
  end

  local text_b64 = base64.enc(text)
  local osc = fmt([[%s]52;c;%s%s]], string.char(0x1b), text_b64, string.char(0x07))
  local success = vim.fn.chansend(vim.v.stderr, osc)

  if not success then
    echo('Failed to copy selection', 'ErrorMsg')
  elseif not options.silent then
    echo(fmt('%d characters copied', #text))
  end
end

-------------------- PUBLIC --------------------------------
function M.operator_copy_cb(type)
  local text = get_text('operator', type)
  osc52(text)
end

function M.operator_copy()
  vim.go.operatorfunc = "v:lua.require'oscyank'.operator_copy_cb"
  return 'g@'
end

function M.visual_copy()
  local text = get_text('visual', vim.fn.visualmode())
  osc52(text)
end

-------------------- SETUP ---------------------------------
function M.setup(user_options)
  if user_options then
    options = vim.tbl_extend('force', options, user_options)
  end
end

------------------------------------------------------------
return M
