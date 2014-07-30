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

function Texture:_new()
	local handle = ffi.new('unsigned int[1]')
	gl.GenTextures(1, handle)
	self.handle = handle[0]
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
	gl.BindTexture(GL.TEXTURE_2D, self.handle)
end

function Texture:Unbind()
	gl.ActiveTexture(self.unit)
	gl.BindTexture(self.gl_target, 0)
	self.unit = -1
end	

return Texture