local Coeus = ...
local OOP = Coeus.Utility.OOP

local Loader = OOP:Static() {
	Formats = {}
}

function Loader:Load(path, ...)
	local loader

	for name, member in pairs(self.Formats) do
		if (member:Match(path, ...)) then
			loader = member
			break
		end
	end

	if (not loader) then
		print("Could not find loader for file at " .. (path or "nil"))
		return
	end

	return loader:Load(path, ...)
end

return Loader