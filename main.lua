local Coeus = require("src.Coeus")

local tests = require("tests")
tests:Init(Coeus)
--print(tests:RunTestFolder("Coeus"))

--require("audio_test")

local Window = Coeus.Graphics.Window
local Vector3 = Coeus.Math.Vector3
local Matrix4 = Coeus.Math.Matrix4
local Quaternion = Coeus.Math.Quaternion

local OpenGL = Coeus.Bindings.OpenGL
local GLFW = Coeus.Bindings.GLFW
local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL

local Scene = Coeus.Graphics.Scene
local Shader = Coeus.Graphics.Shader
local Mesh = Coeus.Graphics.Mesh
local Entity = Coeus.Entity.Entity
local Camera = Coeus.Graphics.Camera
local Material = Coeus.Graphics.Material
local MeshRenderer =  Coeus.Graphics.MeshRenderer
local TextRenderer = Coeus.Graphics.Text.TextRenderer

local window = Window:New("Coeus", 1280, 720, {fullscreen = false, resizable = true, vsync = true})
local TestApp = Coeus.Application:New(window)
local keyboard = window.Keyboard
local mouse = window.Mouse

local PlaneMesh = Coeus.Graphics.Debug.PlaneMesh

local Framebuffer = Coeus.Graphics.Framebuffer

local fb = nil
local light_buffer = nil

local dir_light = nil
local composite = nil

function TestApp:Initialize()
	local scene = Scene:New(window.Graphics)
	window.Graphics:AddScene(scene)
	window.Graphics:SetSceneActive(scene, true)

	local cam = Entity:New()
	cam:SetPosition(0, 5, 5)
	cam:AddComponent(Camera:New(window))
	cam:BuildTransform()
	scene:AddEntity(cam)
	window.Graphics.ActiveCamera = cam:GetComponent(Camera)

	local plane = Entity:New()
	plane:SetPosition(0, 0, 0)
	scene:AddEntity(plane)
	local plane_render = MeshRenderer:New(window.Graphics)
	plane_render.Mesh = PlaneMesh:New(30, 30, 5, 5)
	plane:AddComponent(plane_render)

	local w, h = window:GetSize()
	fb = Framebuffer:New(window.Graphics, w, h, nil, 3, true)
	light_buffer = Framebuffer:New(window.Graphics, w, h, nil, 1, false)


	local test_obj = Entity:New()
	scene:AddEntity(test_obj)
	test_obj:SetPosition(0, 2, 0)
	local mesh_renderer = MeshRenderer:New(window.Graphics)
	mesh_renderer.Mesh = Coeus.Utility.OBJLoader:New("assets/test.obj"):GetMesh()
	test_obj:AddComponent(mesh_renderer)
	local material = Material:New(window.Graphics)
	material.Shader = Shader:New(window.Graphics, [[
		#version 330
		layout(location=0) in vec3 position;
		layout(location=1) in vec2 texcoord_;
		layout(location=2) in vec3 normal_;

		uniform mat4 ModelViewProjection;
		uniform mat4 Model;

		out vec2 texcoord;
		out vec3 normal;

		void main() {
			gl_Position = ModelViewProjection * vec4(position, 1.0);
			texcoord = texcoord_;
			normal = (Model * vec4(normal_, 0.0)).xyz;
		}
		]],[[
		#version 330
		
		layout(location=0) out vec4 DiffuseColor;
		layout(location=1) out vec4 NormalColor;

		uniform sampler2D tex;

		in vec2 texcoord;
		in vec3 normal;

		void main() {
			vec3 norm;
			norm = normalize(normal);
			norm += 1.0;
			norm *= 0.5;

			DiffuseColor = texture(tex, texcoord);
			NormalColor = vec4(norm, 1.0);
		}
	]])
	material.Textures.tex = Coeus.Utility.PNGLoader:New("assets/test.png"):GetTexture()
	test_obj:AddComponent(material)

	dir_light = Shader:New(window.Graphics, [[
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

layout(location=0) out vec4 LightColor;

uniform vec3 light_direction;
uniform vec3 light_color;
uniform vec3 eye_pos;
uniform mat4 InverseViewProjection;
uniform sampler2D NormalBuffer;
uniform sampler2D DepthBuffer;

in vec2 texcoord;

void main() {
	vec4 normal = vec4(texture(NormalBuffer, texcoord).xyz, 0.0);
	normal.xyz *= 2.0;
	normal.xyz -= vec3(1.0);

	vec4 light_dir = vec4(light_direction, 0.0);
	light_dir = normalize(light_dir);

	float cosine = max(dot(light_dir, normal), 0.0);
	float specular = 0.0;

	float depth = texture(DepthBuffer, texcoord).x;

	vec4 pixel_pos = vec4(
		texcoord.x * 2.0 - 1.0,
	  -(texcoord.y * 2.0 - 1.0),
		depth,
		1.0
	);
	pixel_pos = InverseViewProjection * pixel_pos;
	pixel_pos /= pixel_pos.w;
	vec3 to_pixel = normalize(eye_pos - pixel_pos.xyz);
	
	if (cosine > 0.0) {
		vec3 half_vec = normalize(light_dir.xyz + to_pixel);
		float half_vec_cos = max(dot(half_vec, normal.xyz), 0.0);
		specular = pow(clamp(half_vec_cos, 0.0, 1.0), 64.0);
	}

	LightColor = vec4(vec3(cosine) * light_color, max(0.0, min(1.0, specular)));
}
	]])

	composite = Shader:New(window.Graphics, [[
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

	FinalColor = vec4(diffuse.xyz * light.xyz, 1.0);
}
	]])


	local mat2 = Material:New(window.Graphics)
	mat2.Shader = material.Shader
	mat2.Textures.tex = Coeus.Utility.PNGLoader:New("assets/plane.png"):GetTexture()

	plane:AddComponent(mat2)

	--[[local text = Entity:New()
	text:SetPosition(-100, 0.01, 1400)
	scene:AddEntity(text)
	local text_renderer = TextRenderer:New(window.Graphics)
	text_renderer.text = "coeus"
	text_renderer.font = Coeus.Graphics.Text.Font:New("Orbitron-Regular.ttf", 100)
	text:SetScale(0.05, 0.05, 0.01)
	text:SetRotation(Quaternion.FromAngleAxis(math.rad(90), Vector3:New(1, 0, 0)))
	text_renderer:RebuildText()
	text:AddComponent(text_renderer)]]

	mouse:SetLocked(true)

	self.look_pitch = 0
	self.look_yaw = 0
	self.look_roll = 0
end

local des_rot = Quaternion:New()
function TestApp:Render()
	local delta = self.Timer:GetDelta()

	window:SetTitle("Coeus (FPS: " .. self.Timer:GetFPS() .. ")")

	local cam = window.Graphics.ActiveCamera:GetEntity()
	local dx, dy = mouse:GetDelta()
	local rot = cam:GetRotation()
	self.look_pitch = self.look_pitch + dy * 0.005
	if mouse:IsButtonDown(2) then
		self.look_roll = self.look_roll + dx * 0.005
	else
		self.look_yaw = self.look_yaw + dx * 0.005
		
	end
	local yaw = Quaternion.FromAngleAxis(self.look_yaw, Vector3:New(0, 1, 0))
	local pitch = Quaternion.FromAngleAxis(self.look_pitch, Vector3:New(1, 0, 0))
	local roll = Quaternion.FromAngleAxis(self.look_roll, Vector3:New(0, 0, 1))
	des_rot = pitch * yaw
	rot = Quaternion.Slerp(rot, des_rot, self.Timer:GetDelta() * 20)
	
	fb:Bind()
	fb:Clear()

	window.Graphics:Render()
	fb:Unbind()

	light_buffer:Bind()
	dir_light:Use()
	dir_light:Send("eye_pos", cam:GetRenderTransform():GetTranslation())
	dir_light:Send("InverseViewProjection", (window.Graphics.ActiveCamera:GetViewTransform() * window.Graphics.ActiveCamera:GetProjectionTransform()):GetInverse())
	dir_light:Send("NormalBuffer", fb.textures[2])
	dir_light:Send("DepthBuffer", fb.depth)
	dir_light:Send("light_direction", Vector3:New(math.cos(os.clock()), math.sin(os.clock()), 0))
	dir_light:Send("light_color", Vector3:New(0.5, 0.5, 0.5))
	light_buffer.mesh:Render()
	light_buffer:Unbind()

	composite:Use()

	composite:Send("DiffuseBuffer", fb.textures[1])
	composite:Send("LightBuffer", light_buffer.textures[1])
	fb.mesh:Render()

	--fb:Render()
	window.Graphics:UnbindTextures()



	local dist = 0
	local strafe = 0

	if keyboard:IsKeyDown("w") then
		dist = -5 * delta
	end
	if keyboard:IsKeyDown("s") then
		dist = 5 * delta
	end

	if keyboard:IsKeyDown("a") then
		strafe = -4 * delta
	end
	if keyboard:IsKeyDown("d") then
		strafe = 4 * delta
	end
	
	if keyboard:IsKeyDown(256) then
		window:Close()
	end

	
	local fwd = cam:GetLocalTransform():GetForwardVector()
	local right = cam:GetLocalTransform():GetRightVector()
	cam:SetPosition(cam:GetPosition() + (fwd * dist) + (right * strafe))
	cam:SetRotation(rot)
end

TestApp:Main()