--[[
	Model Loader

	Defines a loader for loading model data.
]]

local C = (...)
local Coeus = C:Get("Coeus")
local OOP = Coeus.Utility.OOP

local ModelLoader = OOP:Static(Coeus.Asset.Loader) {
	Formats = Coeus.Asset.Model.Formats:FullyLoad()
}

return ModelLoader