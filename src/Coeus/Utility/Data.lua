--[[
	Data Utility Functions

	Provides helpful functions for handling unmanaged data from within LuaJIT.
]]

local C = (...)
local Coeus = C:Get("Coeus")
local ffi = require("ffi")
local C_ = Coeus.Bindings.C_
local Data = {}

--[[
	Allocates some data of a given pointer ctype.
	It's recommended that ctype be pre-built with ffi.type. 
]]
function Data.Alloc(ctype, count)
	return ffi.cast(ctype, C_.malloc(ffi.sizeof(ctype) * (count or 1)))
end

--[[
	Frees some data defined by a pointer.
]]
function Data.Free(data)
	C_.free(data)
end

return Data