--Serves only to load the combined coeus_aux DLL
local Coeus = ...
local ffi = require("ffi")
local coeus_aux = (ffi.os == "Windows") and ffi.load("lib/win32/coeus_aux.dll") or ffi.C

return coeus_aux