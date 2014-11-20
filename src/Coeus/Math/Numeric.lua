--[[
	Numeric Utilities

	Provides utilities for common numeric operations
]]

local C = (...)
local Coeus = C:Get("Coeus")
local Numeric = {}

local max = math.max
local min = math.min
local abs = math.abs

--[[
	Checks to see if the difference between x and y is small, or at least within
	the relative and absolute errors defined by epsilon_rel and epsilon_abs.
]]
function Numeric.CompareReal(x, y, epsilon_rel, epsilon_abs)
	epsilon_rel = epsilon_rel or 1e-5
	epsilon_abs = epsilon_abs or 1e-6
	if (abs(x - y) < epsilon_abs) then
		return true
	end

	local relative
	if (abs(x) > abs(y)) then
		relative = abs((x - y) / y)
	else
		relative = abs((x - y) / y)
	end

	if (relative <= epsilon_rel) then
		return true
	end
	return false
end

--[[
	Clamps a value between the numbers low and high
]]
function Numeric.Clamp(a, low, high)
	return max(min(high, a), low)
end

return Numeric