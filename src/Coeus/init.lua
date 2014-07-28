local PATH = (...)
local lfs = require("lfs")
local Coeus

local function name_to_file(name)
	return name:gsub("%.", "/") .. ".lua"
end

local function name_to_directory(name)
	return name:gsub("%.", "/")
end

local Coeus = {
	Root = PATH .. ".",
	Version = {0, 0, 0},

	loaded = {},
}

function Coeus:Load(name)
	local abs_name = self.Root .. name

	if (self.loaded[name]) then
		return self.loaded[name]
	else
		local file = name_to_file(abs_name)
		local dir = name_to_directory(abs_name)

		local file_mode = lfs.attributes(file, "mode")
		local dir_mode = lfs.attributes(dir, "mode")

		if (file_mode == "file") then
			return self:LoadFile(name, file)
		elseif (dir_mode == "directory") then
			return self:LoadDirectory(name, dir)
		elseif (not file_mode and not dir_mode) then
			error("Unable to load module '" .. (name or "nil") .. "': file does not exist.")
		else
			error("Unknown error in loading module '" .. (name or "nil") .. "'")
		end
	end
end

function Coeus:LoadFile(name, path)
	path = path or name_to_file(name)

	--print("loadfile", name, path)

	local chunk, err = loadfile(path)

	if (not chunk) then
		error(err)
	end

	local success, object = pcall(chunk, self)

	if (not success) then
		error(object)
	end

	if (object) then
		self.loaded[name] = object

		return object
	end
end

function Coeus:LoadDirectory(name, path)
	path = path or name_to_directory(name)

	--print("loaddir", name, path)

	local container = setmetatable({}, {
		__index = function(container, key)
			self[key] = self:Load(name .. "." .. key)

			return self[key]
		end
	})

	self.loaded[name] = container

	return container
end

--Automagically load directories if a key doesn't exist
setmetatable(Coeus, {
	__index = function(self, key)
		self[key] = self:Load(key)

		return self[key]
	end
})

local GLFW = Coeus.Bindings.GLFW
local OpenGL = Coeus.Bindings.OpenGL
local ffi = require("ffi")

local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL
OpenGL.loader = glfw.GetProcAddress

local Shader = Coeus.Graphics.Shader
local Mesh = Coeus.Graphics.Mesh

local Vector3 = Coeus.Math.Vector3
local Matrix4 = Coeus.Math.Matrix4

function Coeus.Main(window)
	local shader = Shader:New([[
	#version 330
	layout(location=0) in vec4 position;

	uniform mat4 modelview;
	uniform mat4 projection;

	void main() {
		gl_Position = projection * modelview * position;
	}
	]],[[
	#version 330
	layout(location=0) out vec4 FragColor;

	uniform float x;

	void main() {
		FragColor = vec4(x, 1.0, x, 1.0);	
	}
	]])

	local vertex_data = {
		1.0, 1.0,-1.0,
	   -1.0, 1.0,-1.0,
	   -1.0, 1.0, 1.0,
	    1.0, 1.0, 1.0,
	    1.0,-1.0,-1.0,
	   -1.0,-1.0,-1.0,
	   -1.0,-1.0, 1.0,
	    1.0,-1.0, 1.0
	}
	local index_data = {
		0,1,2,
		0,2,3,
		0,4,5,
		0,5,1,
		1,5,6,
		1,6,2,
		2,6,7,
		2,7,3,
		3,7,4,
		3,4,0,
		4,7,6,
		4,6,5
	}
	local mesh = Mesh:New()
	mesh:SetData(vertex_data, index_data, Mesh.DataFormat.Position)

	local width, height = window:GetSize()
	local aspect = width / height
	local perspective = Matrix4.GetPerspective(90, 1.0, 100.0, aspect)

	local modelview = Matrix4.GetTranslation(Vector3:New(0, 0, -5))
	for i=0,15 do
		print(modelview.m[i])
	end

	while (glfw.WindowShouldClose(window.handle) == 0) do
		window:Use()
		gl.ClearColor(0, 0, 1, 1)
		gl.Clear(GL.COLOR_BUFFER_BIT)

		gl.UseProgram(shader.program)
		shader:Send('x', math.sin(os.clock()))
		shader:Send('projection', perspective)
		shader:Send('modelview', modelview)

		modelview = modelview:Multiply(Matrix4.GetRotationY(math.rad(0.5)), modelview)
		
		mesh:Render()
		local err = gl.GetError()
		if err ~= GL.NO_ERROR then
			error("GL error: " .. err)
		end


		glfw.SwapBuffers(window.handle)
		glfw.PollEvents()

	end
end

return Coeus