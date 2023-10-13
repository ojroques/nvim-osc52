-------------------- VARIABLES -----------------------------
local base64 = require('osc52.base64')
local fmt = string.format
local commands = {
  operator = {block = "`[\\<C-v>`]y", char = "`[v`]y", line = "'[V']y"},
  visual = {[''] = 'y', ['V'] = 'y', ['v'] = 'y', [''] = 'y'},
}
local options = {
  max_length = 0,           -- Maximum length of selection (0 for no limit)
  silent = false,           -- Disable message on successful copy
  trim = false,             -- Trim surrounding whitespaces before copy
  tmux_passthrough = false, -- Use tmux passthrough (requires tmux: set -g allow-passthrough on)
  osc52 = '\27]52;c;%s\7',
}
local M = {}

-------------------- UTILS ---------------------------------
local function echo(text, hl_group)
  vim.api.nvim_echo({{fmt('[osc52] %s', text), hl_group or 'Normal'}}, false, {})
end

local function get_text(mode, type)
  -- Save user settings
  local clipboard = vim.go.clipboard
  local register = vim.fn.getreginfo('"')
  local visual_marks

  -- Save previous visual marks in operator mode
  if mode == 'operator' then
    visual_marks = {vim.fn.getpos("'<"), vim.fn.getpos("'>")}
  end

  -- Retrieve text
  vim.go.clipboard = ''
  local command = fmt('keepjumps normal! %s', commands[mode][type])
  vim.cmd(fmt('silent execute "%s"', command))
  local text = vim.fn.getreg('"')

  -- Restore user settings
  vim.go.clipboard = clipboard
  vim.fn.setreg('"', register)

  -- Restore previous visual marks in operator mode
  if mode == 'operator' then
    vim.fn.setpos("'<", visual_marks[1])
    vim.fn.setpos("'>", visual_marks[2])
  end

  return text or ''
end

local function trim_text(text)
  local i, j = string.find(text, '^%s+')

  -- Remove common indent from all lines
  if i then
    local indent = string.rep('%s', j - i + 1)
    text = string.gsub(text, fmt('\n%s', indent), '\n')
  end

  return vim.trim(text)
end

local function write(osc52)
  local success = false

  if vim.fn.filewritable('/dev/fd/2') == 1 then
    success = vim.fn.writefile({osc52}, '/dev/fd/2', 'b') == 0
  else
    success = vim.fn.chansend(vim.v.stderr, osc52) > 0
  end

  return success
end

-------------------- PUBLIC --------------------------------
function M.copy(text)
  text = options.trim and trim_text(text) or text

  if options.max_length > 0 and #text > options.max_length then
    echo(fmt('Selection is too big: length is %d, limit is %d', #text, options.max_length), 'WarningMsg')
    return
  end

  local text_b64 = base64.enc(text)
  local osc52 = fmt(options.osc52, text_b64)
  local msg = '%d characters copied'
  if options.tmux_passthrough and os.getenv("TMUX") then
    osc52 = fmt('\27Ptmux;\27%s\27\\', osc52)
    msg = msg .. ' (tmux passthrough)'
  end
  local success = write(osc52)

  if not success then
    echo('Failed to copy selection', 'ErrorMsg')
  elseif not options.silent then
    echo(fmt(msg, #text))
  end

  return success
end

function M.paste()
  local osc52 = fmt(options.osc52, '?')
  local success = write(osc52)

  if not success then
    echo('Failed to paste', 'ErrorMsg')
  end

  return success
end

function M.copy_operator_cb(type)
  local text = get_text('operator', type)
  return M.copy(text)
end

function M.copy_operator()
  vim.go.operatorfunc = "v:lua.require'osc52'.copy_operator_cb"
  return 'g@'
end

function M.copy_visual()
  local text = get_text('visual', vim.fn.visualmode())
  return M.copy(text)
end

function M.copy_register(register)
  local text = vim.fn.getreg(register)
  return M.copy(text)
end

-------------------- SETUP ---------------------------------
function M.setup(user_options)
  if user_options then
    options = vim.tbl_extend('force', options, user_options)
  end
end

------------------------------------------------------------
return M
