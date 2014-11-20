local C = (...)
local Coeus = C:Get("Coeus")
local OOP = Coeus.Utility.OOP

local BaseComponent = Coeus.World.Component.BaseComponent
local Material = Coeus.Graphics.Material

local MeshRenderer = OOP:Class(BaseComponent) {
	ClassName = "MeshRenderer",
	RenderLayerFlag = Coeus.Graphics.Layer.Flag.Geometry,
	Mesh = false,
}

function MeshRenderer:_new()

end

function MeshRenderer:Render()
	local material = self.Actor.Components.Material
	if material and self.Mesh then
		material:Use()
		
		self.Mesh:Render()
	end
end

return MeshRenderer