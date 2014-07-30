local ffi = require("ffi")
local Coeus = ...
local OOP = Coeus.Utility.OOP

local OpenGL = Coeus.Bindings.OpenGL
local gl = OpenGL.gl
local GL = OpenGL.GL

local RenderPass = Coeus.Graphics.RenderPass

local GraphicsContext = OOP:Class() {
	texture_units = {},
	MaxTextureUnits = 32,

	render_passes = {},

	ActiveCamera = false
}

function GraphicsContext:_new()
	local texture_units = ffi.new('int[1]')
	gl.GetIntegerv(GL.MAX_TEXTURE_IMAGE_UNITS, texture_units)
	self.MaxTextureUnits = texture_units[0]

	self.render_passes[#self.render_passes+1] = RenderPass:New("Default Pass", RenderPass.PassTag.Default, 1)
	self.render_passes[#self.render_passes+1] = RenderPass:New("Transparent Pass", RenderPass.PassTag.Transparent, 2)
	self.render_passes[#self.render_passes+1] = RenderPass:New("HUD", RenderPass.PassTag.HUD, 3)
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
	return unused
end

function GraphicsContext:UnbindTextures()
	for i, texture in ipairs(self.texture_units) do
		texture:Unbind()
	end
end

return GraphicsContext