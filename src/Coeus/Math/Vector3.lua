local Coeus = (...)
local OOP = Coeus.Utility.OOP

local Vector3 = OOP:Class() {
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
	if type(a) == 'number' then
		return Vector3.Add(b, a)
	end
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
	if type(a) == 'number' then
		return Vector3.Multiply(b, a)
	end
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

function Vector3:LengthSquared()
	return (self.x^2) + (self.y^2) + (self.z^2)
end
function Vector3:Length()
	return math.sqrt(self:LengthSquared())
end

function Vector3.Unit(a)
	local length = a:Length()
	return a / length
end
function Vector3:Normalize()
	local len = self:Length()
	self.x = self.x / len
	self.y = self.y / len
	self.z = self.z / len
end

function Vector3.GetMidpoint(a, b)
	return (a + b) / 2
end

function Vector3.Lerp(a, b, alpha)
	return a + (alpha * (b - a))
end

function Vector3:GetValues()
	return {self.x, self.y, self.z}
end

function Vector3:XY() 
	return Coeus.Math.Vector2:New(self.x, self.y)
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