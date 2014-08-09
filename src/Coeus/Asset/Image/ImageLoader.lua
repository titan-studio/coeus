local Coeus = ...
local OOP = Coeus.Utility.OOP

local ImageLoader = OOP:Static(Coeus.Asset.Loader) {
	Formats = Coeus:FullyLoadDirectory("Asset.Image.Formats")
}

return ImageLoader