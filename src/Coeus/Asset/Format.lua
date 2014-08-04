local Coeus = ...
local OOP = Coeus.Utility.OOP

local Format = OOP:Static()()

function Format:Match(filename)
	return false
end

function Format:Load(filename)
	return {}
end

return Format