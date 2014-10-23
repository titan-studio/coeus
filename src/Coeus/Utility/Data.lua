--[[
	Data Utility Functions

	Provides helpful functions for handling unmanaged data from within LuaJIT.
]]

local Coeus = (...)
local ffi = require("ffi")
local C = Coeus.Bindings.C
local Data = {}

--[[
	Allocates some data of a given pointer ctype.
	It's recommended that ctype be pre-built with ffi.type. 
]]
function Data.Alloc(ctype, count)
	return ffi.cast(ctype, C.malloc(ffi.sizeof(ctype) * (count or 1)))
end

--[[
	Frees some data defined by a pointer.
]]
function Data.Free(data)
	C.free(data)
end

return Data