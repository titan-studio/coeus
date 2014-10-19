local Coeus = (...)
local OOP = Coeus.Utility.OOP

local Table 		= Coeus.Utility.Table
local Event 		= Coeus.Utility.Event

local Matrix4 		= Coeus.Math.Matrix4
local Vector3 		= Coeus.Math.Vector3
local Quaternion 	= Coeus.Math.Quaternion

local BaseActor = OOP:Class() {
	scene = false,

	parent 		= false,
	children 	= {},

	local_transform 	= Matrix4:New(),
	render_transform 	= Matrix4:New(),
	dirty_transform 	= false,

	scale 	 = Vector3:New(1, 1, 1),
	position = Vector3:New(),
	rotation = Quaternion:New(),

	layer_flag = Coeus.Graphics.Layer.Flag.None,
	layer = false,

	Name = "Base Actor",
	DrawOrder = 1

	ChildAdded = Event:New(),
	ChildRemoved = Event:New()
}


function BaseActor:_new()

end

function BaseActor:SetScene(scene)
	self.scene = scene
	for i,v in pairs(self.children) do
		v:SetScene(scene)
	end
end

function BaseActor:SetupLayer()
	if self.layer then
		self.layer:DeregisterEntity(self)
	end

	local found = self.scene:GetLayersByFlag(self.layer_flag)
	if #found > 0 then
		self.layer = found[1]
		self.layer:RegisterEntity(self)
	end
end

function BaseActor:AddChild(child, dont_set_layer)
	for i,v in pairs(self.children) do
		if v == child then return end
	end
	self.children[#self.children+1] = child
	if child.parent then
		child.parent:RemoveChild(child)
	end
	child.parent = self
	child:SetScene(self.scene)

	if not dont_set_layer then
		child:SetupLayer()
	end

	self.ChildAdded:Fire(child)
end

function BaseActor:RemoveChild(child)
	for i,v in pairs(self.children) do
		if v == child then
			v.parent = false
			self.ChildRemoved:Fire(child)
			table.remove(self.children, i)
			return
		end
	end
end

function BaseActor:SetParent(parent)
	parent:AddChild(self)
end

function BaseActor:FindFirstChild(name, recursive)
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

function BaseActor:GetChildren()
	return Table.Copy(self.children)
end

function BaseActor:SetLocalTransform(matrix)
	self.local_transform = matrix:Copy()
	self:DirtyTransform()
end
function BaseActor:GetLocalTransform()
	self:BuildTransform()
	return self.local_transform:Copy()
end

function BaseActor:GetRenderTransform()
	self:BuildTransform()
	return self.render_transform:Copy()
end


function BaseActor:SetScale(x, y, z)
	if type(x) ~= "number" then
		self:SetScale(x.x, x.y, x.z)
		return
	end
	self.scale.x = x
	self.scale.y = y or x
	self.scale.z = z or x
	self:DirtyTransform()
end
function BaseActor:GetScale()
	return self.scale:Copy()
end

function BaseActor:SetPosition(x, y, z)
	if type(x) ~= "number" then
		self:SetPosition(x.x, x.y, x.z)
		return
	end
	self.position.x = x
	self.position.y = y
	self.position.z = z
	self:DirtyTransform()
end
function BaseActor:GetPosition()
	return self.position:Copy()
end

function BaseActor:SetRotation(x, y, z, w)
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
function BaseActor:GetRotation()
	return self.rotation:Copy()
end


function BaseActor:DirtyTransform()
	self.dirty_transform = true

	for i,v in pairs(self.children) do
		v:DirtyTransform()
	end
end

function BaseActor:BuildTransform()
	if not self.dirty_transform then return end
	self.dirty_transform = false

	self.local_transform = Matrix4.GetTranslation(self.position) *
						   self.rotation:ToRotationMatrix() *
						   Matrix4.GetScale(self.scale)
						   
	self.render_transform = self.local_transform-- * self.render_transform
end


function BaseActor:Update(dt)
	for i,v in pairs(self.children) do
		v:Update(dt)
	end
end

function BaseActor:Render()
	self:BuildTransform()
	
end


return BaseActor