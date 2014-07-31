local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local BaseComponent	= Coeus.Entity.BaseComponent
local Material 		= Coeus.Graphics.Material

local MeshRenderer = OOP:Class(BaseComponent) {
	GraphicsContext = false,
	Mesh = false,
}

function MeshRenderer:_new(ctx)
	self.GraphicsContext = ctx
end

function MeshRenderer:Render()
	local material = self.entity:GetComponent(Material)
	if material and self.Mesh then
		material:Use()
		
		self.Mesh:Render()
	end
end

return MeshRenderer