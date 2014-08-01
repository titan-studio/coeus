local Coeus = require("src.Coeus")
local ffi = require("ffi")
local OpenAL = Coeus.Bindings.OpenAL

local device = ffi.new("ALCdevice*")
local context = ffi.new("ALCcontext*")

local device = OpenAL.alcOpenDevice(nil)
local context = OpenAL.alcCreateContext(device, nil)
OpenAL.alcMakeContextCurrent(context)

local SourcePos = ffi.new("ALfloat[3]", {0, 0, 0})
local SourceVel = ffi.new("ALfloat[3]", {0, 0, 0})
local ListenerPos = ffi.new("ALfloat[3]", {0, 0, 0})
local ListenerVel = ffi.new("ALfloat[3]", {0, 0, 0})
local ListenerOri = ffi.new("ALfloat[6]", {0, 0, -1, 0, 1, 0})

local test_data = {}

local bt = 22000
for index = 1, bt do
	test_data[index] = math.ceil(127 + 127 * math.sin(index / bt))
end

local format = ffi.new("ALenum[1]")
local size = ffi.new("ALsizei[1]")
local data = ffi.new("ALint[?]", #test_data, test_data)
local pdata = ffi.new("ALvoid*", data)
local freq = ffi.new("ALsizei[1]")
local loop = ffi.new("ALboolean[1]", 1)

local Buffer = ffi.new("unsigned int[1]")
OpenAL.alGenBuffers(1, Buffer)
OpenAL.alBufferData(Buffer[0], OpenAL.AL_FORMAT_MONO8, pdata, 4, bt)

local pSource = ffi.new("int[1]")
OpenAL.alGenSources(1, pSource)

local Source = pSource[0]
OpenAL.alSourcei(Source, OpenAL.AL_BUFFER, Buffer[0])
OpenAL.alSourcef(Source, OpenAL.AL_PITCH, 1)
OpenAL.alSourcef(Source, OpenAL.AL_GAIN, 1)
OpenAL.alSourcefv(Source, OpenAL.AL_POSITION, SourcePos)
OpenAL.alSourcefv(Source, OpenAL.AL_VELOCITY, SourceVel)
OpenAL.alSourcei(Source, OpenAL.AL_LOOPING, OpenAL.AL_TRUE)

OpenAL.alListenerfv(OpenAL.AL_POSITION, ListenerPos)
OpenAL.alListenerfv(OpenAL.AL_VELOCITY, ListenerVel)
OpenAL.alListenerfv(OpenAL.AL_ORIENTATION, ListenerOri)

OpenAL.alSourcePlay(Source)