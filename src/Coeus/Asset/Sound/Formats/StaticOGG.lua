local Coeus = ...
local ffi = require("ffi")

local OOP = Coeus.Utility.OOP
local ogg = Coeus.Bindings.libogg
local vorbisfile = Coeus.Bindings.libvorbisfile
local C = Coeus.Bindings.C

local SoundCommon = Coeus.Asset.Sound.Common
local SoundData = Coeus.Asset.Sound.SoundData

local OGGFormat = OOP:Static(Coeus.Asset.Format)()

local BUFFER_SIZE = 32768

function OGGFormat:Load(filename)
	local buffer = {}
	local array = ffi.new("uint8_t[?]", BUFFER_SIZE)
	local endian = 0
	local pbit_stream = ffi.new("int[1]")

	local format, frequency

	local f = C.fopen(filename, "rb")
	local pinfo
	local pogg_file = ffi.new("OggVorbis_File[1]")

	vorbisfile.ov_open(f, pogg_file, nil, 0)
	pinfo = vorbisfile.ov_info(pogg_file, -1)

	if (pinfo[0].channels == 1) then
		format = SoundCommon.Format.Mono16
	else
		format = SoundCommon.Format.Stereo16
	end

	local frequency = pinfo[0].rate
	local bytes = 0
	local total_size = 0

	repeat
		bytes = vorbisfile.ov_read(pogg_file, array, BUFFER_SIZE, endian, 2, 1, pbit_stream)
		total_size = total_size + bytes

		table.insert(buffer, ffi.string(array, bytes))
	until (bytes == 0)

	local bufstr = table.concat(buffer)
	local data = ffi.new("uint8_t[?]", total_size)
	for i = 1, total_size do
		data[i - 1] = string.byte(bufstr:sub(i, i))
	end

	vorbisfile.ov_clear(oggFile)

	local out = SoundData:New()
	out.format = format
	out.frequency = frequency
	out.size = total_size
	out.channels = tonumber(pinfo[0].channels)
	out.data = data

	return out
end

function OGGFormat:Match(filename, static)
	return static and (not not filename:match("%.ogg$"))
end

return OGGFormat