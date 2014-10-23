--[[
	Threading Interface

	Based on https://github.com/ColonelThirtyTwo/LuaJIT-Threads
]]
local Coeus = (...)
local ffi = require("ffi")
local OOP = Coeus.Utility.OOP
local ljta = Coeus.Bindings.luajit_thread_aux
local LuaJIT = Coeus.Bindings.LuaJIT
local TCT = Coeus.Bindings.TinyCThread

local xpcall_debug_hook_dump = string.dump(function(err)
	return debug.traceback(tostring(err) or "<nonstring error>")
end)

local converters = {
	["number"] = function(L,v)
		LuaJIT.lua_pushnumber(L,v)
	end,

	["string"] = function(L,v)
		LuaJIT.lua_pushlstring(L,v,#v)
	end,

	["nil"] = function(L,v)
		LuaJIT.lua_pushnil(L)
	end,

	["boolean"] = function(L,v)
		LuaJIT.lua_pushboolean(L,v)
	end,

	["cdata"] = function(L,v)
		LuaJIT.lua_pushlightuserdata(L,v)
	end,
}

-- Copies values into a lua state
local function move_values(L, ...)
	local n = select("#", ...)

	if (LuaJIT.lua_checkstack(L, n) == 0) then
		Coeus:Fatal("Out of memory to move Lua values across state", "Coeus.Threading.Thread:move_values")
	end

	for i = 1, n do
		local v = select(i, ...)
		local converter = converters[type(v)]

		if (not converter) then
			Coeus:Error(("Cannot pass argument %s into thread: type not supported"):format(i), "Coeus.Threading.Thread:move_values")
		end

		converter(L, v)
	end
end

local Thread = OOP:Class()()

--[[
	Creates a new thread with a given function and a list of arguments.
]]
function Thread:_new(method, ...)
	local serialized = string.dump(method)
	local L = LuaJIT.luaL_newstate()

	self.state = L

	LuaJIT.luaL_openlibs(L)
	LuaJIT.lua_settop(L, 0)

	LuaJIT.lua_getfield(L, LuaJIT.LUA_GLOBALSINDEX, "loadstring")
	LuaJIT.lua_pushlstring(L, xpcall_debug_hook_dump, #xpcall_debug_hook_dump)
	LuaJIT.lua_call(L, 1, 1)

	LuaJIT.lua_getfield(L, LuaJIT.LUA_GLOBALSINDEX, "loadstring")
	LuaJIT.lua_pushlstring(L, serialized, #serialized)
	LuaJIT.lua_call(L, 1, 1)

	move_values(L, ...)

	self.thread = ffi.new("thrd_t[1]")
	TCT.thrd_create(self.thread, ljta.ljta_run, ffi.cast("void*", L))
end

--[[
	Joins the thread object back into the main thread.
]]
function Thread:Join()
	TCT.thrd_join(self.thread[0], nil)
end

--[[
	Destroys the thread by issuing a thread join.
]]
function Thread:Destroy()
	self:Join()
end

return Thread