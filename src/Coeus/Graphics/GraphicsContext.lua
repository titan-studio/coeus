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

	ActiveCamera = false,

	all_scenes = {},
	active_scenes = {}
}

function GraphicsContext:_new()
	local texture_units = ffi.new('int[1]')
	gl.GetIntegerv(GL.MAX_TEXTURE_IMAGE_UNITS, texture_units)
	self.MaxTextureUnits = texture_units[0]

	self.render_passes[#self.render_passes+1] = RenderPass:New(self, "Default Pass", RenderPass.PassTag.Default, 1)
	self.render_passes[#self.render_passes+1] = RenderPass:New(self, "Transparent Pass", RenderPass.PassTag.Transparent, 2)
	self.render_passes[#self.render_passes+1] = RenderPass:New(self, "HUD", RenderPass.PassTag.HUD, 3)
end

function GraphicsContext:BindTexture(texture)
	local unused = 1
	for i = 1, self.MaxTextureUnits do
		if self.texture_units[i] == nil then
			unused = i - 1
			break
		end
	end
	texture:Bind(tonumber(unused + GL.TEXTURE0))
	self.texture_units[unused] = texture
	return unused
end
function GraphicsContext:UnbindTextures()
	for i, texture in ipairs(self.texture_units) do
		texture:Unbind()
	end
	self.texture_units = {}
end

function GraphicsContext:AddScene(scene)
	for i, v in pairs(self.all_scenes) do
		if v == scene then
			return
		end
	end
	self.all_scenes[#self.all_scenes + 1] = scene
end
function GraphicsContext:RemoveScene(scene)
	self:SetSceneActive(scene, false)
	for i, v in pairs(self.all_scenes) do
		if v == scene then
			table.remove(self.all_scenes, i)
		end
	end
end
function GraphicsContext:SetSceneActive(scene, active)
	local found = false
	for i, v in pairs(self.all_scenes) do
		if v == scene then
			found = true
		end
	end
	if not found then
		return false
	end
	for i, v in pairs(self.active_scenes) do
		if active then
			if v == scene then
				return false
			end
		else
			table.remove(self.active_scenes, i)
			return true
		end
	end
	self.active_scenes[#self.active_scenes + 1] = scene
	return true
end


function GraphicsContext:Render()
	for i, v in ipairs(self.render_passes) do
		v:Render()
	end
end

return GraphicsContext