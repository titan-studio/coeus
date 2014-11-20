local Coeus 	= (...)
local OOP 		= Coeus.Utility.OOP 

local BaseComponent	= Coeus.World.Component.BaseComponent
local Matrix4		= Coeus.Math.Matrix4

local Camera = OOP:Class(BaseComponent) {
	ClassName = "Camera",

	fov = 60,
	near = 0.5,
	far = 1000,

	projection = false,
	projection_dirty = true,

	window = false
}

function Camera:_new()
	local resized = nil
	self.AddedToActor:Listen(function(actor)
		self.window = actor.Scene.context.Window

		if resized then
			resized:Disconnect()
		end
		resized = self.window.Resized:Listen(function()
			self.projection_dirty = true
		end)	

		self:BuildProjectionTransform()
	end)
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
	local actor = self.Actor
	if actor then
		local transform = actor.Components.Transform
		if transform then
			return transform:GetRenderTransform():Inverse()
		end
	end
	return Matrix4:Identity()
end

function Camera:BuildProjectionTransform()
	if not self.projection_dirty then return end
	self.projection_dirty = false

	local fov = self.fov
	local width, height = self.window:GetSize()
	local near, far = self.near, self.far
	local aspect = width / height
	self.projection = Matrix4.GetPerspective(fov, near, far, aspect)
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