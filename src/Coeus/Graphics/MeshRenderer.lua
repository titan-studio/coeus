local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local BaseComponent	= Coeus.Entity.BaseComponent

local MeshRenderer = OOP:Class(BaseComponent) {
	GraphicsContext = false,
	Mesh = false,
	Shader = false,
}

function MeshRenderer:_new(ctx)
	self.GraphicsContext = ctx
end

function MeshRenderer:Render()
	local camera = self.GraphicsContext.ActiveCamera
	local model = self.entity:GetRenderTransform()
	local view_projection = camera:GetViewProjection()

	local mvp = view_projection * model

	if self.Shader and self.Mesh then
		self.Shader:Send("ModelViewProjection", mvp)
		self.Mesh:Render()
	end
end

return MeshRenderer