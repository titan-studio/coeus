--[[
Initialization method for the audio system.
Creates an OpenAL context and device.
]]

local Coeus = ...
local OpenAL = Coeus.Bindings.OpenAL

return function()
	local aldevice = OpenAL.alcOpenDevice(nil)
	local alcontext = OpenAL.alcCreateContext(aldevice, nil)
	OpenAL.alcMakeContextCurrent(alcontext)

	return alcontext
end