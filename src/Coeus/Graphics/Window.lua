local C = (...)
local Coeus = C:Get("Coeus")
local ffi = require("ffi")

local OOP = Coeus.Utility.OOP
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

local Window = OOP:Class() {
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

	MainViewport = false,

	Keyboard = false,
	Mouse = false,
	Graphics = false,
	Application = false,

	IsClosed = false,

	ClearColor = Coeus.Graphics.Color:New(),

	Resized 	= Event:New(),
	Moved 		= Event:New(),
	Closed 		= Event:New(),
	
	FocusGained = Event:New(),
	FocusLost 	= Event:New(),

	Minimized 	= Event:New(),
	Restored	= Event:New()
}

function Window:_new(title, width, height, mode)
	self.width = width or self.width
	self.height = height or self.height
	self.title = title or self.title

	self.fullscreen = mode and mode.fullscreen or self.fullscreen

	local monitor = mode and mode.monitor or self.mode
	local resizable = mode and mode.resizable or self.resizable
	local vsync_enabled = mode and mode.vsync or self.vsync

	local monitorobj

	if monitor then
		local count = ffi.new("int[1]")
		local monitors = glfw.GetMonitors(count)

		if (monitor <= count[0]) then
			monitorobj = monitors[monitor - 1]
		else
			print("Monitor cannot be greater than the number of connected monitors!")
			print("Reverting to primary monitor...")
			monitorobj = glfw.GetPrimaryMonitor()
		end
	else
		monitorobj = glfw.GetPrimaryMonitor()
	end

	glfw.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
	glfw.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL.TRUE)
	glfw.WindowHint(GLFW.OPENGL_DEBUG_CONTEXT, GL.TRUE)

	glfw.WindowHint(GLFW.DEPTH_BITS, 32)

	glfw.WindowHint(GLFW.RESIZABLE, resizable and GL.TRUE or GL.FALSE)

	local mode = glfw.GetVideoMode(monitorobj)[0]
	width = width or mode.width
	height = height or mode.height

	local window
	if fullscreen then
		if fullscreen == "desktop" then
			glfw.WindowHint(GLFW.DECORATED, GL.FALSE)

			window = glfw.CreateWindow(width, height, title, nil, nil)
		else
			window = glfw.CreateWindow(width, height, title, monitorobj, nil)
		end
	else
		window = glfw.CreateWindow(width, height, title, nil, nil)
	end

	if window == nil then
		error("GLFW failed to create a window!")
	end

	self.handle = window
	glfw.SetWindowSizeCallback(self.handle, function(handle, width, height)
		self.Resized:Fire(width, height)
		self.width = width
		self.height = height

		if self.MainViewport then
			self.MainViewport:Resize(self.width, self.height)
		end
	end)
	glfw.SetWindowCloseCallback(self.handle, function(handle)
		self.Closed:Fire()
		glfw.DestroyWindow(self.handle)
		self.IsClosed = true
	end)
	glfw.SetWindowPosCallback(self.handle, function(handle, x, y)
		self.Moved:Fire(x, y)
		self.x = x
		self.y = y
	end)
	glfw.SetWindowFocusCallback(self.handle, function(handle, focus)
		if focus == GL.TRUE then
			self.FocusGained:Fire()
		else
			self.FocusLost:Fire()
		end
	end)
	glfw.SetWindowIconifyCallback(self.handle, function(handle, iconify)
		if iconify == GL.TRUE then
			self.Minimized:Fire()
		else
			self.Restored:Fire()
		end
	end)

	local xp, yp = ffi.new("int[1]"), ffi.new("int[1]")
	glfw.GetWindowPos(self.handle, xp, yp)
	self.x = xp[0]
	self.y = yp[0]
	glfw.GetWindowSize(self.handle, xp, yp)
	self.width = xp[0]
	self.height = yp[0]

	self:Use()
	gl.Enable(GL.DEPTH_TEST)
	gl.DepthFunc(GL.LEQUAL)

	gl.FrontFace(GL.CCW)
	gl.Enable(GL.CULL_FACE)
	gl.CullFace(GL.BACK)
	gl.DepthMask(GL.TRUE)
	gl.Enable(GL.BLEND)
	

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

function Window:Update(dt)
	self:PollEvents()
	self.Mouse:Update(dt)
end

return Window