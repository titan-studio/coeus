local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local BaseComponent	= Coeus.Entity.BaseComponent

local Material = OOP:Class(BaseComponent) {
	GraphicsContext = false,
	Shader = false,

	Textures = {}
}

function Material:_new(ctx)
	self.GraphicsContext = ctx
end

function Material:Use()
	self.Shader:Use()
	for i, v in pairs(self.Textures) do
		if v.GetClass and v:GetClass(Texture) then
			self.Shader:Send(i, v)
		end
	end

	local camera = self.GraphicsContext.ActiveCamera
	local model = self.entity:GetRenderTransform()
	local view_projection = camera:GetViewProjection()
	local mvp = view_projection * model
	
	self.Shader:Send("ModelViewProjection", mvp)
	self.Shader:Send("Model", model)
	self.Shader:Send("ZNear", camera.near)
	self.Shader:Send("ZFar", camera.far)
end

return Material