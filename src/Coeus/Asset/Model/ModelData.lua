local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local ModelData = OOP:Class() {
	Type = 0,
	Meshes = {},
	Materials = {},
	Joints = {},
	Animations = {}
}
ModelData.Type = {
	Static		= 0,
	Skeletal	= 1
}

return ModelData