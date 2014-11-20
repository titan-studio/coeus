local C = (...)
local Coeus = C:Get("Coeus")
local oop = Coeus.Utility.OOP

local Matrix4 = Coeus.Math.Matrix4
local Vector3 = Coeus.Math.Vector3

--TURN BACK NOW! THIS FILE HAS BEEN KNOWN TO CAUSE IRREVERSIBLE BRAIN DAMAGE

local Quaternion = oop:Class() {
	x = 0,
	y = 0,
	z = 0,
	w = 1
}

function Quaternion:_new(x, y, z, w)
	self.x = x or self.x
	self.y = y or self.y
	self.z = z or self.z
	self.w = w or self.w
end

function Quaternion.FromMatrix4(matrix)
	local m = matrix.m
	local trace = m[1] + m[6] + m[11]
	local root

	if trace > 0 then
		root = math.sqrt(trace + 1)
		local w = root * 0.5
		root = 0.5 / root
		return Quaternion:New(
			(m[10] - m[7]) * root,
			(m[ 3] - m[9]) * root,
			(m[ 5] - m[2]) * root,
			w
		)
	else
		--This section is adapted from some C++ code from the Ogre3D framework
		--and as such is completely nonsensical in Lua because we lack convenient
		--pointer math. Therefore, it uses a bunch of if statements to get similar
		--functionality.
		--
		--There is probably a more elegant solution to this, but I don't personally
		--understand the math enough to implement it myself.
		--If anyone more knowledgeable than I stumbles upon this, please feel
		--free to clean it up a little bit.
		--
		--	Kyle
		local i = 0
		if m[6] > m[1] then
			i = 1
		else
			i = 2
		end
		local n = {1, 2, 0}
		local j = n[i - 1]
		local k = n[j - 1]

		local ii, jj, kk, kj, jk, ji, ij, ki, ik
		if i == 0 then
			ii = m[1] -- i = 0
			jj = m[6] -- j = 1
			kk = m[11] --k = 2
			kj = m[10]; jk = m[7]
			ji = m[5]; ij = m[2]
			ki = m[9]; ik = m[3]
		elseif i == 1 then
			ii = m[6] -- i = 1
			jj = m[11] -- j = 2
			kk = m[1] -- k = 0
			kj = m[3]; jk = m[9]
			ji = m[10]; ij = m[7]
			ki = m[2]; ik = m[5]
		elseif i == 2 then
			ii = m[11] -- i = 2
			jj = m[1] -- j = 0
			kk = m[6] -- k = 1
			kj = m[2]; jk = m[5]
			ji = m[3]; ij = m[9]
			ki = m[7]; ik = m[10]
		end
		local root = math.sqrt(ii - jj - kk + 1)
		local quat = {}
		quat[i] = root * 0.5
		root = 0.5 / root

		local w = (kj - jk) * root
		quat[j] = (ji + ij) * root
		quat[k] = (ki + ik) * root
	end
end

function Quaternion:ToRotationMatrix()
	local tx = self.x + self.x
	local ty = self.y + self.y
	local tz = self.z + self.z
	
	local twx = tx * self.w
	local twy = ty * self.w
	local twz = tz * self.w

	local txx = tx * self.x
	local txy = ty * self.x
	local txz = tz * self.x

	local tyy = ty * self.y
	local tyz = tz * self.y
	local tzz = tz * self.z

	return Matrix4.Manual(
		1 - (tyy + tzz), txy - twz, txz + twy, 0,
		txy + twz, 1 - (txx + tzz), tyz - twx, 0,
		txz - twy, tyz + twx, 1 - (txx + tyy), 0,
		0, 0, 0, 1
	)
end

function Quaternion.FromEulerAngles(x, y, z)
	if type(x) ~= "number" then
		y = x.y
		z = x.z
		x = x.x
	end

	local c1 = math.cos(x / 2)
	local c2 = math.cos(y / 2)
	local c3 = math.cos(z / 2)
	local s1 = math.sin(x / 2)
	local s2 = math.sin(y / 2)
	local s3 = math.sin(z / 2)

	return Quaternion:New(
		s1 * c2 * c3 + c1 * s2 * s3,
		c1 * s2 * c3 - s1 * c2 * s3,
		c1 * c2 * s3 + s1 * s2 * c3,
		c1 * c2 * c3 - s1 * s2 * s3
	)
end

function Quaternion.FromAngleAxis(angle, axis)
	local half_angle = 0.5 * angle
	local sin = math.sin(half_angle)

	return Quaternion:New(sin * axis.x, sin * axis.y, sin * axis.z, math.cos(half_angle))
end

function Quaternion:ToAngleAxis()
	local len_sqr = (self.x^2) + (self.y^2) + (self.z^2)

	if len_sqr > 0 then
		local angle = 2 * math.acos(self.w)
		local inv_length = 1 / math.sqrt(len_sqr)
		return angle, Vector3:New(self.x * inv_length, self.y * inv_length, self.z * inv_length)
	else
		return 0, Vector3:new(1, 0, 0)
	end
end

function Quaternion.Slerp(a, b, alpha, shortest_path)
	local cos = a:Dot(b)
	local t = Quaternion:New()

	if cos < 0 and shortest_path == true then
		cos = -cos
		t = b * -1
	else
		t = b
	end

	if math.abs(cos) < (1 - 1e-3) then
		local sin = math.sqrt(1 - cos^2)
		local angle = math.atan2(sin, cos)
		local inv_sin = 1 / sin
		local coeff0 = math.sin((1 - alpha) * angle) * inv_sin
		local coeff1 = math.sin(alpha * angle) * inv_sin
		return a:Multiply(coeff0) + coeff1 * t
	else
		t = a:Multiply(1 - alpha) + alpha * t
		t:Normalize()
		return t
	end
end

function Quaternion.Dot(a, b)
	return a.w*b.w+a.x*b.x+a.y*b.y+a.z*b.z
end

function Quaternion:Norm()
	return (self.x^2) + (self.y^2) + (self.z^2) + (self.w^2)
end

function Quaternion:Normalize()
	local length = self:Norm()
	local factor = 1 / math.sqrt(length)
	self.x = self.x * factor
	self.y = self.y * factor
	self.z = self.z * factor
	self.w = self.w * factor
end

function Quaternion:GetInverse()
	local norm = self:GetNorm()
	if norm > 0 then
		local inv_norm = 1 / norm
		return Quaternion:New(-x * inv_norm, -y * inv_norm, -z * inv_norm, w * inv_norm)
	else
		return nil
	end
end

function Quaternion:TransformVector(vec)
	local uv, uuv
	local q_vec = Vector3:New(self.x, self.y, self.z)
	uv = q_vec:Cross(vec)
	uuv = q_vec:Cross(uv)
	uv = uv * (self.w * 2)
	uuv = uuv * 2

	return (vec + uv + uuv)
end

function Quaternion.Add(a, b)
	return Quaternion:New(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)
end

function Quaternion.Subtract(a, b)
	return Quaternion:New(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w)
end

function Quaternion.Multiply(a, b)
	if type(a) == 'number' then
		return Quaternion.Multiply(b, a)
	end
	if type(b) == 'number' then
		return Quaternion:New(a.x * b, a.y * b, a.z * b, a.w * b)
	end
	if b.GetClass and b:GetClass() == Vector3 then
		return a:TransformVector(b)
	end

	return Quaternion:New(
		a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
		a.w * b.y + a.y * b.w + a.z * b.x - a.x * b.z,
		a.w * b.z + a.z * b.w + a.x * b.y - a.y * b.x,
		a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
	)
end

function Quaternion:ToString()
	return ("(%s, %s, %s, %s)"):format(self.x, self.y, self.z, self.w)
end

Quaternion:AddMetamethods({
	__add = function(a, b)
		return Quaternion.Add(a, b)
	end,
	__sub = function(a, b)
		return Quaternion.Subtract(a, b)
	end,
	__mul = function(a, b)
		return Quaternion.Multiply(a, b)
	end,
	__div = function(a, b)
		return Quaternion.Divide(a, b)
	end
})

return Quaternion