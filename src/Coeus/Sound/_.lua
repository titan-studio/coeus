--[[
Initialization and termination logic for the audio system.
Creates an OpenAL context and device.
]]

local Coeus = ...
local OpenAL = Coeus.Bindings.OpenAL
local Sound

Sound = {
	aldevice = nil,
	alcontext = nil,

	Initialize = function(self)
		local aldevice = OpenAL.alcOpenDevice(nil)
		local alcontext = OpenAL.alcCreateContext(aldevice, nil)
		OpenAL.alcMakeContextCurrent(alcontext)

		self.aldevice = aldevice
		self.alcontext = alcontext
	end,

	Terminate = function(self)
		OpenAL.alcMakeContextCurrent(nil)
		OpenAL.alcDestroyContext(self.alcontext)
		OpenAL.alcCloseDevice(self.aldevice)
	end
}

Sound:Initialize()

return Sound