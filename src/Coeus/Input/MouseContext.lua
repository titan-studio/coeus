local Coeus = (...)
local ffi = require('ffi')
local bit = require('bit')

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
	LeaveWindow = Event:New()
}
MouseContext.Buttons = {
	Left = 0,
	Right = 2,
	Middle = 1
}

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

function MouseContext:IsButtonDown(button)
	return self.buttons[button] or false
end

function MouseContext:GetPosition()
	return math.floor(self.x), math.floor(self.y)
end

function MouseContext:SetPosition(x, y)
	glfw.SetCursorPos(self.window.handle, x, y)
	self.x = x
	self.y = y
end

function MouseContext:GetDelta()
	return self.delta_x, self.delta_y
end

function MouseContext:SetLocked(locked)
	self.lock = locked
	if locked then
		self.prelock_x = self.x
		self.prelock_y = self.y
	else
		self:SetPosition(self.prelock_x, self.prelock_y)
	end
end
function MouseContext:IsLocked()
	return self.lock
end

function MouseContext:Update()
	local xp, yp = ffi.new("double[1]"), ffi.new("double[1]")
	glfw.GetCursorPos(self.window.handle, xp, yp)
	self.x, self.y = xp[0], yp[0]

	self.delta_x = self.x - self.last_x
	self.delta_y = self.y - self.last_y
	self.last_x = self.x
	self.last_y = self.y

	if self.lock and self.window:HasFocus() then
		glfw.SetInputMode(self.window.handle, GLFW.CURSOR, GLFW.CURSOR_DISABLED)
	else
		glfw.SetInputMode(self.window.handle, GLFW.CURSOR, GLFW.CURSOR_NORMAL)
	end

	if self.lock and not self.window:HasFocus() then
		self.delta_x = 0
		self.delta_y = 0
	end
end

return MouseContext