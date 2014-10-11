local Coeus = (...)
local Numeric = {}

function Numeric.CompareReal(x, y, epsilon_rel, epsilon_abs)
	epsilon_rel = epsilon_rel or 1e-5
	epsilon_abs = epsilon_abs or 1e-6
	if math.abs(x - y) < epsilon_abs then
		return true
	end

	local relative
	if math.abs(x) > math.abs(y) then
		relative = math.abs((x - y) / y)
	else
		relative = math.abs((x - y) / y)
	end

	if relative <= epsilon_rel then
		return true
	end
	return false
end

function Numeric.Clamp(a, min, max)
	return math.max(math.min(max, a), min)
end

function Numeric.AngleDifference(t1, t2)
	return (t1 - t2 + math.pi) % (math.pi * 2) - math.pi
end

return Numeric