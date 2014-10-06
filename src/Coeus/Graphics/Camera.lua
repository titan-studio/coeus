local Coeus 	= (...)
local OOP 		= Coeus.Utility.OOP 

local BaseComponent = Coeus.Entity.BaseComponent
local Matrix4		= Coeus.Math.Matrix4

local Camera = OOP:Class(BaseComponent) {
	fov = 60,
	near = 0.5,
	far = 1000,

	projection_type = 0,
	projection = false,
	projection_dirty = true,

	window = false
}
Camera.ProjectionType = {
	Orthographic 	= 1,
	Perspective 	= 2
}

function Camera:_new(window)
	self.window = window
	self.window.Resized:Listen(function()
		self.projection_dirty = true
	end)	

	self.projection_type = Camera.ProjectionType.Perspective
	self:BuildProjectionTransform()
end

function Camera:SetFieldOfView(degrees)
	self.fov = degrees
	self.projection_dirty = true
end	
function Camera:GetFieldOfView()
	return self.fov
end

function Camera:SetRenderDistances(near, far)
	self.near = near
	self.far = far
	self.projection_dirty = true
end
function Camera:GetRenderDistances()
	return self.near, self.far
end


function Camera:GetViewTransform()
	local entity = self.entity
	if entity then
		return entity:GetRenderTransform():GetInverse()
	end
	return Matrix4:New()
end

function Camera:BuildProjectionTransform()
	if not self.projection_dirty then return end
	self.projection_dirty = false

	if self.projection_type == Camera.ProjectionType.Perspective then
		local fov = self.fov
		local width, height = self.window:GetSize()
		local near, far = self.near, self.far
		local aspect = width / height
		self.projection = Matrix4.GetPerspective(fov, near, far, aspect)
	end
end

function Camera:GetProjectionTransform()
	self:BuildProjectionTransform()
	return self.projection
end

function Camera:GetViewProjection()
	local view = self:GetViewTransform()
	local proj = self:GetProjectionTransform()

	return proj * view
end

return Camera