--Serves only to load the combined coeus_aux DLL
local Coeus = ...
local ffi = require("ffi")
local so = ffi.load(Coeus.BinDir .. "coeus_aux")
local coeus_aux = (ffi.os == "Windows") and so or ffi.C

return coeus_aux