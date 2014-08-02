local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local Mesh			= Coeus.Graphics.Mesh

local PlaneMesh = OOP:Class(Mesh) {
	
}

function PlaneMesh:_new(x_scale, y_scale, tex_x, tex_y)
	Mesh._new(self)

	local x = x_scale or 1
	local y = y_scale or 1
	local tx = tex_x or 1
	local ty = tex_y or 1

	local vertices = {
		-0.5 * x, 0, -0.5 * y, 		0.0 * tx, 0.0 * ty, 	0.0, 1.0, 0.0,
		 0.5 * x, 0, -0.5 * y, 		1.0 * tx, 0.0 * ty, 	0.0, 1.0, 0.0,
		-0.5 * x, 0,  0.5 * y, 		0.0 * tx, 1.0 * ty, 	0.0, 1.0, 0.0,
		 0.5 * x, 0,  0.5 * y, 		1.0 * tx, 1.0 * ty, 	0.0, 1.0, 0.0
	}		

	local indices = {
		2, 1, 0,
		3, 1, 2
	}

	self:SetData(vertices, indices, Mesh.DataFormat.PositionTexCoordNormalInterleaved)
end

return PlaneMesh