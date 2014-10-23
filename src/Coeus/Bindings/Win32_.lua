--[[
	Win32 Bindings (Partial)

	Contains just the Win32 bindings Coeus needs.
]]

local Coeus = (...)
local ffi = require("ffi")
if (ffi.os ~= "Windows") then
	return
end

ffi.cdef([[
	typedef uint16_t WORD;
	typedef long LONG;
	typedef unsigned long DWORD;
	typedef unsigned long ULONG_PTR;
	typedef void *HANDLE;
	typedef const char *LPCSTR;
	typedef int BOOL;

	typedef struct _LIST_ENTRY {
	   struct _LIST_ENTRY *Flink;
	   struct _LIST_ENTRY *Blink;
	} LIST_ENTRY, *PLIST_ENTRY;

	typedef struct _RTL_CRITICAL_SECTION {
	    struct _RTL_CRITICAL_SECTION *DebugInfo;

	    //
	    //  The following three fields control entering and exiting the critical
	    //  section for the resource
	    //

	    LONG LockCount;
	    LONG RecursionCount;
	    HANDLE OwningThread;        // from the thread's ClientId->UniqueThread
	    HANDLE LockSemaphore;
	    ULONG_PTR SpinCount;        // force size on 64-bit systems when packed
	} RTL_CRITICAL_SECTION, *PRTL_CRITICAL_SECTION;

	typedef struct _RTL_CRITICAL_SECTION_DEBUG {
	    WORD   Type;
	    WORD   CreatorBackTraceIndex;
	    struct _RTL_CRITICAL_SECTION *CriticalSection;
	    LIST_ENTRY ProcessLocksList;
	    DWORD EntryCount;
	    DWORD ContentionCount;
	    DWORD Flags;
	    WORD   CreatorBackTraceIndexHigh;
	    WORD   SpareWORD  ;
	} RTL_CRITICAL_SECTION_DEBUG, *PRTL_CRITICAL_SECTION_DEBUG, RTL_RESOURCE_DEBUG, *PRTL_RESOURCE_DEBUG;

	typedef struct _RTL_CRITICAL_SECTION CRITICAL_SECTION;
	typedef unsigned int MMRESULT;

	void Sleep(DWORD milliseconds);
	MMRESULT timeBeginPeriod(unsigned int uperiod);
	BOOL SetDllDirectoryA(LPCSTR lpPathName);
]])

return ffi.C