--[[
	Sound Emitter

	Defines a speaker in space that can emit sounds.
]]

local C = (...)
local Coeus = C:Get("Coeus")
local ffi = require("ffi")
local OOP = Coeus.Utility.OOP
local OpenAL = Coeus.Bindings.OpenAL
local SoundLoader = Coeus.Asset.Sound.SoundLoader
local SoundData = Coeus.Asset.Sound.SoundData

local SoundEmitter = OOP:Class() {
	data_source = nil,
	al_source = nil,
	looping = false,
	pitch = 1,
	position = {0, 0, 0},
	velocity = {0, 0, 0},
	loader = nil --By default, use the global SoundLoader
}

--[[
	Creates a new SoundEmitter.
	data_source can be a string, SoundData, or SoundStream.
	If data_source is a string, the sound is loaded from the filesystem,
	producing either a SoundData or SoundStream, depending on whether static is
	true.
]]
function SoundEmitter:_new(data_source, static)
	local p_source = ffi.new("int[1]")
	OpenAL.alGenSources(1, p_source)
	self.al_source = p_source[0]

	local typeof = type(data_source)

	if (typeof == "string") then
		data_source = SoundLoader:Load(data_source, static)
		typeof = type(data_source)
	end

	if (typeof == "userdata") then
		if (data_source.Is[SoundData]) then
			OpenAL.alSourcei(self.al_source, OpenAL.AL_BUFFER, data_source:GetALBuffer())
			OpenAL.alSourcef(self.al_source, OpenAL.AL_PITCH, 1)
			OpenAL.alSourcef(self.al_source, OpenAL.AL_GAIN, 1)

			local SourcePos = ffi.new("ALfloat[3]", {0, 0, 0})
			local SourceVel = ffi.new("ALfloat[3]", {0, 0, 0})
			OpenAL.alSourcefv(self.al_source, OpenAL.AL_POSITION, SourcePos)
			OpenAL.alSourcefv(self.al_source, OpenAL.AL_VELOCITY, SourceVel)
		elseif (data_source.Is[SoundStream]) then
			--todo: handle sound stream
		else
			error("Could not create SoundEmitter: invalid argument #1: does not derive from SoundData or SoundStream!")
		end
	else
		error("Could not create SoundEmitter: invalid argument #1 of type '" .. typeof .. "'")
	end
end

--[[
	Returns whether the SoundEmitter has stopped playing.
]]
function SoundEmitter:IsStopped()
	local pstate = ffi.new("ALenum[1]")
	OpenAL.alGetSourcei(self.al_source, OpenAL.AL_SOURCE_STATE, pstate)
	return (pstate[0] == OpenAL.AL_STOPPED)
end

--[[
	Returns whether the SoundEmitter is currently set to loop
]]
function SoundEmitter:GetLooping()
	return self.looping
end

--[[
	Sets whether or not the SoundEmitter should loop.
]]
function SoundEmitter:SetLooping(looping)
	self.looping = looping
	OpenAL.alSourcei(self.al_source, OpenAL.AL_LOOPING, looping and OpenAL.AL_TRUE or OpenAL.AL_FALSE)
end

--[[
	Returns the pitch offset of the current SoundEmitter.
]]
function SoundEmitter:GetPitch()
	return self.pitch
end

--[[
	Sets the pitch offset of the current SoundEmitter.
]]
function SoundEmitter:SetPitch(pitch)
	OpenAL.alSourcef(self.al_source, OpenAL.AL_PITCH, pitch)
end

--[[
	Returns the position in 3D space the SoundEmitter occupies.
]]
function SoundEmitter:GetPosition()
	return unpack(self.position)
end

--[[
	Sets the position of the SoundEmitter in 3D space.
]]
function SoundEmitter:SetPosition(x, y, z)
	self.position = {x, y, z}
end

--[[
	Gets the velocity in 3D space of the SoundEmitter.
]]
function SoundEmitter:GetVelocity()
	return unpack(self.velocity)
end

--[[
	Sets the velocity in 3D space of the SoundEmitter.
]]
function SoundEmitter:SetVelocity(x, y, z)
	self.velocity = {x, y, z}
end

--[[
	Plays the audio the SoundEmitter is set up to use.
]]
function SoundEmitter:Play()
	OpenAL.alSourcePlay(self.al_source)
end

--[[
	Pauses the audio the SoundEmitter is using.
]]
function SoundEmitter:Pause()
	OpenAL.alSourcePause(self.al_source)
end

--[[
	Stops the audio and seeks back to the beginning of the track.
]]
function SoundEmitter:Stop()
	OpenAL.alSourceStop(self.al_source)
end

return SoundEmitter