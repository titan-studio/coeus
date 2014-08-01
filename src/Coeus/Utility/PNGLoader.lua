local ffi = require("ffi")
local Coeus			= (...)
local OOP			= Coeus.Utility.OOP
local lodepng		= Coeus.Bindings.lodepng
local Texture 		= Coeus.Graphics.Texture

local OpenGL = Coeus.Bindings.OpenGL
local gl = OpenGL.gl
local GL = OpenGL.GL

local PNGLoader = OOP:Class() {
	texture = false
}

function PNGLoader:_new(filename)
	local err_code = ffi.new('unsigned int')
	local image_data = ffi.new('unsigned char*[1]')
	local width = ffi.new('unsigned int[1]')
	local height = ffi.new('unsigned int[1]')
	local file_data = ffi.new('unsigned char*[1]')
	local img_size = ffi.new('size_t[1]')

	lodepng.lodepng_load_file(file_data, img_size, filename)
	err_code = lodepng.lodepng_decode32(image_data, width, height, file_data[0], img_size[0])

	--ffi.C.free(file_data[0])
	if err_code ~= 0 then
		print("Error loading PNG file: " .. ffi.string(lodepng.lodepng_error_text(err_code)))
		--ffi.C.free(image_data[0])
		return
	end

	
	local texture = Texture:New()
	texture:Bind()

	

	gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR)

	gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR)
	gl.TexImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width[0], height[0], 0, GL.RGBA, GL.UNSIGNED_BYTE, image_data[0])
	local err = gl.GetError()
	if err ~= GL.NO_ERROR then
		error("GL error: " .. err)
	end
	self.texture = texture
	--ffi.C.free(image_data[0])
end

function PNGLoader:GetTexture()
	return self.texture
end

return PNGLoader