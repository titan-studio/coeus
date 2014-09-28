--Serves only to load the combined coeus_aux shared library
local Coeus = ...
local ffi = require("ffi")
local coeus_aux

if (ffi.os == "Windows") then
	coeus_aux = ffi.load(Coeus.BinDir .. "coeus_aux")
else
	coeus_aux = ffi.load("coeus_aux")
end

return coeus_aux