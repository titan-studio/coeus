local Coeus = require("src.Coeus")
local Window = Coeus.Graphics.Window
local Shader = Coeus.Graphics.Shader

local Shader = Coeus.Graphics.Shader
local Mesh = Coeus.Graphics.Mesh

local Vector3 = Coeus.Math.Vector3
local Matrix4 = Coeus.Math.Matrix4

local OpenGL = Coeus.Bindings.OpenGL
local GLFW = Coeus.Bindings.GLFW
local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL

local window = Window:New("Coeus", 1280, 720, false, true)
local app = {}

local Entity = Coeus.Entity.Entity
local Camera = Coeus.Graphics.Camera

local cam = Entity:New()
cam:SetPosition(0, 0, 10)
cam:AddComponent(Camera:New(window))
cam:BuildTransform()
local view = cam:GetComponent(Camera):GetViewTransform()
for i=0,15 do print(view.m[i]) end

local CTester = require("tests")
CTester:Init(Coeus)
print(CTester:RunTestFolder("Coeus.Bindings"))

function app:Load()
	self.shader = Shader:New([[
	#version 330
	layout(location=0) in vec4 position;

	uniform mat4 mvp;

	void main() {
		gl_Position = mvp * position;
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

	gl.Enable(GL.CULL_FACE)
	gl.CullFace(GL.BACK)
end

function app:Render()
	window:SetTitle("Coeus (FPS: " .. Coeus.Timing.GetFPS() .. ")")

	self.shader:Use()
	
	local model_trans = Matrix4.GetRotationY(math.rad(os.clock() * 100))
	--model_trans = Matrix4.GetTranslation(Vector3:New(1.5, 0, 0)) * model_trans

	local view = cam:GetComponent(Camera):GetViewTransform()
	local proj = cam:GetComponent(Camera):GetProjectionTransform()
	local mvp = proj * view * model_trans

	self.shader:Send('mvp', mvp)
	self.mesh:Render()

	if glfw.GetKey(window.handle, GLFW.KEY_W) == GLFW.PRESS then
		cam:SetPosition(0, 1.5, cam:GetPosition().z - 5 * Coeus.Timing.GetDelta())
	end
	if glfw.GetKey(window.handle, GLFW.KEY_S) == GLFW.PRESS then
		cam:SetPosition(0, 1.5, cam:GetPosition().z + 5 * Coeus.Timing.GetDelta())
	end
end

Coeus.Main(window, app)