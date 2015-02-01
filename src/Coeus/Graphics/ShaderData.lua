local Coeus = (...)
local OOP = Coeus.Utility.OOP
local Data = Coeus.Asset.Data

local ShaderData = OOP:Class()
	:Members {
		VertexCode = false,
		FragmentCode = false,
		ComputeCode = false,
		GeometryCode = false,

		Type = 0
	}
}
ShaderData.ShaderType = {
	Invalid = 0,
	VertexFragment = 1,
	VertexFragmentGeometry = 2,
	Compute = 3,
}

function ShaderData:_new(shader_type, data)
	self.Type = shader_type

	for i, v in pairs(data) do
		if (self[i] ~= nil) then
			self[i] = v
		end
	end
end

return ShaderData