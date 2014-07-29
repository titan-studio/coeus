local Coeus 	= (...)
local oop 		= Coeus.Utility.OOP 
local bit		= require('bit')
local Event		= Coeus.Event
local ffi		= require('ffi')

local OpenGL	= Coeus.Bindings.OpenGL
local GL 		= OpenGL.GL
local GLFW 		= Coeus.Bindings.GLFW
local glfw 		= GLFW.glfw
	  GLFW 		= GLFW.GLFW

local Mouse = oop:Class() {
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

	ButtonDown 	= Event:New(),
	ButtonUp	= Event:New()
}

function Mouse:_new(window)
	self.window = window

	glfw.SetCursorEnterCallback(self.window.handle, function(handle, entered)
		if entered == GL.TRUE then
			self.mouse_in = true
		else
			self.mouse_in = false
		end
	end)
	glfw.SetMouseButtonCallback(self.window.handle, function(handle, button, action, mod)
		local modifiers = {
			shift = false,
			alt = false,
			ctrl = false,
			super = false
		}
		modifiers.shift = false
		if bit.band(mod, GLFW.MOD_SHIFT) == GLFW.MOD_SHIFT then
			modifiers.shift = true
		end

		modifiers.alt = false
		if bit.band(mod, GLFW.MOD_ALT) == GLFW.MOD_ALT then
			modifiers.alt = true
		end

		modifiers.ctrl = false
		if bit.band(mod, GLFW.MOD_CONTROL) == GLFW.MOD_CONTROL then
			modifiers.ctrl = true
		end

		modifiers.super = false
		if bit.band(mod, GLFW.MOD_SUPER) == GLFW.MOD_SUPER then
			modifiers.super = true
		end

		if action == GLFW.PRESS then
			self.buttons[button+1] = true
			self.ButtonDown:Fire(button+1, modifiers)
		else
			self.buttons[button+1] = false
			self.ButtonUp:Fire(button+1, modifiers)
		end
	end)
end

function Mouse:IsButtonDown(button)
	return self.buttons[button] or false
end

function Mouse:GetPosition()
	return math.floor(self.x), math.floor(self.y)
end

function Mouse:SetPosition(x, y)
	glfw.SetCursorPos(self.window.handle, x, y)
	self.x = x
	self.y = y
end

function Mouse:GetDelta()
	return self.delta_x, self.delta_y
end

function Mouse:SetLocked(locked)
	self.lock = locked
	if locked then
		self.prelock_x = self.x
		self.prelock_y = self.y
	else
		self:SetPosition(self.prelock_x, self.prelock_y)
	end
end
function Mouse:IsLocked()
	return self.lock
end

function Mouse:Update()
	local xp, yp = ffi.new('double[1]'), ffi.new('double[1]')
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

return Mouse