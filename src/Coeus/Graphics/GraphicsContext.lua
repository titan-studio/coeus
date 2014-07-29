local Coeus = ...
local OOP = Coeus.Utility.OOP

local GraphicsContext = OOP:Class() {
	texture_units = {},

	MaxTextureUnits = 32
}

function GraphicsContext:_new()
	local texture_units = ffi.new('int[1]')
	gl.GetIntegerv(GL.MAX_TEXTURE_IMAGE_UNITS, texture_units)
	self.MaxTextureUnits = texture_units[0]
end

function GraphicsContext:BindTexture(texture)
	local unused = 1
	for i = 1, self.MaxTextureUnits do
		if self.texture_units[i] == nil then
			unused = i
			break
		end
	end

	texture:Bind(unused + GL.TEXTURE0)
	self.texture_units[unused] = texture
end

function GraphicsContext:UnbindTextures()
	for i, texture in ipairs(self.texture_units) do
		texture:Unbind()
	end
end

return GraphicsContext