local Coeus = (...)
local OOP = Coeus.Utility.OOP

local BaseComponent = Coeus.World.Component.BaseComponent
local Matrix4 = Coeus.Math.Matrix4
local Vector2 = Coeus.Math.Vector2

local Transform2D = OOP:Class(BaseComponent) {
	Name = "Transform2D",
	local_transform = Matrix4:New(),
	render_transform = Matrix4:New(),
	dirty_transform = false,

	scale = Vector2:New(1, 1),
	position = Vector2:New(0, 0),
	rotation = 0,
	offset = Vector2:New(0, 0),
}

function Transform2D:_new(position, rotation, scale, offset)
	self.position = position or self.position
	self.rotation = rotation or self.rotation
	self.scale = scale or self.scale
	self.offset = offset or self.offset
end

function Transform2D:SetLocalTransform(matrix)
	self.local_transform = matrix:Copy()
	self:DirtyTransform()
end
function Transform2D:GetLocalTransform()
	self:BuildTransform()
	return self.local_transform:Copy()
end

function Transform2D:GetRenderTransform()
	self:BuildTransform()
	return self.render_transform:Copy()
end

function Transform2D:SetScale(x, y)
	if type(x) ~= "number" then
		self:SetScale(x.x, x.y)
		return
	end
	self.scale.x = x
	self.scale.y = y or x
	self:DirtyTransform()
end
function Transform2D:GetScale()
	return self.scale:Copy()
end

function Transform2D:SetPosition(x, y)
	if type(x) ~= "number" then
		self:SetPosition(x.x, x.y)
		return
	end
	self.position.x = x
	self.position.y = y
	self:DirtyTransform()
end
function Transform2D:GetPosition()
	return self.position:Copy()
end

function Transform2D:SetRotation(theta)
	self.rotation = theta
	self:DirtyTransform()
end

function Transform2D:DirtyTransform()
	self.dirty_transform = true

	for i, v in pairs(self.Actor.children) do
		local comp = v.Components.Transform2D
		if comp then
			comp:DirtyTransform()
		end
	end
end

function Transform2D:BuildTransform()
	if not self.dirty_transform then
		return
	end
	self.dirty_transform = false

	self.local_transform = Matrix4.GetTranslation(self.position:XYZ()) * 
						   Matrix4.GetRotationZ(self.rotation) *
						   Matrix4.GetTranslation((-self.offset):XYZ()) *
						   Matrix4.GetScale(self.scale:XYZ(1))
						   Matrix4:New()
	self.render_transform = self.local_transform

	if self.Actor.Parent then
		local comp = self.Actor.Parent.Components.Transform2D
		if comp then
			comp:BuildTransform()
			self.render_transform = self.local_transform * comp.render_transform
		end
	end
end

return Transform2D