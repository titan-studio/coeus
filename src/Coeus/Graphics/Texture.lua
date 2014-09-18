local ffi = require("ffi")
local Coeus			= (...)
local oop			= Coeus.Utility.OOP 

local ImageData 	= Coeus.Asset.Image.ImageData

local OpenGL		= Coeus.Bindings.OpenGL
local gl = OpenGL.gl
local GL = OpenGL.GL

local Texture = oop:Class() {
	context = false,
	unit = -1,
	handle = -1,

	filter_min = 1,
	filter_mag = 1,
	mipmapping = false,

	wrap_s = 0,
	wrap_t = 0,

	gl_target = GL.TEXTURE_2D
}

Texture.Filter = {
	Nearest		= 0,
	Linear		= 1
}
Texture.Wrap = {
	Wrap 	= 0,
	Clamp	= 1
}


function Texture:_new(image_data)
	local handle = ffi.new('unsigned int[1]')
	gl.GenTextures(1, handle)
	self.handle = handle[0]

	self:Bind()
	self:UpdateTextureParameters()
	self:SetData(image_data)
end

function Texture:UpdateTextureParameters()
	local filter_lookup = {
		[true] = {
			[Texture.Filter.Nearest] = GL.NEAREST_MIPMAP_NEAREST,
			[Texture.Filter.Linear] = GL.NEAREST_MIPMAP_LINEAR
		},
		[false] = {
			[Texture.Filter.Nearest] = GL.NEAREST,
			[Texture.Filter.Linear] = GL.LINEAR
		}
	}
	local min = filter_lookup[self.mipmapping][self.filter_min] or GL.NEAREST
	local mag = filter_lookup[self.mipmapping][self.filter_mag] or GL.NEAREST

	gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, min)
	gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, mag)

	if self.wrap_s == Texture.Wrap.Wrap then
		gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.REPEAT)
	else
		gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE)
	end
	if self.wrap_t == Texture.Wrap.Wrap then
		gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.REPEAT)
	else
		gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE)
	end
end

function Texture:SetData(image_data)
	local width = image_data.Width
	local height = image_data.Height
	local format_lookup = {
		[ImageData.Format.RGBA] = {
			internal 	= GL.RGBA,
			format 		= GL.RGBA,
			type		= GL.UNSIGNED_BYTE
		},
		[ImageData.Format.Depth] = {
			internal	= GL.DEPTH_COMPONENT,
			format 		= GL.DEPTH_COMPONENT,
			type		= GL.UNSIGNED_BYTE
		},
		[ImageData.Format.DepthStencil] = {
			internal	= GL.DEPTH32F_STENCIL8,
			format 		= GL.DEPTH_COMPONENT,
			type		= GL.UNSIGNED_BYTE
		},
		[ImageData.Format.Single] = {
			internal	= GL.R32F,
			format 		= GL.RED,
			type		= GL.UNSIGNED_BYTE
		}
	}
	local format = format_lookup[image_data.format]
	local dat = nil

	if image_data.image then
		dat = image_data.image
	end
	gl.TexImage2D(GL.TEXTURE_2D, 0, format.internal, width, height, 0, format.format, format.type, dat)
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