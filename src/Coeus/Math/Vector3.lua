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

function Vector3:GetValues()
	return {self.x, self.y, self.z}
end

return Vector3