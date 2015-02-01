--[[
	Asset Format

	Defines a base class for defining asset formats.
]]

local Coeus = (...)
local OOP = Coeus.Utility.OOP

local Format = OOP:Static()()

--[[
	Returns whether the filename should be loaded by this loader.
]]
function Format:Match(filename)
	return false
end

--[[
	Loads the asset defined by filename.
]]
function Format:Load(filename)
	return {}
end

return Format