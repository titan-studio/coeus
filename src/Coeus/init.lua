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
	meta = {}
}

function Coeus:Load(name)
	local abs_name = self.Root .. name
	local id = name:lower()

	if (self.loaded[id]) then
		return self.loaded[id]
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

	local chunk, err = loadfile(path)

	if (not chunk) then
		error(err)
	end

	local meta = {
		name = name,
		path = path
	}
	local success, object = pcall(chunk, self, meta)

	if (not success) then
		error(object)
	end

	self.meta[name] = meta

	if (object) then
		self.loaded[name:lower()] = object

		return object
	end
end

function Coeus:LoadDirectory(name, path)
	path = path or name_to_directory(name)

	local container = setmetatable({}, {
		__index = function(container, key)
			self[key] = self:Load(name .. "." .. key)

			return self[key]
		end
	})

	self.loaded[name:lower()] = container

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

local Timing = Coeus.Timing

local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL
OpenGL.loader = glfw.GetProcAddress

local bit = require("bit")

function Coeus.Main(window, app)
	if app.Load then app:Load() end
	while (glfw.WindowShouldClose(window.handle) == 0) do
		Timing.Step()
		glfw.PollEvents()
		window:Use()
		gl.FrontFace(GL.CCW)
		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(bit.bor(tonumber(GL.COLOR_BUFFER_BIT), tonumber(GL.DEPTH_BUFFER_BIT)))
		if app.Render then app:Render() end
		
		local err = gl.GetError()
		if err ~= GL.NO_ERROR then
			error("GL error: " .. err)
		end


		glfw.SwapBuffers(window.handle)
		

	end
	if app.Destroy then app:Destroy() end
end

return Coeus