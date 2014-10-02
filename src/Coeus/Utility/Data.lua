local Coeus = (...)
local ffi = require("ffi")
local C = Coeus.Bindings.C
local Data = {}

function Data.Alloc(ctype, count)
	return ffi.cast(ctype .. "*", C.malloc(ffi.sizeof(ctype) * (count or 1)))
end

function Data.Free(data)
	C.free(data)
end

return Data