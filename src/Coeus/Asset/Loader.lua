--[[
	Base Loader

	A parent class for all asset loaders.
]]

local Coeus = (...)
local OOP = Coeus.Utility.OOP

local Loader = OOP:Static()
	:Members {
		Formats = {}
	}

--[[
	Loads the asset located at path.
]]
function Loader:Load(path, ...)
	local loader

	for name, member in pairs(self.Formats) do
		if (member:Match(path, ...)) then
			return member:Load(path, ...)
		end
	end

	print("Could not find loader for file at " .. (path or "nil"))
end

return Loader