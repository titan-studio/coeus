local Coeus = ...
local ffi = require("ffi")
local OOP = Coeus.Utility.OOP
local OpenAL = Coeus.Bindings.OpenAL
local SoundLoader = Coeus.Asset.Sound.SoundLoader
local SoundData = Coeus.Asset.Sound.SoundData
--local SoundStream = Coeus.Asset.Sound.SoundStream

local SoundEmitter = OOP:Class() {
	data_source = nil,
	al_source = nil,
	looping = false,
	pitch = 1,
	position = {0, 0, 0},
	velocity = {0, 0, 0},
	loader = nil --By default, use the global SoundLoader
}

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

function SoundEmitter:IsStopped()
	local pstate = ffi.new("ALenum[1]")
	OpenAL.alGetSourcei(self.al_source, OpenAL.AL_SOURCE_STATE, pstate)
	return (pstate[0] == OpenAL.AL_STOPPED)
end

function SoundEmitter:GetLooping()
	return self.looping
end

function SoundEmitter:SetLooping(looping)
	self.looping = looping
	OpenAL.alSourcei(self.al_source, OpenAL.AL_LOOPING, looping and OpenAL.AL_TRUE or OpenAL.AL_FALSE)
end

function SoundEmitter:GetPitch()
	return self.pitch
end

function SoundEmitter:SetPitch(pitch)
	OpenAL.alSourcef(self.al_source, OpenAL.AL_PITCH, pitch)
end

function SoundEmitter:GetPosition()
	return unpack(self.position)
end

function SoundEmitter:SetPosition(x, y, z)
	self.position = {x, y, z}
end

function SoundEmitter:GetVelocity()
	return unpack(self.velocity)
end

function SoundEmitter:SetVelocity(x, y, z)
	self.velocity = {x, y, z}
end

function SoundEmitter:Play()
	OpenAL.alSourcePlay(self.al_source)
end

return SoundEmitter