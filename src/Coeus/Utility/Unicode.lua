local Coeus = (...)
local ffi = require("ffi")
local bit = require("bit")

local Unicode = {}

local UTF8_ACCEPT = 0
local UTF8_REJECT = 12
 
local utf8d = ffi.new("const uint8_t[364]", {
  -- The first part of the table maps bytes to character classes that
  -- to reduce the size of the transition table and create bitmasks.
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
   1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
   7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
   8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
  10,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3, 11,6,6,6,5,8,8,8,8,8,8,8,8,8,8,8,
 
  -- The second part is a transition table that maps a combination
  -- of a state of the automaton and a character class to a state.
   0,12,24,36,60,96,84,12,12,12,48,72, 12,12,12,12,12,12,12,12,12,12,12,12,
  12, 0,12,12,12,12,12, 0,12, 0,12,12, 12,24,12,12,12,12,12,24,12,24,12,12,
  12,12,12,12,12,12,12,24,12,12,12,12, 12,24,12,12,12,12,12,12,12,24,12,12,
  12,12,12,12,12,12,12,36,12,36,12,12, 12,36,12,12,12,12,12,36,12,36,12,12,
  12,36,12,12,12,12,12,12,12,12,12,12,
})
 
function Unicode.DecodeUTF8Byte(state, codep, byte)
	local ctype = utf8d[byte];
	if state ~= UTF8_ACCEPT then
		codep = bit.bor(bit.band(byte, 0x3f), bit.lshift(codep, 6))
	else
		codep = bit.band(bit.rshift(0xff, ctype), byte)
	end
	state = utf8d[256 + state + ctype]
	return state, codep
end

function Unicode.UTF8Iterate(utf8string, len)
	len = len or #utf8string
	local state = UTF8_ACCEPT
	local codep = 0
	local offset = 0
	local ptr = ffi.cast("uint8_t *", utf8string)
	local bufflen = len

	return function()
		while offset < bufflen do
			state, codep = Unicode.DecodeUTF8Byte(state, codep, ptr[offset])
			offset = offset + 1
			if state == UTF8_ACCEPT then
				return codep
			elseif state == UTF8_REJECT then
				return nil, state
			end
		end
		return nil, state
	end
end

function Unicode.UTF8Length(utf8string, len)
	local count = 0
	for codepoint, err in utf8_string_iterator(utf8string,len) do
		count = count + 1
	end
	return count
end

return Unicode