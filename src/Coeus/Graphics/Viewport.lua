local Coeus = (...)
local OOP = Coeus.Utility.OOP

local OpenGL = Coeus.Bindings.OpenGL
local gl = OpenGL.gl
local GL = OpenGL.GL

local Matrix4 = Coeus.Math.Matrix4

local Viewport = OOP:Class() {
	Window = false,

	X = 0,
	Y = 0,
	Width = 0,
	Height = 0,

	Projection = false
}

function Viewport:_new(x, y, width, height)
	self.X = x or self.X
	self.Y = y or self.Y
	self.Width = width or self.Width
	self.Height = height or self.Height

	self:RebuildProjection()
end

function Viewport:RebuildProjection()
	self.Projection = Matrix4.GetOrthographic(0, self.Width, 0, self.Height, -1.0, 1.0)
end	

function Viewport:Resize(width, height)
	self.Width = width
	self.Height = height
	self:RebuildProjection()
end

function Viewport:Use()
	gl.Viewport(self.X, self.Y, self.Width, self.Height)
end

return Viewport