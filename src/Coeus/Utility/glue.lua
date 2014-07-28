--glue (Cosmin Apreutesei, public domain)
--bare minimum to make the libpng binding work
--fuck this shit this is useless

local glue = {}

function glue.assert(v,err,...)
	if v then return v,err,... end
	err = err or 'assertion failed!'
	if select('#',...) > 0 then err = format(err,...) end
	error(err, 2)
end

function glue.unprotect(ok, result, ...)
	if not ok then return nil, result, ... end
	if result == nil then result = true end
	return result, ...
end

local function pcall_error(e)
	return tostring(e) .. '\n' .. debug.traceback()
end
function glue.pcall(f, ...) --luajit and lua 5.2 only!
	return xpcall(f, pcall_error, ...)
end

local unprotect = glue.unprotect
function glue.fpcall(f,...) --bloated: 2 tables, 4 closures. can we reduce the overhead?
	local fint, errt = {}, {}
	local function finally(f) fint[#fint+1] = f end
	local function onerror(f) errt[#errt+1] = f end
	local function err(e)
		for i=#errt,1,-1 do errt[i]() end
		for i=#fint,1,-1 do fint[i]() end
		return tostring(e) .. '\n' .. debug.traceback()
	end
	local function pass(ok,...)
		if ok then
			for i=#fint,1,-1 do fint[i]() end
		end
		return unprotect(ok,...)
	end
	return pass(xpcall(f, err, finally, onerror, ...))
end

local fpcall = glue.fpcall
function glue.fcall(f,...)
	return assert(fpcall(f,...))
end

return glue