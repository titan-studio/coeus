local Coeus 	= (...)
local OOP		= Coeus.Utility.OOP
local Table		= Coeus.Utility.Table

local ModelData = Coeus.Asset.Model.ModelData

local Model = OOP:Class() {
	Meshes = {},
	Materials = {},
	Joints = {},
	Animations = {},
}

function Model:_new(data)
	for i, v in ipairs(data.Meshes) do
		local mesh = Mesh:New()
		mesh:SetData(v)

		table.insert(self.Meshes, mesh)
	end

	self.Materials = Table.Copy(data.Materials)
	self.Joints = Table.Copy(data.Joints)
	self.Animations = Table.Copy(data.Animations)
end

return Model