package.path = package.path .. ";?/init.lua"

local Coeus = require("src.Coeus")
local ffi = require("ffi")

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
local SoundLoader = Coeus.Asset.Sound.SoundLoader
local SoundEmitter = Coeus.Sound.SoundEmitter
local SoundData = Coeus.Asset.Sound.SoundData

local OpenAL = Coeus.Bindings.OpenAL

local PlaneMesh = Coeus.Graphics.Debug.PlaneMesh

local Framebuffer = Coeus.Graphics.Framebuffer
local Texture = Coeus.Graphics.Texture

local DirectionalLight = Coeus.Graphics.Lighting.DirectionalLight
local PointLight = Coeus.Graphics.Lighting.PointLight

local fb = nil
local light_buffer = nil

local dir_light = nil
local point_light = nil
local point_mesh = nil
local composite = nil

local aldevice = OpenAL.alcOpenDevice(nil)
local alcontext = OpenAL.alcCreateContext(aldevice, nil)
OpenAL.alcMakeContextCurrent(alcontext)

--local testpng, err = Coeus.Asset.Image.Formats.PNG:Load("assets/test.png")
--local testpng, err = Coeus.Asset.Image.ImageLoader:Load("assets/test.png")
--print(testpng.Width, err)

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

	local plane = Entity:New() plane.name = "plane"
	plane:SetPosition(0, 0, 0)
	
	
	scene:AddEntity(plane)
	local plane_render = MeshRenderer:New(window.Graphics)
	plane_render.Mesh = PlaneMesh:New(30, 30, 5, 5)
	plane:AddComponent(plane_render)

	local light_ent = Entity:New()
	scene:AddEntity(light_ent)
	local light_comp = DirectionalLight:New(window.Graphics)
	light_ent:AddComponent(light_comp)
	light_comp.LightDirection = Vector3:New(1, 1, 0)
	light_comp.LightColor = Vector3:New(0.5, 0.5, 0.5)
	local light_ent2 = Entity:New()
	scene:AddEntity(light_ent2)
	local light_comp2 = DirectionalLight:New(window.Graphics)
	light_ent2:AddComponent(light_comp2)
	light_comp2.LightDirection = Vector3:New(-1, -1, 0)
	light_comp2.LightColor = Vector3:New(0.3, 0.0, 0.0)

	self.plights = {}
	for i = 1, 10 do 
		local point_ent = Entity:New()
		scene:AddEntity(point_ent)
		point_ent:SetPosition(0, 1, 0)
		local point_comp = PointLight:New(window.Graphics)
		point_ent:AddComponent(point_comp)
		point_comp.LightColor = Vector3:New(math.random(), math.random(), math.random())
		point_ent.ang_offset = (math.pi*2) / ((i-1)/9)
		table.insert(self.plights, point_ent)
	end


	local test_obj = Entity:New()
	test_obj.name = "test_obj"
	scene:AddEntity(test_obj)
	test_obj:SetPosition(0, 2, 0)
	plane:SetPosition(0, 0, 0)
	local mesh_renderer = MeshRenderer:New(window.Graphics)
	mesh_renderer.Mesh = Coeus.Utility.OBJLoader:New("assets/test.obj"):GetMesh()
	test_obj:AddComponent(mesh_renderer)
	local material = Material:New(window.Graphics)
	material.Shader = window.Graphics.Shaders.RenderGeometry
	local test_tex = Texture:New(Coeus.Asset.Image.ImageLoader:Load("assets/test.png"))
	material.Textures.ModelTexture = test_tex
	test_obj:AddComponent(material)


	local mat2 = Material:New(window.Graphics)
	mat2.Shader = material.Shader

	local plane_data = Coeus.Asset.Image.ImageData:New()
	plane_data.Width = 100
	plane_data.Height = 100
	plane_data:Map(function(img_data, x, y, buffer, offset)
		local r, g, b, a = 0, 0, 0, 0

		r = (x / plane_data.Width) * 255
		g = (y / plane_data.Height) * 255
		b = 255
		a = 255

		return r, g, b, a
	end)	
	local plane_tex = Texture:New(plane_data)

	mat2.Textures.ModelTexture = plane_tex


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

	--[[
	local testdata = SoundLoader:Load("assets/test.ogg", true)
	local emitter = SoundEmitter:New(testdata)
	emitter:SetLooping(true)
	emitter:Play()
	]]
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
	--local roll = Quaternion.FromAngleAxis(self.look_roll, Vector3:New(0, 0, 1))
	des_rot = pitch * yaw
	rot = Quaternion.Slerp(rot, des_rot, self.Timer:GetDelta() * 20)

	for i, light in ipairs(self.plights) do
		local ang = light.ang_offset + os.clock()
		light:SetPosition(math.cos(ang) * 4, 0, math.sin(ang) * 4)
	end

	window.Graphics:Render()


	local dist = 0
	local strafe = 0

	if keyboard:IsKeyDown("w") then
		dist = -1
	end
	if keyboard:IsKeyDown("s") then
		dist = 1
	end

	if keyboard:IsKeyDown("a") then
		strafe = -1
	end
	if keyboard:IsKeyDown("d") then
		strafe = 1
	end

	local len = math.sqrt(dist^2 + strafe^2)
	if (len > 0) then
		dist = (dist / len) * 5 * delta
		strafe = (strafe / len) * 5 * delta
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