--[[
	IQE Loader

	Loads IQE models (.iqe)
]]

local C = (...)
local Coeus = C:Get("Coeus")
local ffi = require("ffi")

local OOP = Coeus.Utility.OOP
local ModelData = Coeus.Asset.Model.ModelData
local MeshData = Coeus.Asset.Model.MeshData
local ModelJoint = Coeus.Graphics.ModelJoint

local IQE = OOP:Static(Coeus.Asset.Format)()

--This file is partly adapted from the Lua IQE Loader written by
--Landon Manning and Colby Klein.
--
--Copyright (c) 2014 Landon Manning - LManning17@gmail.com - LandonManning.com
--Copyright (c) 2014 Colby Klein - shakesoda@gmail.com - excessive.moe
--
--https://github.com/karai17/Lua-IQE-Loader/blob/master/iqe.lua

-- http://wiki.interfaceware.com/534.html
local function string_split(s, d)
	local t = {}
	local i = 0
	local f
	local match = '(.-)' .. d .. '()'
	
	if string.find(s, d) == nil then
		return {s}
	end
	
	for sub, j in string.gmatch(s, match) do
		i = i + 1
		t[i] = sub
		f = j
	end
	
	if i ~= 0 then
		t[i+1] = string.sub(s, f)
	end
	
	return t
end

local function merge_quoted(t)
	local ret = {}
	local merging = false
	local buf = ""
	for k, v in ipairs(t) do
		local f, l = v:sub(1,1), v:sub(v:len())
		if f == "\"" and l ~= "\"" then
			merging = true
			buf = v
		else
			if merging then
				buf = buf .. " " .. v
				if l == "\"" then
					merging = false
					table.insert(ret, buf:sub(2,-2))
				end
			else
				if f == "\"" and l == f then
					table.insert(ret, v:sub(2, -2))
				else
					table.insert(ret, v)
				end
			end
		end
	end
	return ret
end

local Commands = {}
function Commands:mesh(args)
	args = merge_quoted(args)

	self.current_mesh = MeshData:New()
	self.current_mesh.Name = args[1]
	table.insert(self.model.Meshes, self.current_mesh)
end
function Commands:material(args)
	args = merge_quoted(args)
	self.data.material = self.data.material or {}
	self.data.material[args[1]] = self.data.material[args[1]] or {}
	table.insert(self.data.material[args[1]], self.current_mesh)
	self.current_material = self.data.material[args[1]]
	self.current_mesh.Material = self.current_material
end

--The following four commands build the vertex buffer for the active mesh
function Commands:vp(args)
	local mesh = self.current_material[#self.current_material]
	for i, v in ipairs(args) do
		table.insert(mesh.Vertices, tonumber(v))
	end
	mesh.Format.Positions = true
	self.model.VertexCount = self.model.VertexCount + 1
end
function Commands:vt(args)
	local mesh = self.current_material[#self.current_material]
	for i, v in ipairs(args) do
		table.insert(mesh.Vertices, tonumber(v))
	end
	mesh.Format.TexCoords = true
end
function Commands:vn(args)
	local mesh = self.current_material[#self.current_material]
	for i, v in ipairs(args) do
		table.insert(mesh.Vertices, tonumber(v))
	end
	mesh.Format.Normals = true
end
function Commands:vb(args)
	local mesh = self.current_material[#self.current_material]
	for i, v in ipairs(args) do
		if i % 2 ~= 0 then
			table.insert(mesh.Vertices, tonumber(v))
		end
	end
	for i, v in ipairs(args) do
		if i % 2 == 0 then
			table.insert(mesh.Vertices, tonumber(v))
		end
	end
	mesh.Format.BoneIDs = true
	mesh.Format.BoneWeights = true
end
function Commands:vc(args)
	local mesh = self.current_material[#self.current_material]
	for i, v in ipairs(args) do
		table.insert(mesh.Vertices, tonumber(v))
	end
	mesh.Format.Color = true
end

function Commands:vertexarray(args)
	args = merge_quoted(args)

	--to be implemented (maybe)
end

function Commands:fa(args)
	local mesh = self.current_material[#self.current_material]
	
	--to be implemented (maybe)
end
function Commands:fm(args)
	local mesh = self.current_material[#self.current_material]
	if not mesh.Indices then
		mesh.Indices = {}
	end
	for i, v in ipairs(args) do
		table.insert(mesh.Indices, tonumber(v))
		self.model.TriangleCount = self.model.TriangleCount + 1
	end
end

function Commands:smoothuv(args)
	local mesh = self.current_material[#self.current_material]
	local n = tonumber(args[1])
	mesh.SmoothByUV = false

	if n > 0 then
		mesh.SmoothByUV = true
	end
end
function Commands:smoothgroup(args)
	local mesh = self.current_material[#self.current_material]
	local n = tonumber(args[1])
	mesh.SmoothingGroup = -1

	if n then
		mesh.SmoothingGroup = n
	end
end
function Commands:smoothangle(args)
	local mesh = self.current_material[#self.current_material]
	local angle = tonumber(args[1])
	mesh.SmoothingAngle = math.rad(180)

	if angle then
		mesh.SmoothingAngle = math.rad(angle)
	end
end
function Commands:fs(args)
	local mesh = self.current_material[#self.current_material]
	mesh.fs = mesh.fs or {}
	local fs = {}
	for i, v in ipairs(args) do
		table.insert(fs, tonumber(v))
	end
	table.insert(mesh.fs, fs)
end
function Commands:vs(args)
	local mesh = self.current_material[#self.current_material]
	mesh.vs = mesh.vs or {}
	local vs = tonumber(args[1])
	table.insert(mesh.vs, vs)
end

function Commands:pq(args)
	--First off, let's build the translation, rotation, and scale
	local pose = {}
	local data = {}
	for i, v in ipairs(args) do
		data[i] = tonumber(v)
	end

	if #data == 6 then
		table.insert(data, -1)
	end
	
	pose.Translation = Vector3:New(data[1], data[2], data[3])
	pose.Rotation = Quaternion:New(data[4], data[5], data[6], data[7])
	pose.Scale = Vector3:New(data[8] or 1, data[9] or 1, data[10] or 1)

	if not self.current_animation then
		self.current_joint.Pose = pose
	else
		table.insert(self.current_frame.Poses, pose)
	end
end
function Commands:pm(args)
	local pose = {}
	local data = {}
	for i, v in ipairs(args) do
		data[i] = tonumber(v)
	end

	local m = {}
	local j = 1
	for i = 4, 12, 3 do
		m[j] = data[i + 0]
		m[j + 1] = data[i + 1]
		m[j + 2] = data[i + 2]
		m[j + 3] = 0

		j = j + 4
	end
	table.insert(m, 0)
	table.insert(m, 0)
	table.insert(m, 0)
	table.insert(m, 1)

	pose.Translation = Vector3:New(data[1], data[2], data[3])
	pose.Rotation = Quaternion.FromMatrix4(Matrix4:New(m))
	pose.Scale = Vector3:New(data[13] or 1, data[14] or 1, data[15] or 1)

	if not self.current_animation then
		self.current_joint.Pose = pose
	else
		table.insert(self.current_frame.Poses, pose)
	end
end
function Commands:pa(args)
	local pose = {}
	local data = {}
	for i, v in ipairs(args) do
		data[i] = tonumber(v)
	end

	pose.Translation = Vector3:New(data[1], data[2], data[3])
	pose.Rotation = Quaternion.FromEulerAngles(data[4], data[5], data[6])
	pose.Scale = Vector3:New(data[7] or 1, data[8] or 1, data[9] or 1)

	if not self.current_animation then
		self.current_joint.Pose = pose
	else
		table.insert(self.current_frame.Poses, pose)
	end
end

function Commands:joint(args)
	args = merge_quoted(args)

	local joint = ModelJoint:New()
	joint.Name = args[1]
	joint.Parent = self.model.Joints[tonumber(args[2]) + 1] or false
	joint.Model = self.model
	table.insert(self.model.Joints, joint)

	self.current_joint = joint
end

function Commands:animation(args)
	args = merged_quote(args)

	local name = args[1] or tostring(self.last_anim_num)
	self.last_anim_num = self.last_anim_num + 1

	self.model.Animations[name] = ModelAnimation:New()
	self.current_animation = self.model.Animations[name]
	self.current_animation.Name = name
	self.current_animation.Model = self.model
	self.current_frame = false
end
function Commands:loop(args)
	self.current_animation.Looping = true
end
function Commands:framerate(args)
	self.current_animation.Framerate = tonumber(args[1])
end
function Commands:frame(args)
	local animation = self.current_animation
	table.insert(animation.Frames, {})
	self.current_frame = animation.Frames[#animation.Frames]
end

function IQE:Load(filename)
	local file, err = io.open(filename, 'r')
	if not file then
		print("Error opening IQE file for loading: " .. err)
	end

	local line_num = 0
	local line_str = ""
	local more
	local line = file:read("*l")

	local out = ModelData:New()
	local state = {
		current_mesh = false,
		current_material = false,
		current_joint = false,
		current_animation = false,
		current_frame = false,
		current_vertexarray = false,

		last_anim_num = 1,

		data = {},
		materials = {},
		model = out
	}

	while line do
		line_num = line_num + 1
		if more then
			line_str = line_str .. line
		else
			line_str = line
		end

		if line:find("\\$") then
			more = true
		else
			--pass it off to a command
			line_str = line_str:gsub("^%s*(.-)%s*$", "%1")
			local split = string_split(line_str, " ")
			local cmd = split[1]
			local func = Commands[cmd]
			if cmd and func then
				table.remove(split, 1)
				func(state, split)
			end
		end
		line = file:read("*l")
	end

	return out
end

function IQE:Match(filename)
	return not not filename:match("%.iqe$")
end

return IQE