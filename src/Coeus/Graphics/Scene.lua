local C = (...)
local Coeus = C:Get("Coeus")
local OOP = Coeus.Utility.OOP

local Layer = Coeus.Graphics.Layer

local Scene = OOP:Class() {
	context = false,
	active = false,

	layers = {},
	Actors = {},

	Viewport = false,
	ActiveCamera = false,

	Name = "Unnamed Scene",
}
Scene.DefaultLayers = {
	Layer.Flag.Geometry,
	Layer.Flag.TransparentGeometry,
	Layer.Flag.Lights,
	Layer.Flag.Unlit2D
}
Scene.DefaultLayers2D = {
	Layer.Flag.Unlit2D
}

--[[
	Creates a new Scene.
	context should be something like window.Graphics, a GraphicsContext object.
	layer_types can be left out. If supplied, it should be an ordered table of Layer.Flag
	constants. This will initialize the Scene with corresponding Layer objects.

	By default, Scenes will initialize themselves with the contents of the Scene.DefaultLayers
	table, which canonically contains the following:

		Geometry
		TransparentGeometry
		Lights
		Unlit2D

	This table may be modified by the user application and all future Scenes will
	use the updated contents.

	Scenes are attached to a GraphicsContext and should not be transferred.

]]
function Scene:_new(context, layer_types)
	self.context = context
	self.Viewport = self.context.Window.MainViewport

	layer_types = layer_types or Scene.DefaultLayers
	for i, v in ipairs(layer_types) do
		table.insert(self.layers, Layer:New(self, v))
	end
end

--[[
	Adds an Actor to the top level of the scene. This means the actor will get Update
	and Render calls and will appear in the world with the appropriate components.
	Fires the actor's AddedToScene event.

	If the actor already exists in the Scene, a warning will be raised.
]]
function Scene:AddActor(actor)
	for i, v in ipairs(self.Actors) do
		if (v == actor) then
			return C:Warning(
				"Actor (" .. actor.Name .. ") already exists in scene (" .. self.Name .. ")!",
				"Scene.AddActor"
			)
		end
	end

	actor.Scene = self
	table.insert(self.Actors, actor)
	actor.AddedToScene:Fire(scene)
end

--[[
	Removes an actor from the top level of the scene. This means the actor will no longer
	get Update or Render calls and won't appear in the world anymore.
	Fires the actor's RemovedFromScene event.

	If the actor does not exist in the Scene, a warning will be raised.
]]
function Scene:RemoveActor(actor)
	for i, v in ipairs(self.Actors) do
		if (v == actor) then
			table.remove(self.Actors, i)
			actor.Scene = false
			actor.RemovedFromScene:Fire(self)

			return
		end
	end

	return C:Warning(
		"Actor (" .. actor.Name ..") does not exist in the scene (" .. self.Name .. ")!", 
		"Scene.RemoveActor"
	)
end

--[[
	Passes the Update call to all Actors in the scene.
]]
function Scene:Update(dt)
	for i, v in ipairs(self.Actors) do
		v:Update(dt)
	end
end

--[[
	Renders all layers with a matching flag.
	flag must be a constant from Layer.Flag.
]]
function Scene:RenderLayers(flag)
	if (self.Viewport) then
		self.Viewport:Use()
	end

	for i, v in ipairs(self.layers) do
		if (v.flag == flag) then
			v:Render()
		end
	end
end

--[[
	Returns a mutable table of named Layers with matching names.
	name must be a string.
]]
function Scene:GetLayersByName(name)
	local out = {}
	for i, v in ipairs(self.layers) do
		if (v.Name == name) then
			table.insert(out, v)
		end
	end
	return out
end

--[[
	Returns a mutable table of flagged Layers with matching flags.
	flag must be a constant from Layer.Flag.
]]
function Scene:GetLayersByFlag(flag)
	local out = {}
	for i, v in ipairs(self.layers) do
		if v.flag == flag then
			table.insert(out, v)
		end
	end
	return out
end

--[[
	Returns a single Layer with a name matching the name argument.
	name must be a string or a constant from Layer.Flag.

	If name is actually a flag, it will return the first Layer with
	a matching flag.
]]
function Scene:FindFirstLayer(name)
	for i, v in ipairs(self.layers) do
		if (v.Name == name) then
			return v
		end
		if (v.flag == name) then
			return v
		end
	end
end

return Scene