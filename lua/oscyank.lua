-------------------- VARIABLES -----------------------------
local base64 = require('base64')
local fmt = string.format
local commands = {
  operator = {block = "`[\\<C-v>`]y", char = "`[v`]y", line = "'[V']y"},
  visual = {['V'] = 'y', ['v'] = 'y', [''] = 'y'},
}
local options = {
  max_length = 1000000,  -- Maximum length of selection
  silent = false,        -- Disable message on successful copy
  trim = true,           -- Trim text before copy
}
local M = {}

-------------------- UTILS ---------------------------------
local function echo(text, hl_group)
  vim.api.nvim_echo({{fmt('[oscyank] %s', text), hl_group or 'Normal'}}, false, {})
end

local function get_text(mode, type)
  -- Save user settings
  local clipboard = vim.go.clipboard
  local selection = vim.go.selection
  local register = vim.fn.getreginfo('"')
  local visual_marks = {vim.fn.getpos("'<"), vim.fn.getpos("'>")}

  -- Retrieve text
  vim.go.clipboard = ''
  vim.go.selection = 'inclusive'
  local command = fmt('keepjumps normal! %s', commands[mode][type])
  vim.cmd(fmt('silent execute "%s"', command))
  local text = vim.fn.getreg('"')

  -- Restore user settings
  vim.go.clipboard = clipboard
  vim.go.selection = selection
  vim.fn.setreg('"', register)
  vim.fn.setpos("'<", visual_marks[1])
  vim.fn.setpos("'>", visual_marks[2])

  return text or ''
end

-------------------- PUBLIC --------------------------------
function M.osc52(text)
  text = options.trim and vim.trim(text) or text

  if #text > options.max_length then
    echo(fmt('Selection is too big: length is %d, limit is %d', #text, options.max_length), 'WarningMsg')
    return
  end

  local text_b64 = base64.enc(text)
  local osc = fmt('%s]52;c;%s%s', string.char(0x1b), text_b64, string.char(0x07))
  local success = vim.fn.chansend(vim.v.stderr, osc)

  if not success then
    echo('Failed to copy selection', 'ErrorMsg')
  elseif not options.silent then
    echo(fmt('%d characters copied', #text))
  end
end

function M.copy_operator_cb(type)
  local text = get_text('operator', type)
  M.osc52(text)
end

function M.copy_operator()
  vim.go.operatorfunc = "v:lua.require'oscyank'.copy_operator_cb"
  return 'g@'
end

function M.copy_visual()
  local text = get_text('visual', vim.fn.visualmode())
  M.osc52(text)
end

function M.copy_register(register)
  local text = vim.fn.getreg(register)
  M.osc52(text)
end

-------------------- SETUP ---------------------------------
function M.setup(user_options)
  if user_options then
    options = vim.tbl_extend('force', options, user_options)
  end
end

------------------------------------------------------------
return M
