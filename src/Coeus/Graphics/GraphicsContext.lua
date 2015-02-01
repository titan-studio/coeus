local Coeus = (...)

local ffi = require("ffi")
local OOP = Coeus.Utility.OOP

local OpenGL = Coeus.Bindings.OpenGL
local gl = OpenGL.gl
local GL = OpenGL.GL

local Scene = Coeus.Graphics.Scene
local Layer = Coeus.Graphics.Layer
local Framebuffer = Coeus.Graphics.Framebuffer
local Mesh = Coeus.Graphics.Mesh
local Shader = Coeus.Graphics.Shader

local Matrix4 = Coeus.Math.Matrix4

local GraphicsContext = OOP:Class()
	:Members {
		Window = false,

		texture_units = {},
		MaxTextureUnits = 32,

		render_passes = {},

		ActiveScene = false,

		Shaders = {},

		FullscreenQuad = false,
		IdentityQuad = false,
		IdentityTexture = false,

		GeometryFramebuffer = false,
		LightFramebuffer = false,
	}

function GraphicsContext:_new(window)
	self.Window = window

	local texture_units = ffi.new('int[1]')
	gl.GetIntegerv(GL.MAX_TEXTURE_IMAGE_UNITS, texture_units)
	self.MaxTextureUnits = texture_units[0]

	self.FullscreenQuad = Mesh:New()
	local mesh_data = Coeus.Asset.Model.MeshData:New()
	mesh_data.Vertices = {
		-1.0, -1.0, 0.0, 	0.0, 0.0,
		 1.0, -1.0, 0.0,	1.0, 0.0,
		-1.0,  1.0, 0.0, 	0.0, 1.0,
		 1.0,  1.0, 0.0,	1.0, 1.0
	}
	mesh_data.Indices = {
		0, 1, 2,
		2, 1, 3
	}
	mesh_data.Format.TexCoords = true
	self.FullscreenQuad:SetData(mesh_data)

	local ident_data = Coeus.Asset.Model.MeshData:New()
	ident_data.Vertices = {
		0.0, 0.0, 0.0, 		0.0, 0.0,
		1.0, 0.0, 0.0, 		1.0, 0.0,
		0.0, 1.0, 0.0, 		0.0, 1.0,
		1.0, 1.0, 0.0,		1.0, 1.0
	}
	ident_data.Indices = {
		3, 1, 2,
		2, 1, 0
	}
	ident_data.Format.TexCoords = true
	self.IdentityQuad = Coeus.Graphics.Mesh:New()
	self.IdentityQuad:SetData(ident_data)
	ident_data = nil

	local img_data = Coeus.Asset.Image.ImageData:New()
	img_data.Width = 1
	img_data.Height = 1
	img_data:Map(function(data, x, y, data, idx)
		return 255, 255, 255, 255
	end)
	self.IdentityTexture = Coeus.Graphics.Texture:New(img_data)
	img_data = nil

	local initialize_fbos = function(w, h)
		self.GeometryFramebuffer = Framebuffer:New(self, w, h, {
			Coeus.Asset.Image.ImageData.Format.RGBA,
			Coeus.Asset.Image.ImageData.Format.RGBA,
			Coeus.Asset.Image.ImageData.Format.Single
		}, true, false)
		self.LightFramebuffer = Framebuffer:New(self, w, h, {
 			Coeus.Asset.Image.ImageData.Format.RGBA
		}, false, false)
	end

	self.Window.Resized:Listen(initialize_fbos)
	initialize_fbos(self.Window:GetSize())

	self.Shaders.Render2D = Shader:New(self, Coeus.Graphics.Shaders.Render2D)
	self.Shaders.RenderGeometry = Shader:New(self, Coeus.Graphics.RenderGeometry)
	self.Shaders.CompositeFBOs = Shader:New(self, Coeus.Graphics.CompositeFBOs)
end

function GraphicsContext:BindTexture(texture)
	local unused = 1
	for i = 1, self.MaxTextureUnits do
		if self.texture_units[i] == nil or texture == self.texture_units[i] then
			unused = i - 1
			break
		end
	end
	texture:Bind(tonumber(unused + GL.TEXTURE0))
	self.texture_units[unused + 1] = texture

	return unused
end
function GraphicsContext:UnbindTextures()
	for i, texture in ipairs(self.texture_units) do
		texture:Unbind()
	end
	self.texture_units = {}
end

function GraphicsContext:Render()
	--TODO: Reorganize this, it's atrocious and isn't ever going to be renderer-agnostic
	--[[self.Window.MainViewport:Use()
	if not self.ActiveScene then
		return
	end

	gl.Enable(GL.DEPTH_TEST)
	gl.DepthMask(GL.TRUE)

	self.ActiveScene:RenderLayers(Coeus.Graphics.Layer.Flag.UnlitBackground)

	self.GeometryFramebuffer:Bind()
	self.GeometryFramebuffer:Clear()
	--Render geometry layers here
	self.ActiveScene:RenderLayers(Coeus.Graphics.Layer.Flag.Geometry)
	--eventually render transparent stuff somewhere
	self.GeometryFramebuffer:Unbind()

	gl.Disable(GL.DEPTH_TEST)
	gl.DepthMask(GL.FALSE)

	--additive blending...
	gl.BlendFunc(GL.ONE, GL.ONE)
	self.LightFramebuffer:Bind()
	self.LightFramebuffer:Clear()
	
	--Render lights here
	self.ActiveScene:RenderLayers(Coeus.Graphics.Layer.Flag.Lights)

	self.LightFramebuffer:Unbind()
	gl.BlendFunc(GL.ONE, GL.ZERO)

	self.Shaders.CompositeFBOs:Use()
	self.Shaders.CompositeFBOs:Send("DiffuseBuffer", self.GeometryFramebuffer.textures[1])
--	self.Shaders.CompositeFBOs:Send("LightBuffer", self.LightFramebuffer.textures[1])
	self.FullscreenQuad:Render()

	gl.BlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	self.ActiveScene:RenderLayers(Coeus.Graphics.Layer.Flag.Unlit2D)
	gl.BlendFunc(GL.ONE, GL.ZERO)

	self:UnbindTextures()]]
end

return GraphicsContext