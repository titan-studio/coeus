local Coeus = ...
local OOP = Coeus.Utility.OOP

local ImageData = OOP:Class(Coeus.Asset.Format) {
	Width = 0,
	Height = 0,

	image = nil,
	size = nil,
	format = 0,
}

ImageData.Format = {
	RGBA 			= 0,
	Depth			= 1,
	DepthStencil 	= 2,
	Single			= 3
}

return ImageData