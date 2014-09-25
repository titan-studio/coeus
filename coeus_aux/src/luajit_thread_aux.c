#include "luajit_thread_aux.h"

void ljta_run(void* L) {
	lua_State* Lp = (lua_State*)L;

	int args = lua_gettop(L) - 2;
	int r = lua_pcall(L, args, 0, 1);
	lua_pushinteger(L, r);
}