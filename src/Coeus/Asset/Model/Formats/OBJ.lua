--[[
	OBJ Loader

	Loads OBJ models (.obj)
]]

local Coeus = (...)
local ffi = require("ffi")

local OOP = Coeus.Utility.OOP
local ModelData = Coeus.Asset.Model.ModelData
local MeshData = Coeus.Asset.Model.MeshData

local OBJ = OOP:Static(Coeus.Asset.Format)()

function OBJ:Load(filename)
	local file, err = io.open(filename, 'r')
	if not file then
		print("Error opening OBJ file for loading: " .. err)
	end

	--Do some parsing
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
			self:ParseLine(state, line_str)
		end
		line = file:read("*l")
	end

	local out = ModelData:New()
	for i, mesh in ipairs(state.meshes) do
		local mesh_data = MeshData:New()
		mesh_data.Name = mesh.name
		mesh_data.Format = {
			Positions 	= true,
			TexCoords 	= true,
			Normals 	= true
		}

		local vertex_data = {}
		local index_data = {}
		local vertex_index = 0
		for j, face in ipairs(mesh.faces) do
			for k, point in ipairs(face) do
				local position = mesh.vertices[point.p] or {x=0,y=0,z=0}
				local texcoord = mesh.vertices[point.t] or {x=0,y=0,z=0}
				local normal   = mesh.vertices[point.n] or {x=0,y=0,z=0}

				table.insert(vertex_data, position.x)
				table.insert(vertex_data, position.y)
				table.insert(vertex_data, position.z)

				table.insert(vertex_data, texcoord.x)
				table.insert(vertex_data, texcoord.y)

				table.insert(vertex_data, normal.x)
				table.insert(vertex_data, normal.y)
				table.insert(vertex_data, normal.z)

				table.insert(index_data, vertex_index)
				vertex_index = vertex_index + 1
			end
		end

		mesh_data.Vertices = vertex_data
		mesh_data.Indices = index_data
		table.insert(out.Meshes, mesh_data)
	end

	return out
end

function OBJ:ParseVector3(str)
	local x, y, z = str:match("^(%S+) +(%S+) +(%S+)")
	x = tonumber(x) or 0
	y = tonumber(y) or 0
	z = tonumber(z) or 0

	return {x=x,y=y,z=z}
end

function OBJ:ParseVector2(str)
	local x, y, z = str:match("^(%S+) +(%S+)")
	x = tonumber(x) or 0
	y = tonumber(y) or 0

	return {x=x,y=y}
end	

function OBJ:ParseLine(state, line)
	local cmd, arg_str = line:match("^%s*(%S+) +(.*)")
	cmd = cmd and cmd:lower()
	if not cmd or cmd == "#" then
		--comment or empty line
	elseif cmd == "o" then
		local mesh = {
			name = arg_str,
			positions = {},
			texcoords = {},
			normals = {},
			faces = {}
		}
		state.meshes[#state.meshes + 1] = mesh
		state.current_mesh = mesh
	elseif cmd == "v" then
		state.current_mesh.positions[#state.current_mesh.positions + 1] = self:ParseVector3(arg_str)
	elseif cmd == "vt" then
		state.current_mesh.texcoords[#state.current_mesh.texcoords + 1] = self:ParseVector2(arg_str)
	elseif cmd == "vn" then
		state.current_mesh.normals[#state.current_mesh.normals + 1] = self:ParseVector3(arg_str)
	elseif cmd == "f" then
		local face = {}
		for c in arg_str:gmatch("(%S+)") do
			local p, t, n = c:match("^([^/]+)/?([^/]*)/?([^/]*)")
			
			p = tonumber(p)
			t = tonumber(t)
			n = tonumber(n)

			face[#face + 1] = {
				p = p or 0,
				t = t or 0,
				n = n or 0
			}
			
		end
		
		state.current_mesh.faces[#state.current_mesh.faces + 1] = face
	end
end

function OBJ:Match(filename)
	return not not filename:match("%.obj$")
end

return OBJ