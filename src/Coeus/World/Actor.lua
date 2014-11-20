local C = (...)
local Coeus = C:Get("Coeus")
local OOP = Coeus.Utility.OOP

local Table 		= Coeus.Utility.Table
local Event 		= Coeus.Utility.Event

local Scene = Coeus.Graphics.Scene

local Matrix4 		= Coeus.Math.Matrix4
local Vector3 		= Coeus.Math.Vector3
local Quaternion 	= Coeus.Math.Quaternion

local Actor = OOP:Class() {
	ClassName = "Actor",
	Scene = false,
	Parent = false,
	children = {},

	Components = {},

	layer_flag = Coeus.Graphics.Layer.Flag.None,
	layer = false,

	Name = "Unnamed Actor",
	DrawOrder = 1,

	ChildAdded = Event:New(),
	ChildRemoved = Event:New(),
	AddedToScene = Event:New(),
	RemovedFromScene = Event:New(),

	OnUpdate = false
}

--[[
	Creates a new Actor
	scene is optional, but if supplied, the Actor will add itself to the top 
	level of the scene.
]]
function Actor:_new(scene)
	if scene then
		scene:AddActor(self)
	end
end

--[[
	Adds a component to the Actor and fires its AddedToActor event
]]
function Actor:AddComponent(component)
	self.Components[component.ClassName] = component
	component.Actor = self
	component.AddedToActor:Fire(self)
end

--[[
	Returns a component with the type matching the classname argument.

	Deprecated; access Actor.Components directly.
]]
function Actor:GetComponent(classname)
	return self.Components[classname]
end

--[[
	Adds an actor to this actor's children list and handles its Parent reference.
	Fires this actor's ChildAdded event.
]]
function Actor:AddChild(child)
	for i,v in pairs(self.children) do
		if v == child then return end
	end
	self.children[#self.children+1] = child
	if child.Parent then
		child.Parent:RemoveChild(child)
	end
	child.Parent = self

	self.ChildAdded:Fire(child)
end

--[[
	Removes a child from this actor's hierarchy.
	Fires this actor's ChildRemoved event.
]]
function Actor:RemoveChild(child)
	for i,v in pairs(self.children) do
		if v == child then
			v.Parent = false
			self.ChildRemoved:Fire(child)
			table.remove(self.children, i)
			return
		end
	end
end

--[[
	Simply an alias of parent:AddChild(actor).

	Deprecated; use parent:AddChild(actor) directly.
]]
function Actor:SetParent(parent)
	parent:AddChild(self)
end

--[[
	Searches this actor's children for a named actor. Can
	also do a recursive search, which will find any named matching
	actor in the entire tree. Use sparingly.
]]
function Actor:FindFirstChild(name, recursive)
	for i,v in pairs(self.children) do
		if v.name == name then
			return v
		end
		if recursive then
			v:FindFirstChild(name, true)
		end
	end
	return nil
end

--[[
	Returns a mutable copy of this actor's children table.
]]
function Actor:GetChildren()
	return Table.Copy(self.children)
end

--[[
	The core Update method of the Actor class. If overriden,
	the overriding method should call Actor.Update(self, dt)
	at some point.

	Using the actor's empty OnUpdate method is for external
	code that would like to attach logic to the specific actor.
	Overriding should be used for class-level logic.
]]
function Actor:Update(dt)
	if self.OnUpdate then
		self:OnUpdate(dt)
	end

	for i, v in pairs(self.children) do
		v:Update(dt)
	end

	for i, v in pairs(self.Components) do
		if v.ShouldUpdate then
			v:Update(dt)
		end
	end
end

--[[
	Handles rendering components. Should not be overridden
	or called directly - use components to render things because
	they respect layer flags.
]]
function Actor:Render(layer_flag)
	for i, v in pairs(self.Components) do
		if v.RenderLayerFlag == layer_flag then
			v:Render()
		end
	end

	for i, v in ipairs(self.children) do
		v:Render(layer_flag)
	end
end

return Actor