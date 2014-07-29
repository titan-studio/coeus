local Coeus = ...
local Oop = Coeus.Utility.OOP

local GraphicsContext = OOP:Class() {
	texture_units = {},

	MaxTextureUnits = 32
}

function GraphicsContext:_new()

end

function GraphicsContext:BindTexture(texture)
	local unused = 1
	for i = 1, self.MaxTextureUnits do
		if self.texture_units[i] == nil then
			unused = i
			break
		end
	end

	texture:Bind(unused)
	self.texture_units[unused] = texture
end

function GraphicsContext:UnbindTextures()
	for i, texture in ipairs(self.texture_units) do
		texture:Unbind()
	end
end

return GraphicsContext