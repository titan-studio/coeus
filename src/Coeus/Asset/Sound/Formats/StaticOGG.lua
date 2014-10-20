local Coeus = ...
local ffi = require("ffi")

local OOP = Coeus.Utility.OOP
local ogg = Coeus.Bindings.libogg
local vorbisfile = Coeus.Bindings.libvorbisfile
local C = Coeus.Bindings.C

local SoundCommon = Coeus.Asset.Sound.Common
local SoundData = Coeus.Asset.Sound.SoundData

local OGGFormat = OOP:Static(Coeus.Asset.Format)()

local CHUNK_SIZE = 524288

function OGGFormat:Load(filename)
	local buffer_size = CHUNK_SIZE
	local data = ffi.cast("uint8_t*", C.malloc(buffer_size))

	local array = ffi.cast("uint8_t*", C.malloc(CHUNK_SIZE))
	local pbit_stream = ffi.new("int[1]")

	local format

	local f = C.fopen(filename, "rb")
	local pogg_file = ffi.new("OggVorbis_File[1]")

	vorbisfile.ov_open(f, pogg_file, nil, 0)
	local pinfo = vorbisfile.ov_info(pogg_file, -1)

	if (pinfo[0].channels == 1) then
		format = SoundCommon.Format.Mono16
	else
		format = SoundCommon.Format.Stereo16
	end

	local frequency = pinfo[0].rate
	local bytes = 0
	local total_size = 0
	local written_size = 0

	repeat
		bytes = vorbisfile.ov_read(pogg_file, array, CHUNK_SIZE, 0, 2, 1, pbit_stream)
		total_size = total_size + bytes

		if (buffer_size < total_size) then
			while (buffer_size < total_size) do
				buffer_size = buffer_size * 2
			end
			data = ffi.cast("uint8_t*", C.realloc(data, buffer_size))
		end

		ffi.copy(data + written_size, array, CHUNK_SIZE)
		written_size = total_size
	until (bytes == 0)

	if (buffer_size < total_size) then
		data = ffi.cast("uint8_t*", C.realloc(data, total_size))
	end

	vorbisfile.ov_clear(oggFile)

	local out = SoundData:New()
	out.format = format
	out.frequency = frequency
	out.size = total_size
	out.channels = tonumber(pinfo[0].channels)
	out.data = ffi.gc(data, C.free)

	C.free(array)

	return out
end

function OGGFormat:Match(filename, static)
	return static and (not not filename:match("%.ogg$"))
end

return OGGFormat