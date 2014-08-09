local Coeus 		= (...)
local oop			= Coeus.Utility.OOP
local Mesh			= Coeus.Graphics.Mesh

local Vector3 		= Coeus.Math.Vector3

local OBJLoader = oop:Class() {
	vertices = {},
	normals = {},
	texcoords = {},

	faces = {},

	mesh = false
}

function OBJLoader:_new(filename)
	local file, err = io.open(filename, 'r')
	if not file then
		print("Error opening OBJ file for loading: " .. err)
	end

	--Do some parsing
	local line_num = 0
	local line_str = ""
	local more
	local line = file:read("*l")
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
			self:ParseLine(line_str)
		end
		line = file:read("*l")
	end

	--And then play the matching game
	local vertex_data = {}
	local index_data = {}
	local vertex_index = 0
	for i, face in ipairs(self.faces) do
		for j = 1, #face do
			local point = face[j]
			local vertex = self.vertices[point.v] or Vector3:New()
			local texcoord = self.texcoords[point.t] or Vector3:New()
			local normal = self.normals[point.n] or Vector3:New()

			vertex_data[#vertex_data + 1] = vertex.x
			vertex_data[#vertex_data + 1] = vertex.y
			vertex_data[#vertex_data + 1] = vertex.z
 	
 			vertex_data[#vertex_data + 1] = texcoord.x
			vertex_data[#vertex_data + 1] = texcoord.y
 
 			vertex_data[#vertex_data + 1] = normal.x
			vertex_data[#vertex_data + 1] = normal.y
			vertex_data[#vertex_data + 1] = normal.z

			index_data[#index_data + 1] = vertex_index
			vertex_index = vertex_index + 1
		end
	end

	local mesh = Mesh:New()
	local mesh_data = Coeus.Asset.Model.MeshData:New()
	mesh_data.Vertices = vertex_data
	mesh_data.Indices = index_data
	mesh_data.Format.TexCoords = true
	mesh_data.Format.Normals = true
	mesh:SetData(mesh_data)

	self.mesh = mesh
end

function OBJLoader:ParseVector3(str)
	local x, y, z = str:match("^(%S+) +(%S+) +(%S+)")
	x = tonumber(x) or 0
	y = tonumber(y) or 0
	z = tonumber(z) or 0

	return Vector3:New(x, y, z)
end

function OBJLoader:ParseVector2(str)
	local x, y, z = str:match("^(%S+) +(%S+)")
	x = tonumber(x) or 0
	y = tonumber(y) or 0

	return {x=x,y=y}
end	

function OBJLoader:ParseLine(line)
	local cmd, arg_str = line:match("^%s*(%S+) +(.*)")
	cmd = cmd and cmd:lower()
	if not cmd or cmd == "#" then
		--comment or empty line
	elseif cmd == 'v' then
		self.vertices[#self.vertices + 1] = self:ParseVector3(arg_str)
	elseif cmd == 'vn' then
		self.normals[#self.normals + 1] = self:ParseVector3(arg_str)
	elseif cmd == 'vt' then
		self.texcoords[#self.texcoords + 1] = self:ParseVector2(arg_str)
	elseif cmd == 'f' then
		local face = {}
		for c in arg_str:gmatch("(%S+)") do
			local v, t, n = c:match("^([^/]+)/?([^/]*)/?([^/]*)")
			
			v = tonumber(v)
			t = tonumber(t)
			n = tonumber(n)

			face[#face + 1] = {
				v = v or 0,
				t = t or 0,
				n = n or 0
			}
			
		end
		
		self.faces[#self.faces + 1] = face
	end
end

function OBJLoader:GetMesh()
	return self.mesh
end

return OBJLoader