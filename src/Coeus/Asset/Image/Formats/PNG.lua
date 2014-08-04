local Coeus = (...)
local ffi = require("ffi")

local OOP = Coeus.Utility.OOP
local ImageData = Coeus.Asset.Image.ImageData
local lodepng = Coeus.Bindings.lodepng

local PNG = OOP:Static(Coeus.Asset.Format)()

function PNG:Load(filename)
	local err_code = ffi.new("unsigned int")
	local image_data = ffi.new("unsigned char*[1]")
	local width = ffi.new("unsigned int[1]")
	local height = ffi.new("unsigned int[1]")
	local file_data = ffi.new("unsigned char*[1]")
	local img_size = ffi.new("size_t[1]")

	lodepng.lodepng_load_file(file_data, img_size, filename)
	err_code = lodepng.lodepng_decode32(image_data, width, height, file_data[0], img_size[0])

	if (err_code ~= 0) then
		return nil, {
			code = err_code,
			message = lodepng.lodepng_error_text(err_code)
		}
	end

	local image_data = ImageData:New()
	image_data.Width = tonumber(width[0])
	image_data.Height = tonumber(height[0])
	image_data.data = file_data
	image_data.size = img_size

	return image_data
end

function PNG:Match(filename)
	return not not filename:match("%.png$")
end

return PNG