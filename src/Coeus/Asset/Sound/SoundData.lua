local Coeus = ...
local OpenAL = Coeus.Bindings.OpenAL
local OOP = Coeus.Utility.OOP

local SoundData = OOP:Class(Coeus.Asset.Format) {
	size = 0,
	channels = 0,
	frequency = 0,
	data = nil,
	format = 0,
	channels = 0
}

return SoundData