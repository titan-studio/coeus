local Coeus = ...
local OOP = Coeus.Utility.OOP

local ImageData = OOP:Class(Coeus.Asset.Format) {
	Width = 0,
	Height = 0,

	image = nil,
	size = nil,
	format = 0,
}

ImageData.Format = OOP:Static() {
	RGBA 			= 0,
	Depth			= 1,
	DepthStencil 	= 2
}

return ImageData