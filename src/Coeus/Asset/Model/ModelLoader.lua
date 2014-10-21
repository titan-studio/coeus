local Coeus = ...
local OOP = Coeus.Utility.OOP

local ModelLoader = OOP:Static(Coeus.Asset.Loader) {
	Formats = Coeus.Asset.Model.Formats:FullyLoad()
}

return ModelLoader