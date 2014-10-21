local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local MeshData = OOP:Class() {
	Name = "Mesh",
	Vertices = {},
	Indices = false,

	SmoothingGroup = -1,
	SmoothingAngle = math.rad(180),
	SmoothByUv = false,

	Format = {
		Positions 		= true,
		TexCoords 		= false,
		Normals			= false,
		Tangents		= false,
		BoneIDs		 	= false,
		BoneWeights		= false,
		Color			= false
	}
}
MeshData.DefaultLocations = {
	[1] = "Positions",
	[2] = "TexCoords",
	[3] = "Normals",
	[4] = "Tangents",
	[5] = "BoneIDs",
	[6] = "BoneWeights",
	[7] = "Color"
}
MeshData.FormatSize = {
	Positions		= 3,
	TexCoords		= 2,
	Normals			= 3,
	Tangents		= 3,
	BoneIDs			= 4,
	BoneWeights		= 4,
	Color			= 4
}
MeshData.FormatType = {
	Positions 		= "float",
	TexCoords		= "float",
	Normals			= "float",
	Tangents		= "float",
	BoneIDs 		= "integer",
	BoneWeights		= "float",
	Color 			= "float"
}

function MeshData.CalculateVertexStride(format)
	local stride = 0
	for i, v in pairs(format) do
		if v then
			stride = stride + (MeshData.FormatSize[i] or 0)
		end
	end
	return stride
end

return MeshData