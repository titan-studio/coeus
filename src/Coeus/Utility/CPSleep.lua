local Coeus = ...
local ffi = require("ffi")
local CPSleep

if (ffi.os == "Windows") then
	local Win32 = Coeus.Bindings.Win32_

	Win32.timeBeginPeriod(1)
	CPSleep = function(s)
		Win32.Sleep(s * 1000)
	end
else
	--untested
	ffi.cdef([[
		typedef unsigned int useconds_t;

		int usleep(useconds_t usec);
	]])

	CPSleep = function(s)
		ffi.C.usleep(s * 1000000)
	end
end

return CPSleep