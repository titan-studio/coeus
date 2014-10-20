local Coeus = (...)
local ffi = require("ffi")

local OOP = Coeus.Utility.OOP
local ModelData = Coeus.Asset.Model.ModelData
local MeshData = Coeus.Asset.Model.MeshData

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
	self.current_mesh = {}
end
function Commands:material(args)
	args = merge_quoted(args)

	self.data.material = self.data.material or {}
	self.data.material[args[1]] = self.data.material[args[1]] or {}
	table.insert(self.data.material[args[1]], self.current_mesh)
	self.current_material = self.data.material[args[1]]
end

function Commands:vp(args)
	local mesh = self.current_material[#self.current_material]
	mesh.vp = mesh.vp or {}
	local vp = {}
	for i, v in ipairs(args) do
		table.insert(vp, tonumber(v))
	end
	if #vp == 3 then
		table.insert(vp, 1)
	end
	table.insert(mesh.vp, vp)
end
function Commands:vt(args)
	local mesh = self.current_material[#self.current_material]
	mesh.vt = mesh.vt or {}
	local vt = {}
	for i, v in ipairs(args) do
		table.insert(vt, tonumber(v))
	end
	table.insert(mesh.vt, vt)
end
function Commands:vb(args)
	local mesh = self.current_material[#self.current_material]
	self.rigged = true
	mesh.vb = mesh.vb or {}
	local vb = {}
	for i, v in ipairs(args) do
		table.insert(vb, tonumber(v))
	end
	table.insert(mesh.vb, vb)
end

function Commands:v0(args, cmd)
	merge_quoted(args)
	cmd = cmd or "v0"
	local mesh = self.current_material[#self.current_material]
	mesh[cmd] = mesh[cmd] or {}
	local v0 = {}
	for i, v in ipairs(args) do
		table.insert(v0, tonumber(v))
	end
	table.insert(mesh[cmd], v0)
end

function Commands:v1(args)
	Commands.v0(self, args, "v1")
end
function Commands:v2(args)
	Commands.v0(self, args, "v2")
end
function Commands:v3(args)
	Commands.v0(self, args, "v3")
end
function Commands:v4(args)
	Commands.v0(self, args, "v4")
end
function Commands:v5(args)
	Commands.v0(self, args, "v5")
end
function Commands:v6(args)
	Commands.v0(self, args, "v6")
end
function Commands:v7(args)
	Commands.v0(self, args, "v7")
end
function Commands:v8(args)
	Commands.v0(self, args, "v8")
end
function Commands:v9(args)
	Commands.v0(self, args, "v9")
end

function Commands:vertexarray(args)
	args = merge_quoted(args)

	self.data.vertexarray = self.data.vertexarray or {}
	local va = {}
	va.type = args[1]
	va.component = args[2]
	va.size = tonumber(args[3])
	va.name = args[4] or args[1]
	table.insert(self.data.vertexarray, va)
	self.current_vertexarray = self.data.vertexarray[#self.data.vertexarray]
end

function Commands:fa(args)
	local mesh = self.current_material[#self.current_material]
	mesh.fa = mesh.fa or {}
	local fa = {}
	for i, v in ipairs(args) do
		table.insert(fa, tonumber(v))
	end
	table.insert(mesh.fa, fa)
end
function Commands:fm(args)
	local mesh = self.current_material[#self.current_material]
	mesh.fm = mesh.fm or {}
	local fm = {}
	for i, v in ipairs(args) do
		table.insert(fm, tonumber(v))
	end
	table.insert(mesh.fm, fm)
end

function Commands:smoothuv(args)
	local mesh = self.current_material[#self.current_material]
	local n = tonumber(args[1])
	mesh.smoothuv = false

	if n > 0 then
		mesh.smoothuv = true
	end
end
function Commands:smoothgroup(args)
	local mesh = self.current_material[#self.current_material]
	local n = tonumber(args[1])
	mesh.smoothgroup = -1

	if n then
		mesh.smoothgroup = n
	end
end
function Commands:smoothangle(args)
	local mesh = self.current_material[#self.current_material]
	local angle = tonumber(args[1])
	mesh.smoothangle = 180

	if angle then
		mesh.smoothangle = angle
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
	local pq = {}
	for i, v in ipairs(args) do
		table.insert(pq, tonumber(v))
	end
	if #pq == 6 then
		--If there are 6 args, then the pq command was given
		-- Tx Ty Tz Qx Qy Qz
		--and is lacking Qw
 		table.insert(pq, -1)
	end
	if #pq == 7 then
		--If there are 7 args, then the pq command was not given
		--a scale. The scale defaults to 1,1,1.
		table.insert(pq, 1)
		table.insert(pq, 1)
		table.insert(pq, 1)
	end

	local joint
	if not self.current_animation then
		joint = self.current_joint
		joint.pq = pq
	else
		joint = self.current_frame
		joint.pq = joint.pq or {}
		table.insert(joint.pq, pq)
	end
end
function Commands:pm(args)
	local pm = {}
	for i, v in ipairs(args) do
		table.insert(pm, tonumber(v))
	end
	if #pm == 12 then
		--If there are 12 args, then the pm command was given
		-- Tx Ty Tz Ax Ay Az Bx By Bz Cx Cy Cz
		--and is lacking Sx Sy Sz for scale.
		--Scale defaults to 1,1,1.
		table.insert(pm, 1)
		table.insert(pm, 1)
		table.insert(pm, 1)
	end

	local joint
	if not self.current_animation then
		joint = self.current_joint
		joint.pm = pm
	else
		joint = self.current_frame
		joint.pm = joint.pm or {}
		table.insert(joint.pm, pm)
	end
end
function Commands:pa(args)
	local pa = {}
	for i, v in ipairs(args) do
		table.insert(pa, tonumber(v))
	end
	if #pa == 6 then
		--If there are 6 args, the pa command was given
		-- Tx Ty Tz Rx Ry Rz
		--and is lacking Sx Sy Sz. This defaults to 1,1,1
		table.insert(pa, 1)
		table.insert(pa, 1)
		table.insert(pa, 1)
	end

	local joint
	if not self.current_animation then
		joint = self.current_joint
		joint.pa = pa
	else
		joint = self.current_frame
		joint.pa = joint.pa or {}
		table.insert(joint.pa, pa)
	end
end

function Commands:joint(args)
	args = merge_quoted(args)
	self.data.joint = self.data.joint or {}
	local joint = {}
	joint.name = args[1]
	joint.parent = tonumber(args[2]) + 1
	table.insert(self.data.joint, joint)

	self.current_joint = joint
end

function Commands:animation(args)
	args = merged_quote(args)
	self.data.animation = self.data.animation or {}
	local name = args[1] or tostring(math.random(0, 99999))
	self.data.animation[name] = {}
	self.current_animation = self.data.animation[name]
	self.current_frame = false
end
function Commands:loop(args)
	self.current_animation.loop = true
end
function Commands:framerate(args)
	self.current_animation.framerate = tonumber(args[1])
end
function Commands:frame(args)
	local animation = self.current_animation
	animation.frame = animation.frame or {}
	table.insert(animation.frame, {})
	self.current_frame = animation.frame[#animation.frame]
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
	local state = {}
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

	local out = ModelData:New()
	--process the model data...
	return out
end

function IQE:Match(filename)
	return not not filename:match("%.iqe$")
end

return IQE