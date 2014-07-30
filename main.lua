local Coeus = require("src.Coeus")
local oop = Coeus.Utility.OOP
local Window = Coeus.Graphics.Window
local Shader = Coeus.Graphics.Shader

local Shader = Coeus.Graphics.Shader
local Mesh = Coeus.Graphics.Mesh

local Vector3 = Coeus.Math.Vector3
local Matrix4 = Coeus.Math.Matrix4
local Quaternion = Coeus.Math.Quaternion

local OpenGL = Coeus.Bindings.OpenGL
local GLFW = Coeus.Bindings.GLFW
local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL

local window = Window:New("Coeus", 1280, 720, {fullscreen = false, resizable = true, vsync = true})
local TestApp = Coeus.Application:New(window)

local Entity = Coeus.Entity.Entity
local Camera = Coeus.Graphics.Camera

local cam = Entity:New()
cam:SetPosition(0, 0, 10)
cam:AddComponent(Camera:New(window))
cam:BuildTransform()
local view = cam:GetComponent(Camera):GetViewTransform()

local keyboard = window.Keyboard
local mouse = window.Mouse

TestApp.shader = false
TestApp.mesh = false

function TestApp:Initialize()
	self.shader = Shader:New(Coeus.Graphics.GraphicsContext:New(), [[
	#version 330
	layout(location=0) in vec3 position;
	layout(location=1) in vec2 texcoord_;
	layout(location=2) in vec3 normal;

	uniform mat4 mvp;

	out vec2 texcoord;

	void main() {
		gl_Position = mvp * vec4(position, 1.0);
		texcoord = texcoord_;
	}
	]],[[
	#version 330
	
	layout(location=0) out vec4 FragColor;

	uniform sampler2D tex;

	in vec2 texcoord;

	void main() {
		FragColor = texture2D(tex, texcoord);
	}
	]])

	self.texture = Coeus.Utility.PNGLoader:New("test.png"):GetTexture()
	self.mesh = Coeus.Utility.OBJLoader:New("test.obj"):GetMesh()

	mouse:SetLocked(true)
end

local des_rot = Quaternion:New()
function TestApp:Render()
	local delta = self.Timer:GetDelta()

	window:SetTitle("Coeus (FPS: " .. self.Timer:GetFPS() .. ")")

	mouse:Update()
	local dx, dy = mouse:GetDelta()
	local rot = cam:GetRotation()
	local yaw = Quaternion.FromAngleAxis(dx * 0.005, Vector3:New(0, 1, 0))
	des_rot = yaw * des_rot
	rot = Quaternion.Slerp(rot, des_rot, 0.5)
	cam:SetRotation(rot)

	self.shader:Use()
	
	local model_trans = Matrix4:New()--Matrix4.GetRotationY(math.rad(os.clock() * 100))
	--model_trans = Matrix4.GetTranslation(Vector3:New(1.5, 0, 0)) * model_trans

	local view = cam:GetComponent(Camera):GetViewTransform()
	local proj = cam:GetComponent(Camera):GetProjectionTransform()
	local mvp = proj * view * model_trans

	self.shader:Send("mvp", mvp)
	self.shader:Send("tex", self.texture)
	self.mesh:Render()

	local fwd = cam:GetLocalTransform():GetForwardVector()
	local right = cam:GetLocalTransform():GetRightVector()
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
	cam:SetPosition(cam:GetPosition() + (fwd * dist) + (right * strafe))
end

TestApp:Main()