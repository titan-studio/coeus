--[[
	Model Data

	Defines data for models
]]

local Coeus	= (...)
local OOP = Coeus.Utility.OOP

local ModelData = OOP:Class() {
	Type = 0,
	Meshes = {},
	Materials = {},
	Joints = {},
	Animations = {},

	TriangleCount = 0,
	VertexCount = 0,

	Type = {
		Static = 0,
		Skeletal = 1
	}
}

return ModelData