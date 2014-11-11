--[[
	DDS Loader

	Loads DDS images (.dds)
]]
local Coeus = (...)
local ffi = require("ffi")

local OOP = Coeus.Utility.OOP
local ImageData = Coeus.Asset.Image.ImageData
local C = Coeus.Bindings.C

--[=[ffi.cdef([[
struct DDS_PIXELFORMAT {
  unsigned long dwSize;
  unsigned long dwFlags;
  unsigned long dwFourCC;
  unsigned long dwRGBBitCount;
  unsigned long dwRBitMask;
  unsigned long dwGBitMask;
  unsigned long dwBBitMask;
  unsigned long dwABitMask;
};

typedef struct {
  unsigned long           dwSize;
  unsigned long           dwFlags;
  unsigned long           dwHeight;
  unsigned long           dwWidth;
  unsigned long           dwPitchOrLinearSize;
  unsigned long           dwDepth;
  unsigned long           dwMipMapCount;
  unsigned long           dwReserved1[11];
  DDS_PIXELFORMAT 		  ddspf;
  unsigned long           dwCaps;
  unsigned long           dwCaps2;
  unsigned long           dwCaps3;
  unsigned long           dwCaps4;
  unsigned long           dwReserved2;
} DDS_HEADER;
]])]=]

local DDSFormat = OOP:Static(Coeus.Asset.Format)()

function DDSFormat:Load(filename)
	local magic = ffi.new("unsigned long[1]")
	local header = ffi.new("DDS_HEADER[1]")

	local file = C.fopen(filename, "rb")
end

function DDSFormat:Match(filename)
	return not not filename:match("%.dds$")
end

return DDSFormat