local Coeus = ...
local OOP = Coeus.Utility.OOP

local SoundLoader = OOP:Static(Coeus.Asset.Loader) {
	Formats = Coeus:FullyLoadDirectory("Asset.Sound.Formats")
}

return SoundLoader