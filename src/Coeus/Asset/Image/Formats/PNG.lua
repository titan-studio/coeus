--[[
	PNG Loader

	Loads PNG images (.png)
]]

local Coeus = (...)
local ffi = require("ffi")

local OOP = Coeus.Utility.OOP
local ImageData = Coeus.Asset.Image.ImageData
local LodePNG = Coeus.Bindings.LodePNG

local PNGFormat = OOP:Static(Coeus.Asset.Format)()

function PNGFormat:Load(filename)
	local err_code = ffi.new("unsigned int")
	local image_data = ffi.new("unsigned char*[1]")
	local width = ffi.new("unsigned int[1]")
	local height = ffi.new("unsigned int[1]")
	local file_data = ffi.new("unsigned char*[1]")
	local img_size = ffi.new("size_t[1]")

	LodePNG.lodepng_load_file(file_data, img_size, filename)
	err_code = LodePNG.lodepng_decode32(image_data, width, height, file_data[0], img_size[0])

	if (err_code ~= 0) then
		return nil, {
			code = err_code,
			message = LodePNG.lodepng_error_text(err_code)
		}
	end

	local out = ImageData:New()
	out.Width = tonumber(width[0]) or 0
	out.Height = tonumber(height[0]) or 0
	out.image = image_data[0]
	out.size = img_size

	return out
end

function PNGFormat:Match(filename)
	return not not filename:match("%.png$")
end

return PNGFormat