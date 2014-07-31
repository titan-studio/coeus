local Coeus = ...
local ffi = require("ffi")
local lib = Coeus.Bindings.coeus_aux

ffi.cdef([[
	void ljta_run(void* L);
]])

return lib