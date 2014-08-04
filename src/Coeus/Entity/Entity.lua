local Coeus 		= (...)
local oop 			= Coeus.Utility.OOP 
local Table 		= Coeus.Utility.Table

local Matrix4 		= Coeus.Math.Matrix4
local Vector3 		= Coeus.Math.Vector3
local Quaternion 	= Coeus.Math.Quaternion

local Event 		= Coeus.Utility.Event

local Entity = oop:Class() {
	scene = false,

	parent 		= false,
	children 	= {},

	local_transform 	= Matrix4:New(),
	render_transform 	= Matrix4:New(),
	dirty_transform 	= false,

	scale 	 = Vector3:New(1, 1, 1),
	position = Vector3:New(),
	rotation = Quaternion:New(),

	components = {},

	name = "Entity",

}

function Entity:_new()

end

function Entity:SetName(name)
	self.name = name
end
function Entity:GetName()
	return self.name
end


function Entity:SetScene(scene)
	self.scene = scene
	for i,v in pairs(self.children) do
		v:SetScene(scene)
	end
end


function Entity:AddChild(child)
	for i,v in pairs(self.children) do
		if v == child then return end
	end
	self.children[#self.children+1] = child
	if child.parent then
		child.parent:RemoveChild(child)
	end
	child.parent = self
	child:SetScene(self.scene)
end

function Entity:RemoveChild(child)
	for i,v in pairs(self.children) do
		if v == child then
			v.parent = false
			table.remove(self.children, i)
			return
		end
	end
end

function Entity:SetParent(parent)
	parent:AddChild(self)
end

function Entity:FindFirstChild(name, recursive)
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

function Entity:GetChildren()
	return Table.Copy(self.children)
end


function Entity:AddComponent(component)
	if self.components[component:GetClass()] then return end
	self.components[component:GetClass()] = component
	component.entity = self
end

function Entity:RemoveComponent(component)
	local comp = self.components[component:GetClass()]
	if comp then
		comp.entity = false
		self.components[component:GetClass()] = nil
	end
end

function Entity:GetComponent(component_type)
	return self.components[component_type]
end


function Entity:SetLocalTransform(matrix)
	self.local_transform = matrix:Copy()
	self:DirtyTransform()
end
function Entity:GetLocalTransform()
	self:BuildTransform()
	return self.local_transform:Copy()
end

function Entity:GetRenderTransform()
	self:BuildTransform()
	return self.render_transform:Copy()
end


function Entity:SetScale(x, y, z)
	if type(x) ~= "number" then
		self:SetScale(x.x, x.y, x.z)
		return
	end
	self.scale.x = x
	self.scale.y = y or x
	self.scale.z = z or x
	self:DirtyTransform()
end
function Entity:GetScale()
	return self.scale:Copy()
end

function Entity:SetPosition(x, y, z)
	if self.name ~="Entity" then
	print(self.name, x, y, z)
end
	if type(x) ~= "number" then
		self:SetPosition(x.x, x.y, x.z)
		return
	end
	self.position.x = x
	self.position.y = y
	self.position.z = z
	self:DirtyTransform()
end
function Entity:GetPosition()
	return self.position:Copy()
end

function Entity:SetRotation(x, y, z, w)
	if type(x) ~= "number" then
		self:SetRotation(x.x, x.y, x.z, x.w)
		return
	end
	self.rotation.x = x
	self.rotation.y = y
	self.rotation.z = z
	self.rotation.w = w
	self:DirtyTransform()
end
function Entity:GetRotation()
	return self.rotation:Copy()
end


function Entity:DirtyTransform()
	self.dirty_transform = true

	for i,v in pairs(self.children) do
		v:DirtyTransform()
	end
end

function Entity:BuildTransform()
	if not self.dirty_transform then return end
	self.dirty_transform = false

	self.local_transform = Matrix4.GetScale(self.scale) * 
						   Matrix4.GetTranslation(self.position) *
						   self.rotation:ToRotationMatrix() 
						   
	self.render_transform = self.local_transform-- * self.render_transform
end


function Entity:Update(dt)
	for i,v in pairs(self.components) do
		v:Update(dt)
	end
	for i,v in pairs(self.children) do
		v:Update(dt)
	end
end

function Entity:Render()
	self:BuildTransform()
	for i,v in pairs(self.components) do
		v:Render()
	end
	for i,v in pairs(self.children) do 
		v:Render()
	end
end

return Entity