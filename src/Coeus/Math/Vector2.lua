--[[
	Vector2

	Provides methods for operating on 2D vectors

	TODO:
	- Provide operators for non-vector number pairs like
		Vector2 AddXY(vector, x, y, out)
			Add a tuple to a vector
		x, y XYAddXY(vector, x, y)
			Add a vector to a tuple and return a tuple
		x, y XYNormalizeXY(x, y)
			Normalize a pair without making a vector
	- Update operators to use (..., out) semantics
		This means current operators will be deprecated and begin to only accept vectors
]]

local C = (...)
local Coeus = C:Get("Coeus")
local OOP = Coeus.Utility.OOP

local Vector2 = OOP:Class() {
	x = 0,
	y = 0
}

function Vector2:RELEASE__new(x, y)
	self.x = x or 0
	self.y = y or 0
end

function Vector2:DEBUG__new(x, y)
	local err = "Vector2 accepts 2 Lua number or nil parameters."

	if (x ~= nil and type(x) ~= "number") then
		return C:Error(err .. " Argument 1 is of type '" .. type(x) .. "'")
	end

	if (y ~= nil and type(y) ~= "number") then
		return C:Error(err .. " Argument 2 is of type '" .. type(y) .. "'")
	end

	self.x = x or 0
	self.y = y or 0
end

if (C.Config.Debug) then
	Vector2._new = Vector2.DEBUG__new
else
	Vector2._new = Vector2.RELEASE__new
end

function Vector2.Add(a, b)
	if (type(a) == "number") then
		return Vector2.Add(b, a, out)
	end
	if (type(b) == "number") then
		return Vector2:New(a.x + b, a.y + b)
	end

	return Vector2:New(a.x + b.x, a.y + b.y)
end

function Vector2.Subtract(a, b)
	if (type(b) == "number") then
		return Vector2:New(a.x - b, a.y - b)
	end
	return Vector2:New(a.x - b.x, a.y - b.y)
end

function Vector2.Multiply(a, b)
	if (type(a) == "number") then
		return Vector2.Multiply(b, a)
	end
	if (type(b) == "number") then
		return Vector2:New(a.x * b, a.y * b)
	end
	return Vector2:New(a.x * b.x, a.y * b.y)
end

function Vector2.Divide(a, b)
	if (type(b) == "number") then
		return Vector2:New(a.x / b, a.y / b)
	end
	return Vector2:New(a.x / b.x, a.y / b.y)
end

function Vector2:LengthSquared()
	return self.x^2 + self.y^2
end

function Vector2:Length()
	return math.sqrt(self.x^2 + self.y^2)
end

function Vector2:Normalize()
	local len = self:Length()
	self.x = self.x / len
	self.y = self.y / len
end

function Vector2:GetNormalized()
	local len = self:Length()
	return Vector2:New(self.x / len, self.y / len)
end

function Vector2.GetMidpoint(a, b)
	return (a + b) / 2
end

function Vector2.Lerp(a, b, alpha)
	return a + (alpha * (b - a))
end

function Vector2:GetAngle()
	return math.atan2(self.y, self.x)
end

function Vector2:Rotate(angle)
	local sin, cos = math.sin(angle), math.cos(angle)
	self.x = cos * self.x - sin * self.y
	self.y = sin * self.x - cos * self.y
end

function Vector2:GetRotated(angle)
	local sin, cos = math.sin(angle), math.cos(angle)
	return Vector2:New(
		cos * self.x - sin * self.y,
		sin * self.x - cos * self.y
	)
end

function Vector2:GetPerpendicular()
	return Vector2:New(-self.y, self.x)
end

function Vector2:GetMirroredOver(other)
	local s = 2 * (self.x * other.x + self.y + other.y) / (other.x^2 + other.y^2)
	return Vector2:New(s * other.x, s * other.y)
end

function Vector2:GetProjected(other)
	local s = (self.x * other.x + self.y * other.y) / (other.x * other.x + other.y * other.y)
	return Vector2:New(s * other.x, s * other.y)
end

function Vector2:Cross(other)
	return self.x * other.y - self.y * other.x
end

function Vector2:GetValues()
	return {self.x, self.y}
end

--deprecated; use Vector2:ToVector3 instead
function Vector2:XYZ(z)
	return Coeus.Math.Vector3:New(self.x, self.y, z or 0)
end

--[[
	Creates a Vector3 with the X and Y components of this Vector2 with a specified Z component
]]
function Vector2:ToVector3(z)
	return Coeus.Math.Vector3:New(self.x, self.y, z)
end

--[[
	Returns whether the two Vector2 objects are equal
]]
function Vector2.Compare(a, b)
	--todo: debug variant
	return (a.x == b.x and a.y == b.y)
end

--[[
	Returns a string representation of the Vector2
]]
function Vector2:ToString()
	return ("(%s, %s)"):format(self.x, self.y)
end

Vector2:AddMetamethods({
	__add = function(a, b)
		return Vector2.Add(a, b)
	end,
	__sub = function(a, b)
		return Vector2.Subtract(a, b)
	end,
	__mul = function(a, b)
		return Vector2.Multiply(a, b)
	end,
	__div = function(a, b)
		return Vector2.Divide(a, b)
	end,
	__unm = function(a)
		return Vector2:New(-a.x, -a.y)
	end,
	__eq = function(a, b)
		--todo: deprecate
		return Coeus.Math.Numeric.CompareReal(a.x, b.x) and
			   Coeus.Math.Numeric.CompareReal(a.y, b.y)
	end
})

return Vector2