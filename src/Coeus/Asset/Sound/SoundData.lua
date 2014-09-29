local Coeus = ...
local ffi = require("ffi")
local OpenAL = Coeus.Bindings.OpenAL
local SoundCommon = Coeus.Asset.Sound.Common
local OOP = Coeus.Utility.OOP

local SoundData = OOP:Class(Coeus.Asset.Format) {
	size = 0,
	channels = 0,
	frequency = 0,
	data = nil,
	format = 0,
	channels = 0,
	al_buffer = nil
}

--OpenAL auxiliary stuff, this might cause unnecessary duplicate data
function SoundData:GetALBuffer()
	if (self.al_buffer) then
		return self.al_buffer
	end

	local p_buffer = ffi.new("unsigned int[1]")
	OpenAL.alGenBuffers(1, p_buffer)
	OpenAL.alBufferData(p_buffer[0], SoundCommon.OpenALFormat[self.format], self.data, self.size, self.frequency)
	
	self.al_buffer = p_buffer[0]

	return p_buffer[0]
end

return SoundData