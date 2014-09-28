--Serves only to load the combined coeus_aux DLL
local Coeus = ...
local ffi = require("ffi")
local coeus_aux = ffi.load("coeus_aux")

return coeus_aux