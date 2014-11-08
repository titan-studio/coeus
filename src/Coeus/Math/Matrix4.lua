--[[
	4x4 Matrix

	Defines transforms using a 4x4 matrix.

	TODO:
	- Rewrite constructor to use varargs
	- Remove Matrix4.Manual
	- Refactor to use cdata
]]

local Coeus = (...)
local OOP = Coeus.Utility.OOP
local Vector3 = Coeus.Math.Vector3

local Matrix4 = OOP:Class() {
	m = {}
}

--[[
	Creates a new matrix given a sequence of values.
]]
--Debug initializer
function Matrix4:DEBUG__new(...)
	local err = "Matrix4:New accepts 16 Lua number parameters."
	local count = select("#", ...)

	if (count == 0) then
		self.m = {}
		return
	end

	if (count ~= 16) then
		return Coeus:Error(err, "Coeus.Math.Matrix4:DEBUG__new")
	end

	for i = 1, count do
		if (type(select(i, ...)) ~= "number") then
			return Coeus:Error((err .. " Argument #%d is of type '%s'"):format(i, type(select(i, ...))))
		end
	end

	self.m = {...}
end

--Release initializer
function Matrix4:RELEASE__new(...)
	self.m = {...}
end

if (Coeus.Config.Debug) then
	Matrix4._new = Matrix4.DEBUG__new
else
	Matrix4._new = Matrix4.RELEASE__new
end

function Matrix4:Identity()
	return self:New(
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	)
end

function Matrix4:Filled(v)
	return self:New(
		v, v, v, v,
		v, v, v, v,
		v, v, v, v,
		v, v, v, v
	)
end

--[[
	Returns the inverse of the matrix.
]]
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

--[[
	Adds two Matrix4 objects together
]]
function Matrix4.Add(a, b, out)
	local out = out or Matrix4:New()
	local outm, am, bm = out.m, a.m, b.m

	for i = 1, 16 do
		outm[i] = am[i] + bm[i]
	end

	return out
end

--[[
	Multiplies two Matrix4 objects together
]]
function Matrix4.Multiply(a, b)
	local r = {}
	a = a.m
	b = b.m
	r[1] = b[1]*a[1] + b[2]*a[5] + b[3]*a[9] + b[4]*a[13]
	r[2] = b[1]*a[2] + b[2]*a[6] + b[3]*a[10] + b[4]*a[14]
	r[3] = b[1]*a[3] + b[2]*a[7] + b[3]*a[11] + b[4]*a[15]
	r[4] = b[1]*a[4] + b[2]*a[8] + b[3]*a[12] + b[4]*a[16]

	r[5] = b[5]*a[1] + b[6]*a[5] + b[7]*a[9] + b[8]*a[13]
	r[6] = b[5]*a[2] + b[6]*a[6] + b[7]*a[10] + b[8]*a[14]
	r[7] = b[5]*a[3] + b[6]*a[7] + b[7]*a[11] + b[8]*a[15]
	r[8] = b[5]*a[4] + b[6]*a[8] + b[7]*a[12] + b[8]*a[16]

	r[9] = b[9]*a[1] + b[10]*a[5] + b[11]*a[9] + b[12]*a[13]
	r[10] = b[9]*a[2] + b[10]*a[6] + b[11]*a[10] + b[12]*a[14]
	r[11] = b[9]*a[3] + b[10]*a[7] + b[11]*a[11] + b[12]*a[15]
	r[12] = b[9]*a[4] + b[10]*a[8] + b[11]*a[12] + b[12]*a[16]

	r[13] = b[13]*a[1] + b[14]*a[5] + b[15]*a[9] + b[16]*a[13]
	r[14] = b[13]*a[2] + b[14]*a[6] + b[15]*a[10] + b[16]*a[14]
	r[15] = b[13]*a[3] + b[14]*a[7] + b[15]*a[11] + b[16]*a[15]
	r[16] = b[13]*a[4] + b[14]*a[8] + b[15]*a[12] + b[16]*a[16]

	return Matrix4:New(r)
end

--[[
	Returns a Matrix4 that is the transpose of the one given.
]]
function Matrix4.GetTranspose(a)
	local m = {}

	--[[
	1 	2 	3 	4
	5	6	7	8
	9	10	11	12
	13	14	15	16

	]]

	m[1] = a.m[1]
	m[2] = a.m[5] 
	m[3] = a.m[9] 
	m[4] = a.m[13]

	m[5] = a.m[2]
	m[6] = a.m[6]
	m[7] = a.m[10]
	m[8] = a.m[14]

	m[9]  = a.m[8]
	m[10] = a.m[7]
	m[11] = a.m[11]
	m[12] = a.m[15]

	m[13] = a.m[4]
	m[14] = a.m[8]
	m[15] = a.m[12]
	m[16] = a.m[16]

	return Matrix4:New(m)
end

--[[
	Returns a Vector3 corresponding to up
]]
function Matrix4:GetUpVector()
	return Vector3:New(self.m[5], self.m[6], self.m[7])
end

--[[
	Returns a Vector3 corresponding to right
]]
function Matrix4:GetRightVector()
	return Vector3:New(self.m[1], self.m[2], self.m[3])
end

--[[
	Returns a Vector3 corresponding to forward
]]
function Matrix4:GetForwardVector()
	return Vector3:New(self.m[9], self.m[10], self.m[11])
end

function Matrix4:TransformPoint(vec)
	--This function may not be correct (or at least what is expected.)
	--Further investigation may be necessary
	local m = self.m
	local inv_w = 1 / (m[13]*vec.x + m[14]*vec.y + m[15]*vec.z + m[16])
	return Vector3:New(
		(m[1]*vec.x + m[2]*vec.y + m[3]*vec.z + m[4])*inv_w,
		(m[5]*vec.x + m[6]*vec.y + m[7]*vec.z + m[8])*inv_w,
		(m[9]*vec.x + m[10]*vec.y + m[11]*vec.z + m[12])*inv_w
	)
end

function Matrix4:TransformVector3(vec)
	return Vector3:New(
		m[1]*vec.x + m[2]*vec.y + m[3]*vec.z,
		m[5]*vec.x + m[6]*vec.y + m[7]*vec.z,
		m[9]*vec.x + m[10]*vec.y + m[11]*vec.z
	)
end

function Matrix4:GetValues()
	return m
end

function Matrix4.GetTranslation(vector)
	if vector.Is[Vector3] then
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
	return Matrix4:New({
		1, 0, 0, 0,
		0, math.cos(angle), math.sin(angle), 0,
		0, -math.sin(angle), math.cos(angle), 0,
		0, 0, 0, 1
	})
end
function Matrix4.GetRotationY(angle)
	return Matrix4:New({
		math.cos(angle), 0, -math.sin(angle), 0,
		0, 1, 0, 0,
		math.sin(angle), 0, math.cos(angle), 0,
		0, 0, 0, 1
	})
end
function Matrix4.GetRotationZ(angle)
	return Matrix4:New({
		math.cos(angle), math.sin(angle), 0, 0,
		-math.sin(angle), math.cos(angle), 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	})
end

function Matrix4.GetScale(vector)
	return Matrix4:New({
		vector.x, 0, 0, 0,
		0, vector.y, 0, 0,
		0, 0, vector.z, 0,
		0, 0, 0, 1
	})
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

function Matrix4.GetOrthographic(left, right, top, bottom, near, far)
	local m = {}

	m[1] = 2 / (right - left)
	m[2] = 0 
	m[3] = 0 
	m[4] = 0

	m[5] = 0
	m[6] = 2 / (top - bottom)
	m[7] = 0 
	m[8] = 0

	m[9]  = 0 
	m[10] = 0
	m[11] = -2 / (far - near)
	m[12] = 0

	m[13] = -((right + left) / (right - left))
	m[14] = -((top + bottom) / (top - bottom))
	m[15] = -((far + near) / (far - near))
	m[16] = 1

	return Matrix4:New(m)
end

function Matrix4.Compare(a, b)
	local ma, mb = a.m, b.m
	for i = 1, 16 do
		if (ma[i] ~= mb[i]) then
			return false
		end
	end

	return true
end

function Matrix4:ToString()
	local longest = 0
	local m = self.m

	for i = 1, 16 do
		local len = #tostring(m[i])
		if (len > longest) then
			longest = len
		end
	end

	local buffer = {}
	for i = 1, 16 do
		local mi = tostring(m[i])
		local len = #tostring(mi)
		table.insert(buffer, mi .. (" "):rep(longest - len))
	end

	local matrix = ("|%s %s %s %s|\n"):rep(4):format(unpack(buffer))
	return matrix:sub(1, #matrix - 1)
end

Matrix4:AddMetamethods({
	__mul = function(a, b)
		if (b.Is[Vector3]) then
			return Matrix4.TransformPoint(a, b)
		else
			return Matrix4.Multiply(a, b)
		end
	end

})

return Matrix4