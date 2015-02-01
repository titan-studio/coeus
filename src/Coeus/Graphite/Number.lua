--[[
	Graphite for Lua
	Number Utilities

	Exists to make integrating of binding objects like pointers smooth.

	Copyright (c) 2014 Lucien Greathouse (LPGhatguy)

	This software is provided 'as-is', without any express or implied warranty.
	In no event will the authors be held liable for any damages arising from the
	use of this software.

	Permission is granted to anyone to use this software for any purpose, including
	commercial applications, and to alter it and redistribute it freely, subject to
	the following restrictions:

	1. The origin of this software must not be misrepresented; you must not claim
	that you wrote the original software. If you use this software in a product, an
	acknowledgment in the product documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and must not be misrepresented
	as being the original software.

	3. This notice may not be removed or altered from any source distribution.
]]

local Graphite = (...)
local Number = {
}

local indexable = {
	["table"] = true,
	["userdata"] = true,
	["string"] = true
}

function Number.Equals(a, b)
	local ma, mb = getmetatable(a), getmetatable(b)
	local op = (ma and ma.__eq) or (mb and mb.__eq)

	if (op) then
		return (a == b) or op(a, b)
	else
		return (a == b)
	end
end

function Number.LessThan(a, b)
	local ma, mb = getmetatable(a), getmetatable(b)
	local op = (ma and ma.__lt) or (mb and mb.__lt)

	if (op) then
		return op(a, b)
	else
		return (a < b)
	end
end

function Number.GreaterThan(a, b)
	local ma, mb = getmetatable(a), getmetatable(b)
	local op = (ma and ma.__le) or (mb and mb.__le)

	if (op) then
		return not op(a, b)
	else
		return (a > b)
	end
end

function Number.LessThanEqualTo(a, b)
	local ma, mb = getmetatable(a), getmetatable(b)
	local op = (ma and ma.__le) or (mb and mb.__le)

	if (op) then
		return op(a, b)
	else
		return (a <= b)
	end
end

function Number.GreaterThanEqualTo(a, b)
	local ma, mb = getmetatable(a), getmetatable(b)
	local op = (ma and ma.__lt) or (mb and mb.__lt)

	if (op) then
		return not op(a, b)
	else
		return (a > b)
	end
end

-- Shorthand aliases
Number.eq = Number.Equals
Number.lt = Number.LessThan
Number.le = Number.LessThanEqualTo
Number.gt = Number.GreaterThan
Number.ge = Number.GreaterThanEqualTo

return Number