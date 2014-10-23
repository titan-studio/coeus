--[[
	Sound Loader

	Loads sounds, both streaming and static.
]]

local Coeus = (...)
local OOP = Coeus.Utility.OOP

local SoundLoader = OOP:Static(Coeus.Asset.Loader) {
	Formats = Coeus.Asset.Sound.Formats:FullyLoad()
}

return SoundLoader