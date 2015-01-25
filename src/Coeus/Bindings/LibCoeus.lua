--Serves only to load the combined LibCoeus shared library
local Coeus = ...
local ffi = require("ffi")
local LibCoeus = ffi.load("LibCoeus")

return LibCoeus