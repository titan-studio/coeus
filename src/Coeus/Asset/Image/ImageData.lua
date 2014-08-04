local Coeus = ...
local OOP = Coeus.Utility.OOP

local ImageData = OOP:Class(Coeus.Asset.Format) {
	Width = 0,
	Height = 0,

	data = nil,
	size = nil
}

return ImageData