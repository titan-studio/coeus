local Coeus = (...)
local oop = Coeus.Utility.OOP

local Matrix4 = oop:Class() {
	m = {}
}

function Matrix4:_new(values)
	if values then
		for i=0,15 do
			self.m[i] = values[i]
		end
	else
		for i=0,15 do
			self.m[i] = 0
		end
		self.m[0] = 1
		self.m[5] = 1
		self.m[10] = 1
		self.m[15] = 1
	end
end

function Matrix4.Manual(...)
	local vals = {...}
	local m = {}
	for i=0,15 do
		m[i] = vals[i+1]
	end
	return Matrix4:New(m)
end

function Matrix4:Multiply(mat_a, mat_b)
	local a = mat_a.m
	local b = mat_b.m
	local r = {}
	r[0] = a[0] * b[0] + a[1] * b[4] + a[2] * b[8] + a[3] * b[12]
	r[1] = a[0] * b[1] + a[1] * b[5] + a[2] * b[9] + a[3] * b[13]
	r[2] = a[0] * b[2] + a[1] * b[6] + a[2] * b[10] + a[3] * b[14]
	r[3] = a[0] * b[3] + a[1] * b[7] + a[2] * b[11] + a[3] * b[15]

	r[4] = a[4] * b[0] + a[5] * b[4] + a[6] * b[8] + a[7] * b[12]
	r[5] = a[4] * b[1] + a[5] * b[5] + a[6] * b[9] + a[7] * b[13]
	r[6] = a[4] * b[2] + a[5] * b[6] + a[6] * b[10] + a[7] * b[14]
	r[7] = a[4] * b[3] + a[5] * b[7] + a[6] * b[11] + a[7] * b[15]

	r[8] = a[8] * b[0] + a[9] * b[4] + a[10] * b[8] + a[11] * b[12]
	r[9] = a[8] * b[1] + a[9] * b[5] + a[10] * b[9] + a[11] * b[13]
	r[10] = a[8] * b[2] + a[9] * b[6] + a[10] * b[10] + a[11] * b[14]
	r[11] = a[8] * b[3] + a[9] * b[7] + a[10] * b[11] + a[11] * b[15]

	r[12] = a[12] * b[0] + a[13] * b[4] + a[14] * b[8] + a[15] * b[12]
	r[13] = a[12] * b[1] + a[13] * b[5] + a[14] * b[9] + a[15] * b[13]
	r[14] = a[12] * b[2] + a[13] * b[6] + a[14] * b[10] + a[15] * b[14]
	r[15] = a[12] * b[3] + a[13] * b[7] + a[14] * b[11] + a[15] * b[15]

	return Matrix4:New(r)
end

function Matrix4:GetValues()
	return m
end

function Matrix4.GetTranslation(vector)
	local out = Matrix4:New()
	out.m[12] = vector.x
	out.m[13] = vector.y
	out.m[14] = vector.z
	return out
end

function Matrix4.GetRotationY(angle)
	return Matrix4.Manual(
		math.cos(angle), 0, -math.sin(angle), 0,
		0, 1, 0, 0,
		math.sin(angle), 0, math.cos(angle), 0,
		0, 0, 0, 1
	)
end

function Matrix4.GetPerspective(fov, near, far, aspect)
	local m = {}
	local y_scale = 1.0 / math.tan(math.rad(fov) / 2)
	local x_scale = y_scale / aspect
	local range =  far - near

	m[0] = x_scale
	m[1] = 0 
	m[2] = 0 
	m[3] = 0 

	m[4] = 0
	m[5] = y_scale
	m[6] = 0 
	m[7] = 0 

	m[8] = 0 
	m[9] = 0
	m[10] = (far + near) / range
	m[11] = -1 

	m[12] = 0 
	m[13] = 0
	m[14] = 2*far*near / range
	m[15] = 0

	return Matrix4:New(m)
end

return Matrix4