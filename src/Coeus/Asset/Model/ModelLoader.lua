--[[
	Model Loader

	Defines a loader for loading model data.
]]

local Coeus = (...)
local OOP = Coeus.Utility.OOP

local ModelLoader = OOP:Static(Coeus.Asset.Loader) {
	Formats = Coeus.Asset.Model.Formats:FullyLoad()
}

return ModelLoader