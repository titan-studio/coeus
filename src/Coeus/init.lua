local PATH = (...)
local lfs = require("lfs")
local Coeus

local function name_to_file(name)
	return name:gsub("%.", "/") .. ".lua"
end

local function file_to_name(name)
	return name:gsub("%.[^%.]*$", ""):gsub("/", "%.")
end

local function name_to_directory(name)
	return name:gsub("%.", "/")
end

local function name_to_id(name)
	return name:lower()
end

local platform_short = {
	Windows = "win",
	Linux = "linux",
	OSX = "osx",
	BSD = "bsd",
	POSIX = "posix",
	Other = "other"
}

local arch_short = {
	x86 = "32",
	x64 = "64",
	ppcspe = "ppc"
}

local Coeus = {
	Release = false,
	Platform = platform_short[jit.os],
	Architecture = arch_short[jit.arch],
	BinDir = "", --defined below

	Root = (PATH and PATH .. ".") or "",
	Version = {0, 0, 0},

	vfs = {},
	loaded = {},
	meta = {}
}

if (Coeus.Release) then
	Coeus.BinDir = "bin/"
else
	Coeus.BinDir = "bin/" .. Coeus.Platform .. Coeus.Architecture .. "/"
end

function Coeus:Load(name, safe)
	local abs_name = self.Root .. name
	local id = name_to_id(name)

	if (self.loaded[id]) then
		return self.loaded[id]
	elseif (self.vfs[id]) then
		return self:LoadVFSEntry(name, safe)
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

function Coeus:LoadChunk(chunk, meta)
	meta = meta or {}
	local success, object = pcall(chunk, self, meta)

	if (not success) then
		error(object)
		return nil, object
	end

	if (meta.id) then
		self.meta[meta.id] = meta

		if (object) then
			self.loaded[meta.id] = object

			return object
		end
	end
end

function Coeus:LoadFile(name, path, safe)
	local id = name_to_id(name)
	local abs_name = self.Root .. name

	if (self.loaded[id]) then
		return self.loaded[id]
	end

	path = path or name_to_file(abs_name)

	local chunk, err = loadfile(path)

	if (not chunk) then
		if (safe) then
			return nil, err
		else
			error(err)
		end
	end

	return self:LoadChunk(chunk, {
		id = id,
		name = name,
		path = path
	})
end

function Coeus:LoadDirectory(name, path)
	local id = name_to_id(name)
	local abs_name = self.Root .. name

	if (self.loaded[id]) then
		return self.loaded[id]
	end

	path = path or name_to_directory(abs_name)

	local container = setmetatable({}, {
		__index = function(container, key)
			local piece = self:Load(name .. "." .. key)
			container[key] = piece

			return piece
		end
	})

	self.loaded[id] = container

	return container
end

function Coeus:FullyLoadDirectory(name, path)
	local abs_name = self.Root .. name
	local id = name_to_id(name)
	path = path or name_to_directory(abs_name)

	local directory = self:LoadDirectory(name, path)

	--This is not quite ideal
	if (self.vfs[id]) then
		for name in pairs(self.vfs) do
			local shortname = name:match("^" .. id .. "%.(.+)$")
			if (shortname) then
				directory[shortname] = self:LoadVFSEntry(name)
			end
		end
	end

	for filepath in lfs.dir(path) do
		if (filepath ~= "." and filepath ~= "..") then
			local filename = file_to_name(filepath)
			directory[filename] = self:Load(name .. "." .. filename)
		end
	end

	return directory
end

function Coeus:GetLoadedModules()
	local buffer = {}
	for key, value in pairs(self.loaded) do
		table.insert(buffer, key)
	end

	table.sort(buffer)

	return buffer
end

function Coeus:LoadVFSEntry(name, safe)
	local id = name_to_id(name)
	local entry = self.vfs[id]

	if (entry.file) then
		local chunk, err = loadstring(entry.body)

		if (not chunk) then
			if (safe) then
				return nil, err
			else
				error(err)
			end
		end

		return self:LoadChunk(chunk, {
			name = name,
			id = id
		})
	elseif (entry.directory) then
		local container = setmetatable({}, {
			__index = function(container, key)
				local piece = self:Load(name .. "." .. key)
				container[key] = piece

				return piece
			end
		})

		self.loaded[id] = container

		return container
	else
		if (safe) then
			return nil, "Could not load VFS entry"
		else
			error("Could not load VFS entry")
		end
	end
end

function Coeus:AddVFSDirectory(name)
	self.vfs[name_to_id(name)] = {directory = true}
end

function Coeus:AddVFSFile(name, body)
	self.vfs[name_to_id(name)] = {file = true, body = body}
end

--Automagically load directories if a key doesn't exist
setmetatable(Coeus, {
	__index = function(self, key)
		local entry = self:Load(key)
		self[key] = entry

		return entry
	end
})

--Load built-in modules
--@builtins

local GLFW = Coeus.Bindings.GLFW
local OpenGL = Coeus.Bindings.OpenGL

local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL
OpenGL.loader = glfw.GetProcAddress

return Coeus