--[[
	Sound Asset Common

	Defines common data for sound loading.
]]

local C = (...)
local Coeus = C:Get("Coeus")
local OOP = Coeus.Utility.OOP
local OpenAL = Coeus.Bindings.OpenAL

local SoundCommon = {}

SoundCommon.Format = OOP:Static() {
	Mono8 = 1,
	Mono16 = 2,
	Stereo8 = 3,
	Stereo16 = 4
}

local F = SoundCommon.Format
SoundCommon.OpenALFormat = OOP:Static() {
	[F.Mono8] = OpenAL.AL_FORMAT_MONO8,
	[F.Mono16] = OpenAL.AL_FORMAT_MONO16,
	[F.Stereo8] = OpenAL.AL_FORMAT_STEREO8,
	[F.Stereo16] = OpenAL.AL_FORMAT_STEREO16
}

return SoundCommon