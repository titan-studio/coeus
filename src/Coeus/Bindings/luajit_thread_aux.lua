--[[
	LuaJIT Thread Auxiliary Binding

	A binding to some auxiliary C threading code in coeus_aux.
]]

local C = (...)
local Coeus = C:Get("Coeus")
local ffi = require("ffi")
local lib = Coeus.Bindings.coeus_aux

ffi.cdef([[
void ljta_run(void* L);
]])

return lib