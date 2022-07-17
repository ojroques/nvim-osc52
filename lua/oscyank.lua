-------------------- VARIABLES -----------------------------
local base64 = require('base64')
local fmt = string.format
local options = {
  max_length = 1000000,  -- Maximum length of selection
  silent = false,        -- Disable message on successful copy
}
local M = {}

-------------------- UTILS ---------------------------------
local function echo(text, hl_group)
  vim.api.nvim_echo({{fmt('[oscyank] %s', text), hl_group or 'Normal'}}, false, {})
end

local function get_text(type)
  local types = {block = "`[\\<C-v>`]y", char = "`[v`]y", line = "'[V']y"}
  local command = fmt('noautocmd keepjumps normal! %s', types[type])
  local text = ''

  -- Save user settings
  local clipboard = vim.go.clipboard
  local selection = vim.go.selection
  local register = vim.fn.getreginfo('"')
  local visual_marks = {vim.fn.getpos("'<"), vim.fn.getpos("'>")}

  -- Copy text
  vim.go.clipboard = ''
  vim.go.selection = 'inclusive'
  vim.cmd(fmt('silent execute "%s"', command))
  text = vim.fn.getreg('"')

  -- Restore user settings
  vim.go.clipboard = clipboard
  vim.go.selection = selection
  vim.fn.setreg('"', register)
  vim.fn.setpos("'<", visual_marks[1])
  vim.fn.setpos("'>", visual_marks[2])

  return text
end

local function osc52(text)
  local text_b64 = base64.enc(text)
  local osc = fmt([[%s]52;c;%s%s]], string.char(0x1b), text_b64, string.char(0x07))
  return vim.fn.chansend(vim.v.stderr, osc)
end

-------------------- CORE ----------------------------------
function M.copy_callback(type)
  local text = get_text(type)

  if #text > options.max_length then
    echo(fmt('Selection is too big: length is %d, limit is %d', #text, options.max_length), 'WarningMsg')
    return
  end

  local success = osc52(text)

  if not success then
    echo('Failed to copy selection', 'ErrorMsg')
  elseif not options.silent then
    echo(fmt('%d characters copied', #text))
  end
end

function M.copy()
  vim.go.operatorfunc = "v:lua.require'oscyank'.copy_callback"
  return 'g@'
end

-------------------- SETUP ---------------------------------
function M.setup(user_options)
  if user_options then
    options = vim.tbl_extend('force', options, user_options)
  end
end

------------------------------------------------------------
return M
