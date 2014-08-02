local Coeus = require("src.Coeus")

local tests = require("tests")
tests:Init(Coeus)
--print(tests:RunTestFolder("Coeus"))

require("audio_test")

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

	local test_obj = Entity:New()
	scene:AddEntity(test_obj)
	test_obj:SetPosition(0, -3, 0)
	local mesh_renderer = MeshRenderer:New(window.Graphics)
	mesh_renderer.Mesh = Coeus.Utility.OBJLoader:New("test.obj"):GetMesh()
	mesh_renderer.Shader = false
	test_obj:AddComponent(mesh_renderer)
	local material = Material:New(window.Graphics)
	material.Shader = Shader:New(window.Graphics, [[
		#version 330
		layout(location=0) in vec3 position;
		layout(location=1) in vec2 texcoord_;
		layout(location=2) in vec3 normal;

		uniform mat4 ModelViewProjection;

		out vec2 texcoord;

		void main() {
			gl_Position = ModelViewProjection * vec4(position, 1.0);
			texcoord = texcoord_;
		}
		]],[[
		#version 330
		
		layout(location=0) out vec4 FragColor;

		uniform sampler2D tex;

		in vec2 texcoord;

		void main() {
			FragColor = texture(tex, texcoord);
		}
	]])
	material.Textures.tex = Coeus.Utility.PNGLoader:New("test.png"):GetTexture()
	test_obj:AddComponent(material)

	local text = Entity:New()
	text:SetPosition(0, 0, 0)
	scene:AddEntity(text)
	local text_renderer = TextRenderer:New(window.Graphics)
	text_renderer.text = "booty"
	text_renderer.font = Coeus.Graphics.Text.Font:New("Orbitron-Regular.ttf", 100)
	text:SetScale(0.05, 0.05, 0.01)
	text_renderer:RebuildText()
	text:AddComponent(text_renderer)

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
	
	window.Graphics:Render()


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