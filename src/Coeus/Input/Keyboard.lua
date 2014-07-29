local Coeus 	= (...)
local oop 		= Coeus.Utility.OOP 
local bit		= require('bit')
local Event		= Coeus.Event

local GLFW 		= Coeus.Bindings.GLFW
local glfw 		= GLFW.glfw
	  GLFW 		= GLFW.GLFW

local Keyboard = oop:Class() {
	keys = {},

	KeyDown = Event:New(),
	KeyUp	= Event:New(),

	TextInput	= Event:New()
}

function Keyboard:_new(window)
	glfw.SetKeyCallback(window.handle, function(handle, key, scancode, action, mod)
		if action == GLFW.PRESS then
			self.keys[key] = true
		elseif action == GLFW.RELEASE then
			self.keys[key] = false
		end
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

		if self.keys[key] then
			self.KeyDown:Fire(key, modifiers)
		else
			self.KeyUp:Fire(key, modifiers)
		end
	end)
	glfw.SetCharCallback(window.handle, function(handle, unicode)
		self.TextInput:Fire(unicode)
	end)
end

function Keyboard:IsKeyDown(key)
	if type(key) == 'string' then
		key = key:upper()
		key = string.byte(key)
	end
	return self.keys[key] or false
end

return Keyboard