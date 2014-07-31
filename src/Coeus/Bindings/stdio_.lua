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

enum {
	SEEK_CUR = 1,
	SEEK_END = 2,
	SEEK_SET = 0
};

FILE* fopen(const char* filename, const char* mode);
int fclose(FILE* stream);
size_t fread(void* ptr, size_t size, size_t count, FILE* stream);
int fseek(FILE* stream, long int offset, int origin);
long int ftell(FILE* stream);

]])

return C