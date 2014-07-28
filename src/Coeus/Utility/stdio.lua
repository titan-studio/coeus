--pretty much fucking useless too but libpng uses it
--stdio binding (incomplete)
local ffi = require'ffi'
--wint_t is defined as short per mingw for compatibility with MS.
ffi.cdef[[
typedef short unsigned int wint_t;
]]

--result of `cpp stdint.h` from mingw

ffi.cdef[[
typedef signed char int_least8_t;
typedef unsigned char uint_least8_t;
typedef short int_least16_t;
typedef unsigned short uint_least16_t;
typedef int int_least32_t;
typedef unsigned uint_least32_t;
typedef long long int_least64_t;
typedef unsigned long long uint_least64_t;
typedef signed char int_fast8_t;
typedef unsigned char uint_fast8_t;
typedef short int_fast16_t;
typedef unsigned short uint_fast16_t;
typedef int int_fast32_t;
typedef unsigned int uint_fast32_t;
typedef long long int_fast64_t;
typedef unsigned long long uint_fast64_t;
typedef long long intmax_t;
typedef unsigned long long uintmax_t;
]]

--result of `cpp sys/types.h` from mingw

ffi.cdef[[
typedef long __time32_t;
typedef long long __time64_t;
typedef long _off_t;
typedef _off_t off_t;
typedef unsigned int _dev_t;
typedef _dev_t dev_t;
typedef short _ino_t;
typedef _ino_t ino_t;
typedef int _pid_t;
typedef _pid_t pid_t;
typedef unsigned short _mode_t;
typedef _mode_t mode_t;
typedef int _sigset_t;
typedef _sigset_t sigset_t;
typedef int _ssize_t;
typedef _ssize_t ssize_t;
typedef long long fpos64_t;
typedef long long off64_t;
typedef unsigned int useconds_t;
]]


ffi.cdef[[
typedef struct FILE_ FILE;
typedef long long fpos_t;

enum {
	STDIN_FILENO   = 0,
	STDOUT_FILENO  = 1,
	STDERR_FILENO  = 2,
	EOF            = -1,
	SEEK_SET       = 0,
	SEEK_CUR       = 1,
	SEEK_END       = 2
};

FILE* fopen (const char*, const char*);
FILE* freopen (const char*, const char*, FILE*);
int fflush (FILE*);
int fclose (FILE*);
int remove (const char*);
int rename (const char*, const char*);
FILE* tmpfile (void);
char* tmpnam (char*);
char* _tempnam (const char*, const char*);
int _rmtmp(void);
int _unlink (const char*);
char* tempnam (const char*, const char*);
int rmtmp(void);
int unlink (const char*);
int setvbuf (FILE*, char*, int, size_t);
void setbuf (FILE*, char*);
int fprintf (FILE*, const char*, ...);
int printf (const char*, ...);
int sprintf (char*, const char*, ...);
int vfprintf (FILE*, const char*, __gnuc_va_list);
int vprintf (const char*, __gnuc_va_list);
int vsprintf (char*, const char*, __gnuc_va_list);
int _snprintf (char*, size_t, const char*, ...);
int _vsnprintf (char*, size_t, const char*, __gnuc_va_list);
int _vscprintf (const char*, __gnuc_va_list);
int snprintf (char *, size_t, const char *, ...);
int vsnprintf (char *, size_t, const char *, __gnuc_va_list);
int vscanf (const char * __restrict__, __gnuc_va_list);
int vfscanf (FILE * __restrict__, const char * __restrict__, __gnuc_va_list);
int vsscanf (const char * __restrict__, const char * __restrict__, __gnuc_va_list);
int fscanf (FILE*, const char*, ...);
int scanf (const char*, ...);
int sscanf (const char*, const char*, ...);
int fgetc (FILE*);
char* fgets (char*, int, FILE*);
int fputc (int, FILE*);
int fputs (const char*, FILE*);
char* gets (char*);
int puts (const char*);
int ungetc (int, FILE*);
int _filbuf (FILE*);
int _flsbuf (int, FILE*);
int getc (FILE* __F);
int putc (int __c, FILE* __F);
int getchar (void);
int putchar(int __c);
size_t fread (void*, size_t, size_t, FILE*);
size_t fwrite (const void*, size_t, size_t, FILE*);
int fseek (FILE*, long, int);
long ftell (FILE*);
void rewind (FILE*);
int fgetpos (FILE*, fpos_t*);
int fsetpos (FILE*, const fpos_t*);
int feof (FILE*);
int ferror (FILE*);
void clearerr (FILE*);
void perror (const char*);
FILE* _popen (const char*, const char*);
int _pclose (FILE*);
FILE* popen (const char*, const char*);
int pclose (FILE*);
int _flushall (void);
int _fgetchar (void);
int _fputchar (int);
FILE* _fdopen (int, const char*);
int _fileno (FILE*);
int _fcloseall (void);
FILE* _fsopen (const char*, const char*, int);
int _getmaxstdio (void);
int _setmaxstdio (int);
int fgetchar (void);
int fputchar (int);
FILE* fdopen (int, const char*);
int fileno (FILE*);
FILE* fopen64 (const char* filename, const char* mode);
int fseeko64 (FILE*, off64_t, int);
off64_t ftello64 (FILE * stream);
int fwprintf (FILE*, const wchar_t*, ...);
int wprintf (const wchar_t*, ...);
int _snwprintf (wchar_t*, size_t, const wchar_t*, ...);
int vfwprintf (FILE*, const wchar_t*, __gnuc_va_list);
int vwprintf (const wchar_t*, __gnuc_va_list);
int _vsnwprintf (wchar_t*, size_t, const wchar_t*, __gnuc_va_list);
int _vscwprintf (const wchar_t*, __gnuc_va_list);
int fwscanf (FILE*, const wchar_t*, ...);
int wscanf (const wchar_t*, ...);
int swscanf (const wchar_t*, const wchar_t*, ...);
wint_t fgetwc (FILE*);
wint_t fputwc (wchar_t, FILE*);
wint_t ungetwc (wchar_t, FILE*);
int swprintf (wchar_t*, const wchar_t*, ...);
int vswprintf (wchar_t*, const wchar_t*, __gnuc_va_list);
wchar_t* fgetws (wchar_t*, int, FILE*);
int fputws (const wchar_t*, FILE*);
wint_t getwc (FILE*);
wint_t getwchar (void);
wchar_t* _getws (wchar_t*);
wint_t putwc (wint_t, FILE*);
int _putws (const wchar_t*);
wint_t putwchar (wint_t);
FILE* _wfdopen(int, const wchar_t *);
FILE* _wfopen (const wchar_t*, const wchar_t*);
FILE* _wfreopen (const wchar_t*, const wchar_t*, FILE*);
FILE* _wfsopen (const wchar_t*, const wchar_t*, int);
wchar_t* _wtmpnam (wchar_t*);
wchar_t* _wtempnam (const wchar_t*, const wchar_t*);
int _wrename (const wchar_t*, const wchar_t*);
int _wremove (const wchar_t*);
void _wperror (const wchar_t*);
FILE* _wpopen (const wchar_t*, const wchar_t*);
int snwprintf (wchar_t* s, size_t n, const wchar_t* format, ...);
int vsnwprintf (wchar_t* s, size_t n, const wchar_t* format, __gnuc_va_list arg);
int vwscanf (const wchar_t * __restrict__, __gnuc_va_list);
int vfwscanf (FILE * __restrict__, const wchar_t * __restrict__, __gnuc_va_list);
int vswscanf (const wchar_t * __restrict__, const wchar_t * __restrict__, __gnuc_va_list);
FILE* wpopen (const wchar_t*, const wchar_t*);
wint_t _fgetwchar (void);
wint_t _fputwchar (wint_t);
int _getw (FILE*);
int _putw (int, FILE*);
wint_t fgetwchar (void);
wint_t fputwchar (wint_t);
int getw (FILE*);
int putw (int, FILE*);
]]
local M = setmetatable({C = ffi.C}, {__index = ffi.C})

local function checkh(h)
	if h ~= nil then return h end
	error(string.format('errno: %d', ffi.errno()))
end

local function str(s)
	return ffi.string(checkh(s))
end

local function checkz(ret)
	if ret == 0 then return end
	error(string.format('errno: %d', ffi.errno()))
end

local function zcaller(f)
	return function(...)
		checkz(f(...))
	end
end

function M.fopen(path, mode)
	return ffi.gc(checkh(ffi.C.fopen(path, mode or 'rb')), M.fclose)
end

function M.freopen(file, path, mode)
	return checkh(ffi.C.freopen(path, mode or 'rb', file))
end

function M.tmpfile()
	return ffi.gc(checkh(ffi.C.tmpfile()), M.fclose)
end

function M.tmpnam(prefix)
	return str(ffi.C.tmpnam(prefix))
end

function M.fclose(file)
	checkz(ffi.C.fclose(file))
	ffi.gc(file, nil)
end

local fileno = ffi.abi'win' and ffi.C._fileno or ffi.C.fileno
function M.fileno(file)
	local n = fileno(file)
	assert(n >= 0, 'fileno error')
	return n
end

M.fflush = zcaller(ffi.C.fflush)

--methods

ffi.metatype('FILE', {__index = {
	close = M.fclose,
	reopen = M.freopen,
	flush = M.fflush,
	no = M.fileno,
}})

--hi-level API

function M.readfile(file, format)
	local f = M.fopen(file, format=='t' and 'r' or 'rb')
	ffi.C.fseek(f, 0, ffi.C.SEEK_END)
	local sz = ffi.C.ftell(f)
	ffi.C.fseek(f, 0, ffi.C.SEEK_SET)
	local buf = ffi.new('uint8_t[?]', sz)
	ffi.C.fread(buf, 1, sz, f)
	f:close()
	return buf, sz
end

function M.writefile(file, data, sz, format)
	local f = M.fopen(file, format=='t' and 'w' or 'wb')
	ffi.C.fwrite(data, 1, sz, f)
	f:close()
end

return M