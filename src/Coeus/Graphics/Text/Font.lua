local ffi			= require("ffi")
local Coeus 		= (...)
local OOP			= Coeus.Utility.OOP
local tt			= Coeus.Bindings.stb_truetype
local stdio			= Coeus.Bindings.stdio_

local OpenGL		= Coeus.Bindings.OpenGL
local gl = OpenGL.gl
local GL = OpenGL.GL

local Texture 		= Coeus.Graphics.Texture
local Glyph 		= Coeus.Graphics.Text.Glyph

--[[
	Huge thanks to slime from #LOVE on irc.oftc.net
--]]

local Font = OOP:Class() {
	glyphs = {},

	texture_cache_id = 0,
	texture_size_index = 1,
	texture_width = 0,
	texture_height = 0,
	texture_x = 0,
	texture_y = 0,
	row_height = 0,

	font = false,
	scale = 1,
	height = 12,
	line_height = 1,
	baseline = 0,

	ascent = 0,
	descent = 0,


	textures = {},
}	
Font.TextureSizes = {
	{128, 128}, {256, 128},
	{256, 256}, {512, 256},
	{512, 512}, {1024, 512},
	{1024, 1024}, {2048, 1024},
	{2048, 2048}
}
Font.TexturePadding = 1

function Font:_new(filename, height)
	self.height = height or 12

	local file = stdio.fopen(filename, "rb")
	stdio.fseek(file, 0, stdio.SEEK_END)
	local file_size = stdio.ftell(file)
	stdio.fseek(file, 0, stdio.SEEK_SET)
	local buffer = ffi.new("unsigned char[" .. tonumber(file_size) .. "]")
	stdio.fread(buffer, 1, file_size, file)

	self.font = ffi.new("stbtt_fontinfo[1]")
	local ascent = ffi.new("int[1]")
	local descent = ffi.new("int[1]")
	local linegap = ffi.new("int[1]")

	tt.stbtt_InitFont(self.font, buffer, 0)
	self.scale = tt.stbtt_ScaleForPixelHeight(self.font, self.height)
	self.scale = tonumber(self.scale)
	tt.stbtt_GetFontVMetrics(self.font, ascent, descent, linegap)

	--if it bitches, check this line
	self.baseline = math.floor(tonumber(ascent[0] * self.scale))
	self.ascent = ascent[0] * self.scale
	self.descent = descent[0] * self.scale
	self.linegap = linegap[0] * self.scale
end

function Font:CreateTexture()
	local size_index = self.texture_size_index
	print(size_index < #Font.TextureSizes, #self.textures > 0)
	if size_index < #Font.TextureSizes and #self.textures > 0 then
		local top = self.textures[#self.textures]
		top:Destroy()
		table.remove(self.textures, #self.textures)

		self.texture_cache_id = self.texture_cache_id + 1
		size_index = size_index + 1
	end

	local texture = Texture:New()
	texture:Bind()

	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_BASE_LEVEL, 0)
	gl.TexParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAX_LEVEL, 0)
	gl.TexParameterf(GL.TEXTURE_2D, GL.TEXTURE_MAX_ANISOTROPY_EXT, 8)
	gl.PixelStorei(GL.UNPACK_ALIGNMENT, 1)
	gl.PixelStorei(GL.PACK_ALIGNMENT, 1)
	self.texture_width = Font.TextureSizes[size_index][1]
	self.texture_height = Font.TextureSizes[size_index][2]
	local format = GL.RED
	local internal_format = GL.R8
	local bpp = 1
	local byte_len = self.texture_width * self.texture_height * bpp
	local data = ffi.new("unsigned char[?]", byte_len, 0)
	gl.TexImage2D(GL.TEXTURE_2D, 0, internal_format,
				  self.texture_width, self.texture_height,
				  0, format, GL.UNSIGNED_BYTE,
				  data)

	
	local err = gl.GetError()
	if err ~= GL.NO_ERROR then
		texture:Destroy()
		error("Couldn't create font texture! Error: " .. err)
	end

	self.texture_size_index = size_index
	self.texture_x = Font.TexturePadding
	self.texture_y = Font.TexturePadding 
	self.row_height = Font.TexturePadding

	self.textures[#self.textures+1] = texture
end

function Font:AddGlyph(glyph)
	local x1, y1 = ffi.new("int[1]"), ffi.new("int[1]")
	local x2, y2 = ffi.new("int[1]"), ffi.new("int[1]")
	tt.stbtt_GetCodepointBitmapBox(
		self.font, glyph, self.scale, self.scale,
		x1, y1, x2, y2)
	x1 = tonumber(x1[0])
	y1 = tonumber(y1[0])
	local width = tonumber(x2[0]) - x1
	local height = tonumber(y2[0]) - y1
	local bytes = width * height
	local data
	if bytes > 0 then
		data = ffi.new("unsigned char[?]", bytes, 64)
	else
		local data = ffi.new("unsigned char[0]")
	end
	tt.stbtt_MakeCodepointBitmap(
		self.font, data, width, height, width, self.scale, self.scale,
		glyph)

--[[
	local data = tt.stbtt_GetCodepointBitmap(
		self.font, self.scale, self.scale, glyph, x2, y2, x1, y1)
	local width = tonumber(x2[0])
	local height = tonumber(y2[0])
	local y1 = tonumber(y1[0])
]]
	if self.texture_x + width + Font.TexturePadding > self.texture_width then
		self.texture_x = Font.TexturePadding
		self.texture_y = self.texture_y + self.row_height
		self.row_height = Font.TexturePadding
	end
	if self.texture_y + height + Font.TexturePadding > self.texture_height then
		local cache_id = self.texture_cache_id
		self:CreateTexture()

		if cache_id ~= self.texture_cache_id then
			local glyphs = Coeus.Utility.Table.Copy(self.glyphs)
			for i, v in pairs(glyphs) do
				cache_id = self.texture_cache_id
				self:AddGlyph(i)
				table.remove(self.glyphs, i)

				if cache_id ~= self.texture_cache_id then
					break
				end
			end
		end
	end

	local g = Glyph:New()
	local advance = ffi.new("int[1]")
	local lsb = ffi.new("int[1]")
	tt.stbtt_GetCodepointHMetrics(self.font, glyph, advance, lsb)

	g.Spacing = tonumber(advance[0]) * self.scale
	g.BearingX = tonumber(lsb[0]) * self.scale
	g.BearingY = tonumber(y1) + height

	local texture = self.textures[#self.textures]
	g.Texture = texture

	g.Vertices = {}
	if width > 0 and height > 0 then
		texture:Bind()
		gl.TexSubImage2D(GL.TEXTURE_2D,
			0, self.texture_x, self.texture_y, width, height,
			GL.RED, GL.UNSIGNED_BYTE, data)

		g.Vertices = {
			{
				x = 0, y = 0 + height, z = 0, 
				s = (self.texture_x) / self.texture_width, 
				t = (self.texture_y) / self.texture_height
			},
			{
				x = 0 + width, y = 0 + height, z = 0, 
				s = (self.texture_x+width) / self.texture_width, 
				t = (self.texture_y) / self.texture_height
			},
			{
				x = 0, y = 0, z = 0, 
				s = (self.texture_x) / self.texture_width, 
				t = (self.texture_y+height) / self.texture_height
			},
			{
				x = 0, y = 0 , z = 0, 
				s = (self.texture_x) / self.texture_width, 
				t = (self.texture_y +height) / self.texture_height
			},
			{
				x = 0 + width, y = 0 + height, z = 0, 
				s = (self.texture_x+width) / self.texture_width, 
				t = (self.texture_y) / self.texture_height
			},
			{
				x = 0 + width, y = 0, z = 0, 
				s = (self.texture_x+width) / self.texture_width, 
				t = (self.texture_y+height) / self.texture_height
			},
		}
		for i, v in ipairs(g.Vertices) do
			v.x = v.x + g.BearingX
			v.y = v.y - g.BearingY
		end
	end
	if width > 0 then
		self.texture_x = self.texture_x + width + Font.TexturePadding
	end
	if height > 0 then
		self.row_height = math.max(self.row_height, height + Font.TexturePadding)
	end
	g.Codepoint = glyph
	self.glyphs[glyph] = g

	return g
end
function Font:GetGlyph(glyph)
	local found = self.glyphs[glyph]
	if found then
		return found
	end
	return self:AddGlyph(glyph)
end

function Font:GenerateMesh(text, extra_spacing, offset_x, offset_y)
	local draws = {}

	local extra_spacing = extra_spacing or 0
	local offset_x = offset_x or 0
	local offset_y = offset_y or 0
	local dx = offset_x
	local dy = offset_y

	local line_height = self:GetBaseline()
	local max_width = 0

	--Do a pass to get all glyphs loaded
	for codepoint in Coeus.Utility.Unicode.UTF8Iterate(text) do
		self:GetGlyph(codepoint)
	end

	local vertex_data = {}
	local vertex_id = 0
	--Now do the actual mesh building
	for codepoint in Coeus.Utility.Unicode.UTF8Iterate(text) do
		if codepoint == string.byte('\n') then
			if dx > max_width then
				max_width = dx
			end
			dy = dy + math.floor(self:GetHeight() + self:GetLineHeight() + 0.5)
			dx = offset_x
		else
			local glyph = self:GetGlyph(codepoint)
			if glyph.Texture then
				local start_id = vertex_id
				for i, v in ipairs(glyph.Vertices) do
					vertex_id = vertex_id + 1
					vertex_data[#vertex_data + 1] = v.x + dx
					vertex_data[#vertex_data + 1] = v.y + dy + line_height
					vertex_data[#vertex_data + 1] = v.z

					vertex_data[#vertex_data + 1] = v.s
					vertex_data[#vertex_data + 1] = v.t
				end

				if #draws == 0 or draws[#draws].texture ~= glyph.Texture then

					local draw = {}
					draw.start = start_id
					draw.count = 0
					draw.texture = glyph.Texture
					draws[#draws + 1] = draw
				end

				draws[#draws].count = draws[#draws].count + #glyph.Vertices
			end

			dx = dx + glyph.Spacing

			if codepoint == string.byte(" ") and extra_spacing ~= 0 then
				dx = math.floor(dx + extra_spacing)
			end
		end
	end

	table.sort(draws, function(a, b)
		return a.texture.handle < b.texture.handle
	end)

	if dx > max_width then
		max_width = dx
	end

	local height = dy - offset_y
	if dx > 0 then
		height = height + (self:GetHeight() * self:GetLineHeight() + 0.5)
	end
	return vertex_data, draws, max_width - offset_x, height
end

function Font:GetWidth(text)

end

function Font:GetHeight()
	return self.height
end

function Font:GetLineHeight()
	return self.line_height
end

function Font:GetBaseline()
	return self.baseline
end

return Font