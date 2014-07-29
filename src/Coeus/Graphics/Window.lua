local Coeus = (...)
local oop = Coeus.Utility.OOP
local GLFW = Coeus.Bindings.GLFW
local OpenGL = Coeus.Bindings.OpenGL
local ffi = require("ffi")

local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL

local Event = Coeus.Event

local Window = oop:Class() {
	title 	= "Coeus Window",

	x = 0,
	y = 0,

	width 	= 640,
	height 	= 480,

	fullscreen 	= false,
	resizable 	= false,
	monitor 	= false,

	handle = false,

	Resized 	= Event:New(),
	Moved 		= Event:New(),
	Closed		= Event:New()
}

function Window:_new(title, width, height, fullscreen, resizable, monitor)
	self.width = width or self.width
	self.height = height or self.height

	self.title = title or self.title
	self.fullscreen = fullscreen or self.fullscreen

	local monitorobj

	if monitor then
		local count = ffi.new("int[1]")
		local monitors = glfw.GetMonitors(count)

		if (monitor <= count[0]) then
			monitorobj = monitors[monitor - 1]
		else
			print("Monitor cannot be greater than the number of connected monitors!")
			return nil
		end
	else
		monitorobj = glfw.GetPrimaryMonitor()
	end

	glfw.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
	glfw.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL.TRUE)
	glfw.WindowHint(GLFW.OPENGL_DEBUG_CONTEXT, GL.TRUE)

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
	end)
	glfw.SetWindowCloseCallback(self.handle, function(handle)
		self.Closed:Fire()
	end)
	glfw.SetWindowPosCallback(self.handle, function(handle, x, y)
		self.Moved:Fire(x, y)
		self.x = x
		self.y = y
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

	glfw.SwapInterval(1)

end

function Window:Use()
	glfw.MakeContextCurrent(self.handle)
	gl.Viewport(0, 0, self.width, self.height)
end

function Window:GetSize()
	return self.width, self.height
end

function Window:GetPosition()
	return self.x, self.y
end

function Window:SetSize(width, height)
	glfw.SetWindowSize(self.handle, width, height)
end

function Window:SetPosition(x, y)
	glfw.SetWindowPos(self.handle, x, y)
end

function Window:HasFocus()
	return glfw.GetWindowAttrib(self.handle, GLFW.FOCUSED) == 1
end

function Window:IsMinimized()
	return glfw.GetWindowAttrib(self.handle, GLFW.ICONIFIED) == 1
end

function Window:SetTitle(title)
	self.title = title

	glfw.SetWindowTitle(self.handle, title)
end

function Window:Close()
	glfw.SetWindowShouldClose(self.handle, 1)
end

return Window