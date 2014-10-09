local PATH = (...)
local ffi = require("ffi")
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

local function fix_directory(dir)
	if (not dir:match("[/\\]$")) then
		return dir .. "/"
	else
		return dir
	end
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
	--Public members
	Config = {
		Debug = true, --Is this build a developer build?
		Platform = platform_short[jit.os], --What are we running on?
		Architecture = arch_short[jit.arch], --How many bits do we have?
		BinDir = "./bin/", --Location of binaries
		SourceDir = "./src/", --Location of all source files
		CoeusDir = "./src/Coeus/", --Location of Coeus source files

		Version = {0, 2, 0, "alpha"}, --The current version of the engine in the form MAJOR.MINOR.PATCH-STAGE
	},

	--Private members
	vfs = {}, --A virtual file system handler, used by the build system.
	loaded = {}, --A dictionary of all loaded modules
	meta = {}
}

--[[
	Initialize Coeus with an optional configuration structure.
]]
function Coeus:Initialize(config)
	--Load in an optional config option and patch Coeus with it.
	if (config) then
		for key, value in pairs(config) do
			self.Config[key] = value
		end
	end

	--Make sure BinDir and SourceDir end with trailing slashes
	self.Config.BinDir = fix_directory(self.Config.BinDir)
	self.Config.SourceDir = fix_directory(self.Config.SourceDir)

	--Build CoeusDir
	self.Config.CoeusDir = self.Config.SourceDir .. "Coeus/"

	--Force Windows to load binaries from here
	if (ffi.os == "Windows") then
		Coeus.Bindings.Win32_.SetDllDirectoryA(Coeus.Config.BinDir)
	end
end

function Coeus:Terminate()
	for key, item in pairs(self.loaded) do
		if (type(item) == "table") then
			local term = rawget(item, "Terminate")
			if (term) then
				term(item)
			end
		end
	end
end

--[[
	Loads a module given an identifying string.
	The module can exist either on the real filesystem or in the VFS.
]]
function Coeus:Load(name, flags)
	flags = flags or {}
	local id = name_to_id(name)

	if (self.loaded[id]) then
		return self.loaded[id]
	elseif (self.vfs[id]) then
		return self:LoadVFSEntry(name, flags)
	end

	local file = self.Config.CoeusDir .. name_to_file(name)
	local dir = self.Config.CoeusDir .. name_to_directory(name)

	local file_mode = lfs.attributes(file, "mode")
	local dir_mode = lfs.attributes(dir, "mode")

	if (file_mode == "file") then
		return self:LoadFile(name, file, flags)
	elseif (dir_mode == "directory") then
		return self:LoadDirectory(name, dir, flags)
	elseif (not file_mode and not dir_mode) then
		local err = "Unable to load module '" .. (name or "nil") .. "': file does not exist."

		if (flags.safe) then
			return false, err
		else
			error(err)
		end
	else
		local err = "Unknown error in loading module '" .. (name or "nil") .. "'"

		if (flags.safe) then
			return false, err
		else
			error(err)
		end
	end
end

--[[
	Loads a Lua chunk with the associated module metadata.
	Used internally and called by all Load* methods.
]]
function Coeus:LoadChunk(chunk, meta, flags)
	flags = flags or {}
	meta = meta or {}
	local success, object = pcall(chunk, self, meta)

	if (not success) then
		if (flags.safe) then
			return nil, object
		else
			error(object)
		end
	end

	if (meta.id) then
		self.meta[meta.id] = meta

		if (object) then
			self.loaded[meta.id] = object

			return object
		end
	end
end

--[[
	Loads a file located on the real filesystem.
]]
function Coeus:LoadFile(name, path, flags)
	flags = flags or {}
	local id = name_to_id(name)

	if (self.loaded[id]) then
		return self.loaded[id]
	end

	path = path or (self.Config.CoeusDir .. name_to_file(name))

	local chunk, err = loadfile(path)

	if (not chunk) then
		if (flags.safe) then
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

--[[
	Loads a directory and returns a virtual directory object.
	All members are lazy loaded.
]]
function Coeus:LoadDirectory(name, path)
	local id = name_to_id(name)

	if (self.loaded[id]) then
		return self.loaded[id]
	end

	path = path or (self.Config.CoeusDir .. name_to_directory(name))

	local container = {
		FullyLoad = function(this)
			for filepath in lfs.dir(path) do
				if (filepath ~= "." and filepath ~= "..") then
					local filename = file_to_name(filepath)
					this[filename] = self:Load(name .. "." .. filename)
				end
			end
		end,

		Get = function(this, key, flags)
			local piece = self:Load(name .. "." .. key, flags)
			this[key] = piece

			return piece
		end
	}

	local patch = self:Load(name .. "._", {safe = true})

	if (patch) then
		for key, value in pairs(container) do
			if (not patch[key]) then
				patch[key] = value
			end
		end

		container = patch
	end

	setmetatable(container, {
		__index = container.Get
	})

	self.loaded[id] = container

	return container
end

--[[
	Returns a shallow copy of the list of modules currently loaded.
	Useful if the list needs to be mutated.
]]
function Coeus:GetLoadedModules()
	local buffer = {}
	for key, value in pairs(self.loaded) do
		table.insert(buffer, key)
	end

	table.sort(buffer)

	return buffer
end

--[[
	Loads a file from the virtual file system tables.
	Called automatically if the file we're looking for is determined to be on the VFS.
]]
function Coeus:LoadVFSEntry(name, flags)
	flags = flags or {}
	local id = name_to_id(name)
	local entry = self.vfs[id]

	if (entry.file) then
		local chunk, err = loadstring(entry.body)

		if (not chunk) then
			if (flags.safe) then
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
		if (flags.safe) then
			return nil, "Could not load VFS entry"
		else
			error("Could not load VFS entry")
		end
	end
end

--[[
	Registers a new directory in the virtual file system table
	Used by the automagic build system
]]
function Coeus:AddVFSDirectory(name)
	self.vfs[name_to_id(name)] = {directory = true}
end

--[[
	Registers a new file in the virtual file system table
	Used by the automagic build system
]]
function Coeus:AddVFSFile(name, body)
	self.vfs[name_to_id(name)] = {file = true, body = body}
end

--Automagically load directories if a key doesn't exist
setmetatable(Coeus, {
	__index = function(self, key)
		local entry = self:Load(key)
		self[key] = entry

		return entry
	end,

	__gc = function(self)
		self:Terminate()
	end
})

--Load built-in modules
--@builtins

return Coeus