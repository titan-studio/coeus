--Serves only to load the combined coeus_aux DLL
local Coeus = ...
local ffi = require("ffi")
local coeus_aux = ffi.load(Coeus.BinDir .. "coeus_aux")

return coeus_aux