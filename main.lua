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

local CTester = require("tests")
CTester:Init(Coeus)
print(CTester:RunTestFolder("Coeus.Bindings"))

function app:Load()
	self.shader = Shader:New([[
	#version 330
	layout(location=0) in vec4 position;

	uniform mat4 modelview;
	uniform mat4 projection;

	void main() {
		gl_Position = projection * modelview * position;
	}
	]],[[
	#version 330
	layout(location=0) out vec4 FragColor;


	void main() {
		FragColor = vec4(1.0, 1.0, 1.0, 1.0) * gl_FragCoord.z;
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

	local width, height = window:GetSize()
	local aspect = width / height
	local perspective = Matrix4.GetPerspective(90, 1.0, 100.0, aspect)

	local modelview = Matrix4.GetTranslation(Vector3:New(0, 0, -5))
	gl.Enable(GL.CULL_FACE)
	gl.CullFace(GL.BACK)
end

local prev_time = glfw.GetTime()
local x = 0
function app:Render()
	window:SetTitle("Coeus (FPS: " .. Coeus.Timing.GetFPS() .. ")")
	local width, height = window:GetSize()
	local aspect = width / height
	local perspective = Matrix4.GetPerspective(90, 1.0, 100.0, aspect)

	self.shader:Use()
	

	local modelview = Matrix4.GetTranslation(Vector3:New(0, -1.5, -5))
	modelview = modelview:Multiply(Matrix4.GetRotationY(math.rad(os.clock() * 100)), modelview)
	modelview = modelview:Multiply(Matrix4.GetTranslation(Vector3:New(1.5, 0, 0)), modelview)
	
	self.shader:Send('projection', perspective)
	self.shader:Send('modelview', modelview)
	self.mesh:Render()
end

Coeus.Main(window, app)