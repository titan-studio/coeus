local Coeus = require("src.Coeus")
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

local window = Window:New("Coeus", 1280, 720, {fullscreen = false, resizable = true})
local app = {}

local Entity = Coeus.Entity.Entity
local Camera = Coeus.Graphics.Camera

local cam = Entity:New()
cam:SetPosition(0, 0, 10)
cam:AddComponent(Camera:New(window))
cam:BuildTransform()
local view = cam:GetComponent(Camera):GetViewTransform()

local keyboard = Coeus.Input.KeyboardContext:New(window)
local mouse = Coeus.Input.MouseContext:New(window)

function app:Load()
	self.shader = Shader:New([[
	#version 330
	layout(location=0) in vec3 position;
	layout(location=2) in vec3 normal;

	uniform mat4 mvp;

	void main() {
		gl_Position = mvp * vec4(position, 1.0);
	}
	]],[[
	#version 330
	layout(location=0) out vec4 FragColor;


	void main() {
		float mod = gl_FragCoord.z;
		FragColor = vec4(mod, mod, mod, 1.0);
	}
	]])

	local vertex_data = {
		1.0, 1.0,-1.0,
	   -1.0, 1.0,-1.0,
	   -1.0, 1.0, 1.0,
	    1.0, 1.0, 1.0,
	    1.0,-1.0,-1.0,
	   -1.0,-1.0,-1.0,
	   -1.0,-1.0, 1.0,
	    1.0,-1.0, 1.0
	}
	local index_data = {
		0,1,2,
		0,2,3,
		0,4,5,
		0,5,1,
		1,5,6,
		1,6,2,
		2,6,7,
		2,7,3,
		3,7,4,
		3,4,0,
		4,7,6,
		4,6,5
	}
	self.mesh = Mesh:New()
	self.mesh:SetData(vertex_data, index_data, Mesh.DataFormat.Position)

	self.mesh = Coeus.Utility.OBJLoader:New("test.obj"):GetMesh()

	mouse:SetLocked(true)
end

local des_rot = Quaternion:New()
function app:Render()
	window:SetTitle("Coeus (FPS: " .. Coeus.Timing.GetFPS() .. ")")

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

	self.shader:Send('mvp', mvp)
	self.mesh:Render()

	local fwd = cam:GetLocalTransform():GetForwardVector()
	local right = cam:GetLocalTransform():GetRightVector()
	local dist = 0
	local strafe = 0
	if keyboard:IsKeyDown('w') then
		dist = -5 * Coeus.Timing.GetDelta()
	end
	if keyboard:IsKeyDown('s') then
		dist = 5 * Coeus.Timing.GetDelta()
	end
	if keyboard:IsKeyDown('a') then
		strafe = -4 * Coeus.Timing.GetDelta()
	end
	if keyboard:IsKeyDown('d') then
		strafe = 4 * Coeus.Timing.GetDelta()
	end
	if keyboard:IsKeyDown(256) then
		window:Close()
	end
	cam:SetPosition(cam:GetPosition() + (fwd * dist) + (right * strafe))
end

Coeus.Main(window, app)