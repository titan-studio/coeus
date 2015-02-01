local Coeus = (...)
local ffi = require("ffi")

local OOP = Coeus.Graphite.OOP
local GLFW = Coeus.Bindings.GLFW
local OpenGL = Coeus.Bindings.OpenGL

local KeyboardContext = Coeus.Input.KeyboardContext
local MouseContext = Coeus.Input.MouseContext
local GraphicsContext = Coeus.Graphics.GraphicsContext
local Viewport = Coeus.Graphics.Viewport

local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL

local Event = Coeus.Utility.Event

local BaseWindow = OOP:Class() 
	:Members {
		MainViewport = false,

		Keyboard = false,
		Mouse = false,
		Graphics = false,
		Application = false,

		IsClosed = false,

		ClearColor = Coeus.Graphics.Color:New(),

		title = "Coeus Window",

		x = 0,
		y = 0,

		width = 640,
		height = 480,

		fullscreen = false,
		resizable = false,
		monitor = false,
		vsync_enabled = false,

		handle = false,

		Resized = Event:New(),
		Moved = Event:New(),
		Closed = Event:New(),
		
		FocusGained = Event:New(),
		FocusLost = Event:New(),

		Minimized = Event:New(),
		Restored = Event:New()
	}

function BaseWindow:_new(title, width, height, mode)
	self.width = width or self.width
	self.height = height or self.height
	self.title = title or self.title

	self.fullscreen = mode and mode.fullscreen or self.fullscreen

	local monitor = mode and mode.monitor or self.mode
	local resizable = mode and mode.resizable or self.resizable
	local vsync_enabled = mode and mode.vsync or self.vsync

	

	self:SetVSyncEnabled(self.vsync_enabled)

	self.Keyboard = KeyboardContext:New(self)
	self.Mouse = MouseContext:New(self)
	self.Graphics = GraphicsContext:New(self)
	
	self.MainViewport = Viewport:New(0, 0, self.width, self.height)
	self.MainViewport.Window = self
end

function Window:Use()
	glfw.MakeContextCurrent(self.handle)
	gl.Viewport(0, 0, self.width, self.height)
end

function Window:GetSize()
	return self.width, self.height
end
function Window:SetSize(width, height)
	glfw.SetWindowSize(self.handle, width, height)
end

function Window:GetPosition()
	return self.x, self.y
end
function Window:SetPosition(x, y)
	glfw.SetWindowPos(self.handle, x, y)
end

function Window:GetVSyncEnabled()
	return self.vsync_enabled
end
function Window:SetVSyncEnabled(value)
	local old_handle = glfw.GetCurrentContext()

	glfw.MakeContextCurrent(self.handle)
	glfw.SwapInterval(value and 1 or 0)
	glfw.MakeContextCurrent(old_handle)

	self.vsync_enabled = not not value
end

function Window:GetTitle(title)
	return self.title
end
function Window:SetTitle(title)
	self.title = title

	glfw.SetWindowTitle(self.handle, title)
end

function Window:HasFocus()
	return glfw.GetWindowAttrib(self.handle, GLFW.FOCUSED) == 1
end

function Window:IsMinimized()
	return glfw.GetWindowAttrib(self.handle, GLFW.ICONIFIED) == 1
end

function Window:IsClosing()
	return glfw.WindowShouldClose(self.handle) ~= 0
end
function Window:Close()
	glfw.SetWindowShouldClose(self.handle, 1)
end

function Window:PollEvents()
	glfw.PollEvents()
end
function Window:WaitEvents()
	glfw.WaitEvents()
end

function Window:Update(dt)
	self:PollEvents()
	self.Mouse:Update(dt)
end

function Window:PreRender()
	self:Use()
	gl.ClearDepth(1.0)
	gl.ClearColor(self.ClearColor.Red, self.ClearColor.Green, self.ClearColor.Blue, self.ClearColor.Alpha)
	gl.Clear(bit.bor(tonumber(GL.COLOR_BUFFER_BIT), tonumber(GL.DEPTH_BUFFER_BIT)))
end

function Window:PostRender()
	glfw.SwapBuffers(self.handle)
end

function Window:Render()
	
end


return http://kansascity.craigslist.org/cto/4861559580.html