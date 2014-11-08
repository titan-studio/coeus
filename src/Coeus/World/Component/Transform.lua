local Coeus = (...)
local OOP = Coeus.Utility.OOP

local BaseComponent = Coeus.Actor.Component.BaseComponent

local Transform = OOP:Class(BaseComponent) {
	local_transform 	= Matrix4:New(),
	render_transform 	= Matrix4:New(),
	dirty_transform 	= false,

	scale 	 = Vector3:New(1, 1, 1),
	position = Vector3:New(),
	rotation = Quaternion:New(),

	Scene = false
}

function Transform:SetLocalTransform(matrix)
	self.local_transform = matrix:Copy()
	self:DirtyTransform()
end
function Transform:GetLocalTransform()
	self:BuildTransform()
	return self.local_transform:Copy()
end

function Transform:GetRenderTransform()
	self:BuildTransform()
	return self.render_transform:Copy()
end

function Transform:SetScene(scene)
	self.scene = scene
	for i,v in pairs(self.children) do
		v:SetScene(scene)
	end
end

function Transform:SetScale(x, y, z)
	if type(x) ~= "number" then
		self:SetScale(x.x, x.y, x.z)
		return
	end
	self.scale.x = x
	self.scale.y = y or x
	self.scale.z = z or x
	self:DirtyTransform()
end
function Transform:GetScale()
	return self.scale:Copy()
end

function Transform:SetPosition(x, y, z)
	if type(x) ~= "number" then
		self:SetPosition(x.x, x.y, x.z)
		return
	end
	self.position.x = x
	self.position.y = y
	self.position.z = z
	self:DirtyTransform()
end
function Transform:GetPosition()
	return self.position:Copy()
end

function Transform:SetRotation(x, y, z, w)
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
function Transform:GetRotation()
	return self.rotation:Copy()
end


function Transform:DirtyTransform()
	self.dirty_transform = true

	for i, v in pairs(self.Actor.children) do
		local comp = v:GetComponent(Transform)
		if comp then
			comp:DirtyTransform()
		end
	end
end

function Transform:BuildTransform()
	if not self.dirty_transform then return end
	self.dirty_transform = false

	self.local_transform = Matrix4.GetTranslation(self.position) *
						   self.rotation:ToRotationMatrix() *
						   Matrix4.GetScale(self.scale)

	self.render_transform = self.local_transform

	if self.Actor.Parent then
		local comp = self.Actor.Parent:GetComponent(Transform)
		if comp then
			comp:BuildTransform()
			self.render_transform = self.local_transform * comp.render_transform
		end
	end
end


return Transform