local Coeus = ...
local OOP = Coeus.Utility.OOP

local SoundLoader = OOP:Class(Coeus.Asset.Loader) {
	Formats = Coeus.FullyLoadDirectory(Coeus.Asset.Sound.Formats)
}

function SoundLoader:Load(path, static)
	static = not not static

	local loader

	for name, member in pairs(self.Formats) do
		if (member:Match(path, static)) then
			loader = member
			break
		end
	end

	if (not loader) then
		print("Could not find loader for file at " .. (path or "nil"))
		return
	end

	return loader:Load(path)
end

return SoundLoader