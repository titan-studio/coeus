local C = (...)
local Coeus = C:Get("Coeus")
local OOP = Coeus.Utility.OOP
local Table = Coeus.Utility.Table

local Actor = Coeus.World.Actor

local ModelData = Coeus.Asset.Model.ModelData

local Model = OOP:Class(Actor) {
	Meshes = {},
	Materials = {},
	Joints = {},
	Animations = {},
}

function Model:_new(scene, data)
	Actor._new(self, scene)
	for i, v in ipairs(data.Meshes) do
		local mesh = Mesh:New()
		mesh:SetData(v)

		table.insert(self.Meshes, mesh)
	end

	self.Materials = Table.Copy(data.Materials)
	self.Joints = Table.Copy(data.Joints)
	self.Animations = Table.Copy(data.Animations)

	local root_trans = Coeus.World.Component.Transform:New()
	self:AddComponent(root_trans)

	for i, v in ipairs(self.Meshes) do
		local child = Actor:New(scene)
		child:SetParent(self)
		local child_trans = Coeus.World.Component.Transform:New()

	end
end

return Model