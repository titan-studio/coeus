local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local BaseComponent	= Coeus.World.Component.BaseComponent

local Material = OOP:Class(BaseComponent) {
	ClassName = "Material",
	Shader = false,

	Textures = {}
}

function Material:_new()

end

function Material:Use()
	if not self.Actor or not self.Actor.Scene or not self.Actor.Scene.ActiveCamera then
		return
	end
	local graphics = self.Actor.Scene.context
	local transform = self.Actor.Components.Transform
	if not transform then
		return
	end

	self.Shader:Use()
	for i, v in pairs(self.Textures) do
		if v.Is[Texture] then
			self.Shader:Send(i, v)
		end
	end

	local camera = self.Actor.Scene.ActiveCamera
	local model = transform:GetRenderTransform()
	local view_projection = camera:GetViewProjection()
	local mvp = view_projection * model
	
	self.Shader:Send("ModelColor", {1, 1, 1, 1.0})
	self.Shader:Send("ModelViewProjection", mvp)
	self.Shader:Send("Model", model)
	self.Shader:Send("ZNear", camera.near)
	self.Shader:Send("ZFar", camera.far)
end

return Material