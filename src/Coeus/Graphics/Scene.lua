local Coeus 		= (...)
local OOP			= Coeus.Utility.OOP

local Layer = Coeus.Graphics.Layer

local Scene = OOP:Class() {
	context = false,
	active = false,

	layers = {},
	Actors = {},

	Viewport = false
}
Scene.DefaultLayers = {
	Layer.Flag.Geometry,
	Layer.Flag.TransparentGeometry,
	Layer.Flag.Lights,
	Layer.Flag.Unlit2D
}

function Scene:_new(context, layer_types)
	self.context = context
	self.Viewport = self.context.Window.MainViewport

	layer_types = layer_types or Scene.DefaultLayers
	for i, v in ipairs(layer_types) do
		table.insert(self.layers, Layer:New(self, v))
	end
end

function Scene:Update(dt)
	for i, v in ipairs(self.Actors) do
		v:Update(dt)
	end
end

function Scene:RenderLayers(flag)
	if self.Viewport then
		self.Viewport:Use()
	end
	for i, v in ipairs(self.layers) do
		if v.flag == flag then
			v:Render()
		end
	end
end

function Scene:GetLayersByName(name)
	local out = {}
	for i, v in ipairs(self.layers) do
		if v.name == name then
			table.insert(out, v)
		end
	end
	return out
end

function Scene:GetLayersByFlag(flag)
	local out = {}
	for i, v in ipairs(self.layers) do
		if v.flag == flag then
			table.insert(out, v)
		end
	end
	return out
end

return Scene