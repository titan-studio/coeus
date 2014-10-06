local Coeus 		= (...)
local OOP			= Coeus.Utility.OOP

local Scene = OOP:Class() {
	context = false,
	active = false,

	entities = {},
	layers = {}
}
Scene.DefaultLayers = {
	Geometry,
	TransparentGeometry,
	Lights,
	Unlit2D
}

function Scene:_new(context, layer_types)
	self.context = context

	layer_types = layer_types or Scene.DefaultLayers
	for i, v in ipairs(layer_types) do
		table.insert(self.layers, Coeus.Graphics.Layer:New(context, v))
	end
end

function Scene:AddEntity(entity)
	for i, v in pairs(self.entities) do
		if v == entity then
			return
		end
	end
	table.insert(self.entities, entity)
	if entity.scene then
		entity.scene:RemoveEntity(entity)
	end
	entity:SetScene(self)

	--Find the first matching layer to put an entity component into
	for i, component in ipairs(entity.components) do
		for j, layer in ipairs(self.layers) do
			if layer.flag == component.layer_flag then
				layer:RegisterComponent(component)
				break
			end
		end
	end
end

function Scene:RemoveEntity(entity)
	for i, v in pairs(self.entities) do
		if v == entity then
			table.remove(self.entities, i)
			return
		end
	end
end

function Scene:Update(dt)
	for i, v in ipairs(self.entities) do
		v:Update(dt)
	end
end

function Scene:RenderLayers(flag)
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