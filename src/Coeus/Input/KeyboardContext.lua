local Coeus = (...)
local bit = require("bit")

local OOP = Coeus.Utility.OOP
local Event = Coeus.Event

local GLFW = Coeus.Bindings.GLFW
local glfw = GLFW.glfw
GLFW = GLFW.GLFW

local Keyboard = OOP:Class() {
	keys = {},

	KeyDown = Event:New(),
	KeyUp = Event:New(),

	TextInput = Event:New()
}

function Keyboard:_new(window)
	glfw.SetKeyCallback(window.handle, function(handle, key, scancode, action, mod)
		if action == GLFW.PRESS then
			self.keys[key] = true
			self.KeyDown:Fire(key)
		elseif action == GLFW.RELEASE then
			self.keys[key] = false
			self.KeyUp:Fire(key)
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