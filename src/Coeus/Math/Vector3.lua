local Coeus = (...)
local oop = Coeus.Utility.OOP

local Vector3 = oop:Class() {
	x = 0,
	y = 0,
	z = 0
}

function Vector3:_new(x, y, z)
	self.x = x or self.x
	self.y = y or self.y
	self.z = z or self.z
end

function Vector3.Add(a, b)
	if type(b) == 'number' then
		return Vector3:New(a.x + b, a.y + b, a.z + b)
	end
	return Vector3:New(a.x + b.x, a.y + b.y, a.z + b.z)
end

function Vector3.Subtract(a, b)
	if type(b) == 'number' then
		return Vector3:New(a.x - b, a.y - b, a.z - b)
	end
	return Vector3:New(a.x - b.x, a.y - b.y, a.z - b.z)
end

function Vector3.Multiply(a, b)
	if type(b) == 'number' then
		return Vector3:New(a.x * b, a.y * b, a.z * b)
	end
	return Vector3:New(a.x * b.x, a.y * b.y, a.z * b.z)
end

function Vector3.Divide(a, b)
	if type(b) == 'number' then
		return Vector3:New(a.x / b, a.y / b, a.z / b)
	end
	return Vector3:New(a.x / b.x, a.y / b.y, a.z / b.z)
end

function Vector3.Dot(a, b)
	return (a.x + b.x) + (a.y + b.y) + (a.z + b.z)
end
function Vector3.AngleBetween(a, b)
	return math.acos(Vector3.Dot(a, b))
end

function Vector3.Cross(a, b)
	return Vector3:New(
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x
	)
end

function Vector3:GetValues()
	return {self.x, self.y, self.z}
end

Vector3:AddMetamethods({
	__add = function(a, b)
		return Vector3.Add(a, b)
	end,
	__sub = function(a, b)
		return Vector3.Subtract(a, b)
	end,
	__mul = function(a, b)
		return Vector3.Multiply(a, b)
	end,
	__div = function(a, b)
		return Vector3.Divide(a, b)
	end
})

return Vector3