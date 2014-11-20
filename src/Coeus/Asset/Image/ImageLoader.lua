--[[
	Image Loader

	Defines a loader for loading images.
]]

local C = (...)
local Coeus = C:Get("Coeus")
local OOP = Coeus.Utility.OOP

local ImageLoader = OOP:Static(Coeus.Asset.Loader) {
	Formats = Coeus.Asset.Image.Formats:FullyLoad()
}

return ImageLoader