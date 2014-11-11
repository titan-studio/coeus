local Coeus = (...)
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

	OnUpdate = false
}

function Actor:_new(scene)
	self.Scene = scene
	table.insert(self.Scene.Actors, self)
end

function Actor:AddComponent(component)
	self.Components[component.ClassName] = component
	component.Actor = self
	component.AddedToActor:Fire(self)
end

function Actor:GetComponent(classname)
	return self.Components[classname]
end

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

function Actor:SetParent(parent)
	parent:AddChild(self)
end

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

function Actor:GetChildren()
	return Table.Copy(self.children)
end


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