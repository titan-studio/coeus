local Coeus = (...)
local oop = Coeus.Utility.OOP
local GLFW = Coeus.Bindings.GLFW
local OpenGL = Coeus.Bindings.OpenGL

local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL

local Window = oop:class() {
	x 		= 0,
	y 		= 0,

	title 	= "Coeus Window",

	width 	= 640,
	height 	= 480,

	fullscreen 	= false,
	resizable 	= false,
	monitor 	= false,

	handle = false
}

function Window:_new(x, y, title, width, height, fullscreen, resizable, monitor)
	self.x = x or self.x
	self.y = y or self.y
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
	glfw.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
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
		print("GLFW failed to create a window!")
		return nil
	end

	self.handle = window
end

function Window:Use()
	glfw.MakeContextCurrent(self.handle)
end

return Window