local lshift = require('bit').lshift
local rshift = require('bit').rshift
local band = require('bit').band
local bor = require('bit').bor

local M = {}

local base64 = {
  [0] = 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/',
}
local mask = 0x3f -- 0b00111111

function M.enc(s)
  local len = string.len(s)
  local output = {}

  for i = 1, len, 3 do
    local byte1, byte2, byte3 = string.byte(s, i, i + 2)
    local bits = bor(lshift(byte1, 16), lshift(byte2 or 0, 8), byte3 or 0)
    table.insert(output, base64[rshift(bits, 18)])
    table.insert(output, base64[band(rshift(bits, 12), mask)])
    table.insert(output, base64[band(rshift(bits, 6), mask)])
    table.insert(output, base64[band(bits, mask)])
  end

  for i = 0, 1 - ((len - 1) % 3) do
    output[#output - i] = '='
  end

  return table.concat(output)
end

return M
