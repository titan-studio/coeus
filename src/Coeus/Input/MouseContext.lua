local C = (...)
local Coeus = C:Get("Coeus")
local ffi = require("ffi")

local OOP = Coeus.Utility.OOP
local Event = Coeus.Utility.Event

local OpenGL = Coeus.Bindings.OpenGL
local GL = OpenGL.GL
local GLFW = Coeus.Bindings.GLFW
local glfw = GLFW.glfw
GLFW = GLFW.GLFW

local MouseContext = OOP:Class() {
	window = false,
	buttons = {},

	x = 0,
	y = 0,
	xp = ffi.new("double[1]"),
	yp = ffi.new("double[1]"),
	last_x = 0,
	last_y = 0,

	prelock_x = 0,
	prelock_y = 0,
	lock = false,
	mouse_in = false,

	delta_x = 0,
	delta_y = 0,

	double_click_time = 0.250,

	ButtonDown = Event:New(),
	ButtonUp = Event:New(),
	EnterWindow = Event:New(),
	LeaveWindow = Event:New(),

	Buttons = {
		Left = 0,
		Right = 2,
		Middle = 1
	}
}

--[[
	Creates a new MouseContext for the given window.
]]
function MouseContext:_new(window)
	self.window = window

	glfw.SetCursorEnterCallback(self.window.handle, function(handle, entered)
		if entered == GL.TRUE then
			self.mouse_in = true
			self.EnterWindow:Fire()
		else
			self.mouse_in = false
			self.LeaveWindow:Fire()
		end
	end)

	glfw.SetMouseButtonCallback(self.window.handle, function(handle, button, action, mod)
		button = button + 1

		if action == GLFW.PRESS then
			self.buttons[button] = true
			self.ButtonDown:Fire(button, modifiers)
		else
			self.buttons[button] = false
			self.ButtonUp:Fire(button, modifiers)
		end
	end)
end

--[[
	Returns whether the specified mouse button is currently pressed.
]]
function MouseContext:IsButtonDown(button)
	return self.buttons[button] or false
end

--[[
	Returns the current position of the mouse cursor relative to the upper-left
	corner of the drawable window area.
]]
function MouseContext:GetPosition()
	return math.floor(self.x), math.floor(self.y)
end

--[[
	Sets the position of the mouse cursor relative to the upper-left corner of
	the drawable window area.
]]
function MouseContext:SetPosition(x, y)
	glfw.SetCursorPos(self.window.handle, x, y)
	self.x = x
	self.y = y
end

--[[
	Returns the change in mouse position since the last MouseContext Update.
]]
function MouseContext:GetDelta()
	return self.delta_x, self.delta_y
end

--[[
	Sets whether the mouse should be locked to the confines of the window.
]]
function MouseContext:SetLocked(locked)
	self.lock = locked
	if locked then
		self.prelock_x = self.x
		self.prelock_y = self.y
	else
		self:SetPosition(self.prelock_x, self.prelock_y)
	end
end

--[[
	Returns whether the mouse is currently locked within the window.
]]
function MouseContext:GetLocked()
	return self.lock
end

--[[
	Updates the MouseContext and pulls new data from GLFW.
]]
function MouseContext:Update()
	glfw.GetCursorPos(self.window.handle, self.xp, self.yp)
	self.x, self.y = self.xp[0], self.yp[0]

	self.delta_x = self.x - self.last_x
	self.delta_y = self.y - self.last_y
	self.last_x = self.x
	self.last_y = self.y

	if (self.lock and self.window:HasFocus()) then
		glfw.SetInputMode(self.window.handle, GLFW.CURSOR, GLFW.CURSOR_DISABLED)
	else
		glfw.SetInputMode(self.window.handle, GLFW.CURSOR, GLFW.CURSOR_NORMAL)
	end

	if (self.lock and not self.window:HasFocus()) then
		self.delta_x = 0
		self.delta_y = 0
	end
end

return MouseContext