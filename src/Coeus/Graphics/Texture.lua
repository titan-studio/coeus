local ffi = require("ffi")
local Coeus			= (...)
local oop			= Coeus.Utility.OOP 

local OpenGL		= Coeus.Bindings.OpenGL
local gl = OpenGL.gl
local GL = OpenGL.GL

local Texture = oop:Class() {
	context = false,
	unit = -1,
	handle = -1,

	gl_target = GL.TEXTURE_2D
}

function Texture:_new(width, height, repeating)
	local handle = ffi.new('unsigned int[1]')
	gl.GenTextures(1, handle)
	self.handle = handle[0]

	self:Bind()
	gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR)
	gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR)
	if repeating or repeating == nil then
		--gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.WRAP)
		--gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.WRAP)
	else
		gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE)
		gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE)
	end

	if width ~= nil and height ~= nil then
		gl.TexImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, nil)
	end
end

function Texture:Destroy()
	local handle = ffi.new('unsigned int[1]')
	handle[0] = self.handle
	gl.DeleteTextures(1, handle)
end

function Texture:Bind(unit)
	if unit then
		self.unit = unit
		gl.ActiveTexture(unit)
	end
	gl.BindTexture(self.gl_target, self.handle)
end

function Texture:Unbind()
	gl.ActiveTexture(self.unit)
	gl.BindTexture(self.gl_target, 0)
	self.unit = -1
end

return Texture