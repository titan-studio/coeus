local Coeus = ...
local ffi = require("ffi")
local lib = ffi.C
local LuaJIT = {
	lua = {},
	LUA = {}
}

setmetatable(LuaJIT.lua, {
	__index = function(self, key)
		self[key] = lib["lua_" .. key]

		return self[key]
	end
})

setmetatable(LuaJIT.LUA, {
	__index = function(self, key)
		self[key] = lib["LUA_" .. key]

		return self[key]
	end
})

--lua.h
ffi.cdef([[
enum {
	LUA_REGISTRYINDEX = (-10000),
	LUA_ENVIRONINDEX = (-10001),
	LUA_GLOBALSINDEX = (-10002),

	LUA_YIELD = 1,
	LUA_ERRRUN = 2,
	LUA_ERRSYNTAX = 3,
	LUA_ERRMEM = 4,
	LUA_ERRERR = 5,

	LUA_TNONE = (-1),

	LUA_TNIL = 0,
	LUA_TBOOLEAN = 1,
	LUA_TLIGHTUSERDATA = 2,
	LUA_TNUMBER = 3,
	LUA_TSTRING = 4,
	LUA_TTABLE = 5,
	LUA_TFUNCTION = 6,
	LUA_TUSERDATA = 7,
	LUA_TTHREAD = 8,

	LUA_HOOKCALL = 0,
	LUA_HOOKRET = 1,
	LUA_HOOKLINE = 2,
	LUA_HOOKCOUNT = 3,
	LUA_HOOKTAILRET = 4,

	LUA_GCSTOP = 0,
	LUA_GCRESTART = 1,
	LUA_GCCOLLECT = 2,
	LUA_GCCOUNT = 3,
	LUA_GCCOUNTB = 4,
	LUA_GCSTEP = 5,
	LUA_GCSETPAUSE = 6,
	LUA_GCSETSTEPMUL = 7,

	LUA_MINSTACK = 20
};

typedef struct lua_State lua_State;
typedef int (*lua_CFunction) (lua_State *L);

typedef const char * (*lua_Reader) (lua_State *L, void *ud, size_t *sz);
typedef int (*lua_Writer) (lua_State *L, const void* p, size_t sz, void* ud);

typedef void * (*lua_Alloc) (void *ud, void *ptr, size_t osize, size_t nsize);

typedef double lua_Number;

typedef ptrdiff_t lua_Integer;

lua_State *(lua_newstate) (lua_Alloc f, void *ud);
void       (lua_close) (lua_State *L);
lua_State *(lua_newthread) (lua_State *L);

lua_CFunction (lua_atpanic) (lua_State *L, lua_CFunction panicf);

int   (lua_gettop) (lua_State *L);
void  (lua_settop) (lua_State *L, int idx);
void  (lua_pushvalue) (lua_State *L, int idx);
void  (lua_remove) (lua_State *L, int idx);
void  (lua_insert) (lua_State *L, int idx);
void  (lua_replace) (lua_State *L, int idx);
int   (lua_checkstack) (lua_State *L, int sz);

void  (lua_xmove) (lua_State *from, lua_State *to, int n);

int             (lua_isnumber) (lua_State *L, int idx);
int             (lua_isstring) (lua_State *L, int idx);
int             (lua_iscfunction) (lua_State *L, int idx);
int             (lua_isuserdata) (lua_State *L, int idx);
int             (lua_type) (lua_State *L, int idx);
const char     *(lua_typename) (lua_State *L, int tp);

int            (lua_equal) (lua_State *L, int idx1, int idx2);
int            (lua_rawequal) (lua_State *L, int idx1, int idx2);
int            (lua_lessthan) (lua_State *L, int idx1, int idx2);

lua_Number      (lua_tonumber) (lua_State *L, int idx);
lua_Integer     (lua_tointeger) (lua_State *L, int idx);
int             (lua_toboolean) (lua_State *L, int idx);
const char     *(lua_tolstring) (lua_State *L, int idx, size_t *len);
size_t          (lua_objlen) (lua_State *L, int idx);
lua_CFunction   (lua_tocfunction) (lua_State *L, int idx);
void	       *(lua_touserdata) (lua_State *L, int idx);
lua_State      *(lua_tothread) (lua_State *L, int idx);
const void     *(lua_topointer) (lua_State *L, int idx);

void  (lua_pushnil) (lua_State *L);
void  (lua_pushnumber) (lua_State *L, lua_Number n);
void  (lua_pushinteger) (lua_State *L, lua_Integer n);
void  (lua_pushlstring) (lua_State *L, const char *s, size_t l);
void  (lua_pushstring) (lua_State *L, const char *s);
const char *(lua_pushvfstring) (lua_State *L, const char *fmt,
                                                      va_list argp);
const char *(lua_pushfstring) (lua_State *L, const char *fmt, ...);
void  (lua_pushcclosure) (lua_State *L, lua_CFunction fn, int n);
void  (lua_pushboolean) (lua_State *L, int b);
void  (lua_pushlightuserdata) (lua_State *L, void *p);
int   (lua_pushthread) (lua_State *L);

void  (lua_gettable) (lua_State *L, int idx);
void  (lua_getfield) (lua_State *L, int idx, const char *k);
void  (lua_rawget) (lua_State *L, int idx);
void  (lua_rawgeti) (lua_State *L, int idx, int n);
void  (lua_createtable) (lua_State *L, int narr, int nrec);
void *(lua_newuserdata) (lua_State *L, size_t sz);
int   (lua_getmetatable) (lua_State *L, int objindex);
void  (lua_getfenv) (lua_State *L, int idx);

void  (lua_settable) (lua_State *L, int idx);
void  (lua_setfield) (lua_State *L, int idx, const char *k);
void  (lua_rawset) (lua_State *L, int idx);
void  (lua_rawseti) (lua_State *L, int idx, int n);
int   (lua_setmetatable) (lua_State *L, int objindex);
int   (lua_setfenv) (lua_State *L, int idx);

void  (lua_call) (lua_State *L, int nargs, int nresults);
int   (lua_pcall) (lua_State *L, int nargs, int nresults, int errfunc);
int   (lua_cpcall) (lua_State *L, lua_CFunction func, void *ud);
int   (lua_load) (lua_State *L, lua_Reader reader, void *dt,
                                        const char *chunkname);

int (lua_dump) (lua_State *L, lua_Writer writer, void *data);

int  (lua_yield) (lua_State *L, int nresults);
int  (lua_resume) (lua_State *L, int narg);
int  (lua_status) (lua_State *L);

int (lua_gc) (lua_State *L, int what, int data);

int   (lua_error) (lua_State *L);
int   (lua_next) (lua_State *L, int idx);
void  (lua_concat) (lua_State *L, int n);
lua_Alloc (lua_getallocf) (lua_State *L, void **ud);
void lua_setallocf (lua_State *L, lua_Alloc f, void *ud);

void lua_setlevel	(lua_State *from, lua_State *to);

typedef struct lua_Debug lua_Debug;  /* activation record */

/* Functions to be called by the debuger in specific events */
typedef void (*lua_Hook) (lua_State *L, lua_Debug *ar);


int lua_getstack (lua_State *L, int level, lua_Debug *ar);
int lua_getinfo (lua_State *L, const char *what, lua_Debug *ar);
const char *lua_getlocal (lua_State *L, const lua_Debug *ar, int n);
const char *lua_setlocal (lua_State *L, const lua_Debug *ar, int n);
const char *lua_getupvalue (lua_State *L, int funcindex, int n);
const char *lua_setupvalue (lua_State *L, int funcindex, int n);
int lua_sethook (lua_State *L, lua_Hook func, int mask, int count);
lua_Hook lua_gethook (lua_State *L);
int lua_gethookmask (lua_State *L);
int lua_gethookcount (lua_State *L);

void *lua_upvalueid (lua_State *L, int idx, int n);
void lua_upvaluejoin (lua_State *L, int idx1, int n1, int idx2, int n2);
int lua_loadx (lua_State *L, lua_Reader reader, void *dt,
		       const char *chunkname, const char *mode);


struct lua_Debug {
  int event;
  const char *name;
  const char *namewhat;
  const char *what;
  const char *source;
  int currentline;
  int nups;
  int linedefined;
  int lastlinedefined;
  char short_src[60];

  int i_ci;
};
]])

--lauxlib.h
ffi.cdef([[
]])

--lualib.h
ffi.cdef([[
int luaopen_base(lua_State *L);
int luaopen_math(lua_State *L);
int luaopen_string(lua_State *L);
int luaopen_table(lua_State *L);
int luaopen_io(lua_State *L);
int luaopen_os(lua_State *L);
int luaopen_package(lua_State *L);
int luaopen_debug(lua_State *L);
int luaopen_bit(lua_State *L);
int luaopen_jit(lua_State *L);
int luaopen_ffi(lua_State *L);

void luaL_openlibs(lua_State *L);
]])

return LuaJIT