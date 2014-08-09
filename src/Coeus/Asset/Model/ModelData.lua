local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local ModelData = OOP:Class() {
	Meshes = {},
}
ModelData.Type = {
	Static		= 0,
	Skeletal	= 1
}

return ModelData