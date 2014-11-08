local Coeus = (...)
local OOP = Coeus.Utility.OOP

local BaseComponent = Coeus.World.Component.BaseComponent

local QuadRenderer = OOP:Class(BaseComponent) {
	Name = "QuadRenderer",
	RenderLayerFlag = Coeus.Graphics.Layer.Flag.Unlit2D,

	Image = false,
	Color = {1, 1, 1, 1}
}

function QuadRenderer:_new()

end

function QuadRenderer:Render()
	if not self.Actor and not self.Actor.Scene then
		return 
	end
	local graphics = self.Actor.Scene.context
	local transform = self.Actor.Components.Transform2D
	if not transform then
		return
	end
	local render_trans = transform:GetRenderTransform()
	local model_projection = graphics.ScreenProjection * render_trans

	local tex = self.Image
	if not self.Image then
		tex = graphics.IdentityTexture
	end

	graphics.Shaders.Render2D:Use()
	graphics.Shaders.Render2D:Send("DiffuseColor", self.Color)
	graphics.Shaders.Render2D:Send("ModelProjection", model_projection)
	graphics.Shaders.Render2D:Send("Texture", tex)
	graphics.IdentityQuad:Render()
end

return QuadRenderer