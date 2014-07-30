local Coeus = (...)
local ffi = require("ffi")
local C = ffi.C

ffi.cdef([[
struct _iobuf {
	char *_ptr;
	int   _cnt;
	char *_base;
	int   _flag;
	int   _file;
	int   _charbuf;
	int   _bufsiz;
	char *_tmpfname;
};
typedef struct _iobuf FILE;
]])

return C