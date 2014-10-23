--[[
	Image Data

	Defines a chunk of image data loaded by Coeus.
]]

local Coeus = (...)
local OOP = Coeus.Utility.OOP

local ffi = require("ffi")

local ImageData = OOP:Class(Coeus.Asset.Format) {
	Width = 0,
	Height = 0,

	image = nil,
	size = nil,
	format = 0,
}

ImageData.Format = OOP:Static() {
	RGBA = 0,
	Depth = 1,
	DepthStencil = 2,
	Single = 3
}

function ImageData:Map(func)
	if (self.Width == 0 or self.Height == 0) then
		return
	end

	local bpp = 4
	if (not self.image) then
		self.image = ffi.new("unsigned char[?]", self.Width * self.Height * bpp)
	end

	local ctr = 0
	for i = 0, self.Width - 1 do
		for j = 0, self.Height - 1 do
			local bytes = {func(self, i, j, self.image, ctr)}
			for i = 1, bpp do
				self.image[ctr + i - 1] = bytes[i] or 0
			end
			ctr = ctr + bpp
		end
	end
end

return ImageData