local Coeus = (...)
local oop = Coeus.Utility.OOP
local Vector3 = Coeus.Math.Vector3

local Matrix4 = oop:Class() {
	m = {}
}

function Matrix4:_new(values)
	if values then
		for i=1, 16 do
			self.m[i] = values[i]
		end
	else
		for i=1, 16 do
			self.m[i] = 0
		end
		self.m[1] = 1
		self.m[6] = 1
		self.m[11] = 1
		self.m[16] = 1
	end
end

function Matrix4.Manual(...)
	local vals = {...}
	local m = {}
	for i=1, 16 do
		m[i] = vals[i]
	end
	return Matrix4:New(m)
end

function Matrix4:GetInverse()
	local r = {}
	local m = self.m
	r[1 ] =  m[6]*m[11]*m[16] - m[6]*m[15]*m[12] - m[7]*m[10]*m[16] + m[7]*m[14]*m[12] + m[8]*m[10]*m[15] - m[8]*m[14]*m[11]
	r[2 ] = -m[2]*m[11]*m[16] + m[2]*m[15]*m[12] + m[3]*m[10]*m[16] - m[3]*m[14]*m[12] - m[4]*m[10]*m[15] + m[4]*m[14]*m[11]
	r[3 ] =  m[2]*m[7 ]*m[16] - m[2]*m[15]*m[8 ] - m[3]*m[6 ]*m[16] + m[3]*m[14]*m[8 ] + m[4]*m[6 ]*m[15] - m[4]*m[14]*m[7 ]
	r[4 ] = -m[2]*m[7 ]*m[12] + m[2]*m[11]*m[8 ] + m[3]*m[6 ]*m[12] - m[3]*m[10]*m[8 ] - m[4]*m[6 ]*m[11] + m[4]*m[10]*m[7 ]

	r[5 ] = -m[5]*m[11]*m[16] + m[5]*m[15]*m[12] + m[7]*m[9 ]*m[16] - m[7]*m[13]*m[12] - m[8]*m[9 ]*m[15] + m[8]*m[13]*m[11]
	r[6 ] =  m[1]*m[11]*m[16] - m[1]*m[15]*m[12] - m[3]*m[9 ]*m[16] + m[3]*m[13]*m[12] + m[4]*m[9 ]*m[15] - m[4]*m[13]*m[11]
	r[7 ] = -m[1]*m[7 ]*m[16] + m[1]*m[15]*m[8 ] + m[3]*m[5 ]*m[16] - m[3]*m[13]*m[8 ] - m[4]*m[5 ]*m[15] + m[4]*m[13]*m[7 ]
	r[8 ] =  m[1]*m[7 ]*m[12] - m[1]*m[11]*m[8 ] - m[3]*m[5 ]*m[12] + m[3]*m[9 ]*m[8 ] + m[4]*m[5 ]*m[11] - m[4]*m[9 ]*m[7 ]

	r[9 ] =  m[5]*m[10]*m[16] - m[5]*m[14]*m[12] - m[6]*m[9 ]*m[16] + m[6]*m[13]*m[12] + m[8]*m[9 ]*m[14] - m[8]*m[13]*m[10]
	r[10] = -m[1]*m[10]*m[16] + m[1]*m[14]*m[12] + m[2]*m[9 ]*m[16] - m[2]*m[13]*m[12] - m[4]*m[9 ]*m[14] + m[4]*m[13]*m[10]
	r[11] =  m[1]*m[6 ]*m[16] - m[1]*m[14]*m[8 ] - m[2]*m[5 ]*m[16] + m[2]*m[13]*m[8 ] + m[4]*m[5 ]*m[14] - m[4]*m[13]*m[6 ]
	r[12] = -m[1]*m[6 ]*m[12] + m[1]*m[10]*m[8 ] + m[2]*m[5 ]*m[12] - m[2]*m[9 ]*m[8 ] - m[4]*m[5 ]*m[10] + m[4]*m[9 ]*m[6 ]

	r[13] = -m[5]*m[10]*m[15] + m[5]*m[14]*m[11] + m[6]*m[9 ]*m[15] - m[6]*m[13]*m[11] - m[7]*m[9 ]*m[14] + m[7]*m[13]*m[10]
	r[14] =  m[1]*m[10]*m[15] - m[1]*m[14]*m[11] - m[2]*m[9 ]*m[15] + m[2]*m[13]*m[11] + m[3]*m[9 ]*m[14] - m[3]*m[13]*m[10]
	r[15] = -m[1]*m[6 ]*m[15] + m[1]*m[14]*m[7 ] + m[2]*m[5 ]*m[15] - m[2]*m[13]*m[7 ] - m[3]*m[5 ]*m[14] + m[3]*m[13]*m[6 ]
	r[16] =  m[1]*m[6 ]*m[11] - m[1]*m[10]*m[7 ] - m[2]*m[5 ]*m[11] + m[2]*m[9 ]*m[7 ] + m[3]*m[5 ]*m[10] - m[3]*m[9 ]*m[6 ]

	local det = m[1]*r[1] + m[2]*r[5] + m[3]*r[9] + m[4]*r[13]

	for i = 1, 16 do
		r[i] = r[i] / det
	end

	return Matrix4:New(r)
end

function Matrix4.Multiply(b, a)
	local a = a.m
	local b = b.m
	local r = {}
	r[1] = a[1] * b[1] + a[2] * b[5] + a[3] * b[9] + a[4] * b[13]
	r[2] = a[1] * b[2] + a[2] * b[6] + a[3] * b[10] + a[4] * b[14]
	r[3] = a[1] * b[3] + a[2] * b[7] + a[3] * b[11] + a[4] * b[15]
	r[4] = a[1] * b[4] + a[2] * b[8] + a[3] * b[12] + a[4] * b[16]

	r[5] = a[5] * b[1] + a[6] * b[5] + a[7] * b[9] + a[8] * b[13]
	r[6] = a[5] * b[2] + a[6] * b[6] + a[7] * b[10] + a[8] * b[14]
	r[7] = a[5] * b[3] + a[6] * b[7] + a[7] * b[11] + a[8] * b[15]
	r[8] = a[5] * b[4] + a[6] * b[8] + a[7] * b[12] + a[8] * b[16]

	r[9] = a[9] * b[1] + a[10] * b[5] + a[11] * b[9] + a[12] * b[13]
	r[10] = a[9] * b[2] + a[10] * b[6] + a[11] * b[10] + a[12] * b[14]
	r[11] = a[9] * b[3] + a[10] * b[7] + a[11] * b[11] + a[12] * b[15]
	r[12] = a[9] * b[4] + a[10] * b[8] + a[11] * b[12] + a[12] * b[16]

	r[13] = a[13] * b[1] + a[14] * b[5] + a[15] * b[9] + a[16] * b[13]
	r[14] = a[13] * b[2] + a[14] * b[6] + a[15] * b[10] + a[16] * b[14]
	r[15] = a[13] * b[3] + a[14] * b[7] + a[15] * b[11] + a[16] * b[15]
	r[16] = a[13] * b[4] + a[14] * b[8] + a[15] * b[12] + a[16] * b[16]

	return Matrix4:New(r)
end

function Matrix4:GetUpVector()
	return Vector3:New(self.m[5], self.m[6], self.m[7])
end

function Matrix4:GetRightVector()
	return Vector3:New(self.m[1], self.m[2], self.m[3])
end

function Matrix4:GetForwardVector()
	return Vector3:New(self.m[9], self.m[10], self.m[11])
end

function Matrix4:TransformPoint(vec)
	--This function may not be correct (or at least what is expected.)
	--Further investigation may be necessary
	local m = self.m
	local inv_w = 1 / (m[13] * vec.x + m[14] * vec.y + m[15] * vec.z + m[16])
	return Vector3:New(
		(m[1] * vec.x + m[2] * vec.y + m[3] * vec.z + m[4]) * inv_w,
		(m[5] * vec.x + m[6] * vec.y + m[7] * vec.z + m[8]) * inv_w,
		(m[9] * vec.x + m[10] * vec.y + m[11] * vec.z + m[12]) * inv_w
	)
end

function Matrix4:TransformVector3(vec)
	return Vector3:New(
		m[1] * vec.x + m[2] * vec.y + m[3] * vec.z,
		m[5] * vec.x + m[6] * vec.y + m[7] * vec.z,
		m[9] * vec.x + m[10] * vec.y + m[11] * vec.z
	)
end

function Matrix4:GetValues()
	return m
end

function Matrix4.GetTranslation(vector)
	if vector:GetClass() == Vector3 then
		local out = Matrix4:New()
		out.m[13] = vector.x
		out.m[14] = vector.y
		out.m[15] = vector.z
		out.m[16] = 1
		return out
	else
		return Vector3:New(vector.m[13], vector.m[14], vector.m[15])
	end
end

function Matrix4.GetRotationX(angle)
	return Matrix4.Manual(
		1, 0, 0, 0,
		0, math.cos(angle), math.sin(angle), 0,
		0, -math.sin(angle), math.cos(angle), 0,
		0, 0, 0, 1
	)
end
function Matrix4.GetRotationY(angle)
	return Matrix4.Manual(
		math.cos(angle), 0, -math.sin(angle), 0,
		0, 1, 0, 0,
		math.sin(angle), 0, math.cos(angle), 0,
		0, 0, 0, 1
	)
end
function Matrix4.GetRotationZ(angle)
	return Matrix4.Manual(
		math.cos(angle), math.sin(angle), 0, 0,
		-math.sin(angle), math.cos(angle), 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	)
end

function Matrix4.GetScale(vector)
	return Matrix4.Manual(
		vector.x, 0, 0, 0,
		0, vector.y, 0, 0,
		0, 0, vector.z, 0,
		0, 0, 0, 1
	)
end

function Matrix4.GetPerspective(fov, near, far, aspect)
	local m = {}
	local y_scale = 1.0 / math.tan(math.rad(fov) / 2)
	local x_scale = y_scale / aspect
	local range =  near - far

	m[1] = x_scale
	m[2] = 0 
	m[3] = 0 
	m[4] = 0 

	m[5] = 0
	m[6] = y_scale
	m[7] = 0 
	m[8] = 0 

	m[9] = 0 
	m[10] = 0
	m[11] = (far + near) / range
	m[12] = -1 

	m[13] = 0 
	m[14] = 0
	m[15] = 2*far*near / range
	m[16] = 0

	return Matrix4:New(m)
end

Matrix4:AddMetamethods({
	__mul = function(a, b)
		if b:GetClass() == Vector3 then
			return Matrix4.TransformPoint(a, b)
		else
			return Matrix4.Multiply(a, b)
		end
	end

})

return Matrix4