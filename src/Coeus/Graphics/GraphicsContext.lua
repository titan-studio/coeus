local ffi = require("ffi")
local Coeus = ...
local OOP = Coeus.Utility.OOP

local OpenGL = Coeus.Bindings.OpenGL
local gl = OpenGL.gl
local GL = OpenGL.GL

local RenderPass = Coeus.Graphics.RenderPass
local Framebuffer = Coeus.Graphics.Framebuffer
local Mesh = Coeus.Graphics.Mesh
local Shader = Coeus.Graphics.Shader

local GraphicsContext = OOP:Class() {
	window = false,

	texture_units = {},
	MaxTextureUnits = 32,

	render_passes = {},

	ActiveCamera = false,

	all_scenes = {},
	active_scenes = {},

	Shaders = {},

	FullscreenQuad = false,

	GeometryFramebuffer = false,
	LightFramebuffer = false,

	PointLights = {},
	DirectionalLights = {}
}

function GraphicsContext:_new(window)
	self.Window = window

	local texture_units = ffi.new('int[1]')
	gl.GetIntegerv(GL.MAX_TEXTURE_IMAGE_UNITS, texture_units)
	self.MaxTextureUnits = texture_units[0]

	self.render_passes[#self.render_passes+1] = RenderPass:New(self, "Default Pass", RenderPass.PassTag.Default, 1)
	self.render_passes[#self.render_passes+1] = RenderPass:New(self, "Transparent Pass", RenderPass.PassTag.Transparent, 2)
	self.render_passes[#self.render_passes+1] = RenderPass:New(self, "HUD", RenderPass.PassTag.HUD, 3)

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

	self.UnitSphere = Coeus.Utility.OBJLoader:New("assets/UnitSphere.obj"):GetMesh()

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

	self.Shaders.RenderGeometry = Shader:New(self, [[
#version 330
layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord_;
layout(location=2) in vec3 normal_;

uniform mat4 ModelViewProjection;
uniform mat4 Model;

out vec2 texcoord;
out vec3 normal;
out vec2 depth;
out float f_log_z;
out float linear_depth;

void main() {
	gl_Position = ModelViewProjection * vec4(position, 1.0);
	f_log_z = 1.0 + gl_Position.w;
	depth = gl_Position.zw;

	texcoord = texcoord_;
	normal = (Model * vec4(normal_, 0.0)).xyz;
}
		]],[[
#version 330

layout(location=0) out vec4 DiffuseColor;
layout(location=1) out vec4 NormalColor;
layout(location=2) out float LinearDepth;

uniform sampler2D ModelTexture;
uniform float ZNear;
uniform float ZFar;

in vec2 texcoord;
in vec3 normal;
in vec2 depth;
in float f_log_z;

void main() {
	vec3 norm = normalize(normal);
	norm = norm * 0.5 + 0.5;

	DiffuseColor = texture(ModelTexture, texcoord);
	NormalColor = vec4(norm, 1.0);

	LinearDepth = gl_FragCoord.z;

	float coefficient_half = (2.0 / log2(ZFar + ZNear)) * 0.5;
	gl_FragDepth = log2(f_log_z) * coefficient_half;
}
	]])
	self.Shaders.CompositeFBOs = Shader:New(self, [[
#version 330
layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord_;

out vec2 texcoord;

void main() {
	gl_Position = vec4(position, 1.0);
	texcoord = texcoord_;
}
		]],[[
#version 330

layout(location=0) out vec4 FinalColor;

uniform sampler2D DiffuseBuffer;
uniform sampler2D LightBuffer;

in vec2 texcoord;

void main() {
	vec4 diffuse = texture(DiffuseBuffer, texcoord);
	vec4 light = texture(LightBuffer, texcoord);

	FinalColor = vec4((diffuse.xyz * light.xyz + light.w), 1.0);
}
	]])
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
	gl.Enable(GL.DEPTH_TEST)
	gl.DepthMask(GL.TRUE)

	self.GeometryFramebuffer:Bind()
	self.GeometryFramebuffer:Clear()
	for i, v in ipairs(self.render_passes) do
		v:Render()
		break
	end
	self.GeometryFramebuffer:Unbind()

	gl.Disable(GL.DEPTH_TEST)
	gl.DepthMask(GL.FALSE)

	--additive blending...
	gl.BlendFunc(GL.ONE, GL.ONE)
	self.LightFramebuffer:Bind()
	self.LightFramebuffer:Clear()
	
	for i, v in ipairs(self.PointLights) do
		v:Render(true)
	end

	for i, v in ipairs(self.DirectionalLights) do
		v:Render(true)
	end

	self.LightFramebuffer:Unbind()
	gl.BlendFunc(GL.ONE, GL.ZERO)

	self.Shaders.CompositeFBOs:Use()
	self.Shaders.CompositeFBOs:Send("DiffuseBuffer", self.GeometryFramebuffer.textures[1])
	self.Shaders.CompositeFBOs:Send("LightBuffer", self.LightFramebuffer.textures[1])
	self.FullscreenQuad:Render()

	self:UnbindTextures()
end

return GraphicsContext