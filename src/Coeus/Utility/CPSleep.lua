local Coeus = ...
local ffi = require("ffi")
local CPSleep

if (ffi.os == "Windows") then
	local Win32 = Coeus.Bindings.Win32

	Win32.timeBeginPeriod(1)
	CPSleep = function(ms)
		Win32.Sleep(ms)
	end
else
	--untested
	ffi.cdef([[
		typedef unsigned int useconds_t;

		int usleep(useconds_t usec);
	]])

	CPSleep = function(ms)
		ffi.C.usleep(ms * 1000)
	end
end

return CPSleep