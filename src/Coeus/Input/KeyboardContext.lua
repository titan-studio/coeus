--[[
	Keyboard Input Context

	Allows managing of keyboard input in a given window.
]]

local Coeus = (...)

local OOP = Coeus.Utility.OOP
local Event = Coeus.Utility.Event

local GLFW = Coeus.Bindings.GLFW
local glfw = GLFW.glfw
GLFW = GLFW.GLFW

local KeyboardContext = OOP:Class()
	:Members {
		keys = {},

		KeyDown = Event:New(),
		KeyUp = Event:New(),

		TextInput = Event:New()
	}

--[[
	Builds a new KeyboardContext for a given window.
]]
function KeyboardContext:_new(window)
	glfw.SetKeyCallback(window.handle, function(handle, key, scancode, action, mod)
		if (action == GLFW.PRESS) then
			self.keys[key] = true
			self.KeyDown:Fire(key)
		elseif (action == GLFW.RELEASE) then
			self.keys[key] = false
			self.KeyUp:Fire(key)
		end
	end)

	glfw.SetCharCallback(window.handle, function(handle, unicode)
		self.TextInput:Fire(unicode)
	end)
end

--[[
	Returns whether the requested key is currently pressed.
]]
function KeyboardContext:IsKeyDown(key)
	if (type(key) == "string") then
		key = key:upper()
		key = string.byte(key)
	end

	return not not self.keys[key]
end

return KeyboardContext