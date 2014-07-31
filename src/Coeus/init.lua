local PATH = (...)
local lfs = require("lfs")
local Coeus

local function name_to_file(name)
	return name:gsub("%.", "/") .. ".lua"
end

local function name_to_directory(name)
	return name:gsub("%.", "/")
end

local function name_to_id(name)
	return name:lower()
end

local Coeus = {
	Root = PATH .. ".",
	Version = {0, 0, 0},

	loaded = {},
	meta = {}
}

function Coeus:Load(name, safe)
	local abs_name = self.Root .. name
	local id = name_to_id(name)

	if (self.loaded[id]) then
		return self.loaded[id]
	end

	local file = name_to_file(abs_name)
	local dir = name_to_directory(abs_name)

	local file_mode = lfs.attributes(file, "mode")
	local dir_mode = lfs.attributes(dir, "mode")

	if (file_mode == "file") then
		return self:LoadFile(name, file, safe)
	elseif (dir_mode == "directory") then
		return self:LoadDirectory(name, dir)
	elseif (not file_mode and not dir_mode) then
		error("Unable to load module '" .. (name or "nil") .. "': file does not exist.")
	else
		error("Unknown error in loading module '" .. (name or "nil") .. "'")
	end
end

function Coeus:LoadFile(name, path, safe)
	local id = name_to_id(name)
	if (self.loaded[id]) then
		return self.loaded[id]
	end

	path = path or name_to_file(name)

	local chunk, err = loadfile(path)

	if (not chunk) then
		if (safe) then
			return nil, err
		else
			error(err)
		end
	end

	local meta = {
		name = name,
		path = path
	}
	local success, object = pcall(chunk, self, meta)

	if (not success) then
		if (safe) then
			return nil, object
		else
			error(object)
		end
	end

	self.meta[name] = meta

	if (object) then
		self.loaded[name_to_id(name)] = object

		return object
	end
end

function Coeus:LoadDirectory(name, path)
	local id = name_to_id(name)
	if (self.loaded[id]) then
		return self.loaded[id]
	end

	path = path or name_to_directory(name)

	local container = setmetatable({}, {
		__index = function(container, key)
			container[key] = self:Load(name .. "." .. key)

			return container[key]
		end
	})

	self.loaded[name_to_id(name)] = container

	return container
end

function Coeus:GetLoadedModules()
	local buffer = {}
	for key, value in pairs(self.loaded) do
		table.insert(buffer, key)
	end

	table.sort(buffer)

	return buffer
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

local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL
OpenGL.loader = glfw.GetProcAddress

return Coeus