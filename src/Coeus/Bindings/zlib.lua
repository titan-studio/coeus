local Coeus = ...

local ffi = require("ffi")
local z_lib

if (ffi.os == "Windows") then
	z_lib = ffi.load("lib/win32/zlib1.dll")
else
	z_lib = ffi.load("z")
end

ffi.cdef([[
	unsigned long compressBound(unsigned long sourceLen);
	int compress2(uint8_t *dest, unsigned long *destLen, const uint8_t *source, unsigned long sourceLen, int level);
	int uncompress(uint8_t *dest, unsigned long *destLen, const uint8_t *source, unsigned long sourceLen);
]])

return z_lib