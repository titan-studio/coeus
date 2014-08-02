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

--

local ogg = Coeus.Bindings.libogg
local vorbis = Coeus.Bindings.libvorbis
local vorbisfile = Coeus.Bindings.libvorbisfile
local stdio_ = Coeus.Bindings.stdio_

local BUFFER_SIZE = 32768

local buffer = {}
local array = ffi.new("uint8_t[?]", BUFFER_SIZE)
local endian = 0
local bitStream = ffi.new("int[1]")
local bytes = 0

local format
local freq

local f = stdio_.fopen("test.ogg", "rb")
local pInfo
local oggFile = ffi.new("OggVorbis_File[1]")

vorbisfile.ov_open(f, oggFile, nil, 0)
pInfo = vorbisfile.ov_info(oggFile, -1)

if (pInfo[0].channels == 1) then
	format = OpenAL.AL_FORMAT_MONO16
else
	format = OpenAL.AL_FORMAT_STEREO16
end

local freq = pInfo[0].rate
local total_size = 0

repeat
	bytes = vorbisfile.ov_read(oggFile, array, BUFFER_SIZE, endian, 2, 1, bitStream)
	total_size = total_size + bytes

	table.insert(buffer, ffi.string(array, bytes))
until (bytes == 0)

local bufstr = table.concat(buffer)
for i = 1, total_size do
	buffer[i] = string.byte(bufstr:sub(i, i))
end

vorbisfile.ov_clear(oggFile)

local data = ffi.new("uint8_t[?]", total_size, buffer)
local loop = ffi.new("ALboolean[1]", 1)

local Buffer = ffi.new("unsigned int[1]")
OpenAL.alGenBuffers(1, Buffer)
OpenAL.alBufferData(Buffer[0], format, data, total_size, freq)

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