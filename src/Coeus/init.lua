--[[
	Coeus Core

	Provides the basis of Coeus, including module loading, error handling, and
	logging. Only extensions to core Coeus functionality should be placed in
	this file.

	See the included documentation for more information on how to use Coeus.
]]

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

local function fix_directory(dir)
	if (not dir:match("[/\\]$")) then
		return dir .. "/"
	else
		return dir
	end
end

local EOL = (jit.os == "Windows") and "\r\n" or "\n"

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
	
		LogLevel = 3, --Log entries greater than this level will be ignored
		LogFile = "Coeus-log.txt",
		LogBufferMaxSize = 5,
		FatalErrors = true,
		FatalWarnings = false
	},

	LogLevel = {
		None = 0,
		Fatal = 1,
		Error = 2,
		Warning = 3,
		Info = 4
	},

	LogHandlers = {}, --A hashmap of handlers for different log levels

	Initialized = false, --Used to keep track of the initialization state of Coeus.

	--Private members
	vfs = {}, --A virtual file system handler, used by the build system
	loaded = {}, --A dictionary of all loaded modules
	meta = {}, --Contains metadata about modules; may be deprecated soon

	logs_since_flush = 0,
	log_buffer = {}, --Contains the logging information yet to be written to disk
	log_level_longest = 0,
	i_log_level = {} --
}

--[[
	Initialize Coeus with an optional configuration structure.
]]
function Coeus:Initialize(config)
	if (self.Initialized) then
		self:Info("Already initialized, ignoring call.", "Coeus")
		return
	end

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

	--Build i_log_level for fast log level lookups
	--Also define log_level_longest for nice formatting
	for key, value in pairs(self.LogLevel) do
		self.i_log_level[value] = key

		if (#key > self.log_level_longest) then
			self.log_level_longest = #key
		end
	end

	--Force Windows to load binaries from here
	if (jit.os == "Windows") then
		Coeus.Bindings.Win32_.SetDllDirectoryA(Coeus.Config.BinDir)
	end

	self.Initialized = true
end

--[[
	Terminate Coeus and call all finalizers on modules.
]]
function Coeus:Terminate()
	if (not self.Initialized) then
		return
	end

	self:Info("Terminating...", "Coeus")

	for key, item in pairs(self.loaded) do
		if (type(item) == "table") then
			local term = rawget(item, "Terminate")

			if (term) then
				local success, err = pcall(term, item)
				
				if (not success) then
					self:Warn("Termination failed: " .. err, key)
				end
			end
		end
	end

	self.loaded = {}

	self:Info("Terminated.", "Coeus")
	self:FlushLogBuffer()

	self.Initialized = false
end

--[[
	Writes the existing log buffer to disk and clears the buffer.
]]
function Coeus:FlushLogBuffer()
	local path = self.Config.LogFile

	self.logs_since_flush = 0

	if (not path) then
		return
	end

	local handle, err = io.open(path, "ab")
	if (not handle) then
		io.write(("Could not open log file \"%s\" for writing: %s"):format(path, err))
		return
	end

	handle:write(table.concat(self.log_buffer, EOL))
	handle:write(EOL)
	handle:close()

	self.log_buffer = {}
end

--[[
	Generic log function given a message level, a message, and an optional
	location. The location will be automatically defined if not specified, and
	differs based on the Debug setting.
]]
function Coeus:Log(level, message, location)
	level = tonumber(level) or self.LogLevel.Info

	if (level > self.Config.LogLevel) then
		return
	end

	--Determine a location if one wasn't specified
	if (not location) then
		if (self.Config.Debug) then
			local info = debug.getinfo(3, "Sln")

			if (n == "Lua") then
				location = ("[%s]:%d"):format(
					info.short_src,
					info.currentline
				)
			else
				location = ("[%s]:%d"):format(
					info.short_src:match("[^\\/]+$"),
					info.currentline
				)
			end
		else
			location = "unknown"
		end
	end

	local level_name = self.i_log_level[level] or "Info"
	local padding = math.max(0, self.log_level_longest - #level_name)
	local output = ("[%s] %s%s (%s): %s"):format(
		os.date(),
		level_name:upper(),
		(" "):rep(padding),
		location,
		message
	)

	table.insert(self.log_buffer, output)
	if (self.logs_since_flush > self.Config.LogBufferMaxSize) then
		self:FlushLogBuffer()
	end

	self.logs_since_flush = self.logs_since_flush + 1

	self.LogHandlers[level_name](self, output)
end

--[[
	Shorthand method to raise a fatal error.
	Will always terminate the program.
	Should be used when, no matter what, the program cannot continue.
]]
function Coeus:Fatal(message, location)
	self:Log(self.LogLevel.Fatal, message, location)
end

--[[
	Shorthand method to raise an error.
	Will terminate the program if LogLevel is greater than LogLevel.Error and
	FatalErrors are enabled.
	Should be used when the program can not continue under normal circumstances.
]]
function Coeus:Error(message, location)
	self:Log(self.LogLevel.Error, message, location)
end

--[[
	Shorthand method to raise a warning.
	Will terminate the program if LogLevel is greater than LogLevel.Warning and
	FatalWarnings are enabled.
	Should be used when 
]]
function Coeus:Warn(message, location)
	self:Log(self.LogLevel.Warning, message, location)
end

--[[
	Shorthand method to report non-critical information.
]]
function Coeus:Info(message, location)
	self:Log(self.LogLevel.Info, message, location)
end

--[[
	Called when a fatal error or fatal warning occurs.
	Should not be called directly.
]]
function Coeus.LogHandlers.Fatal(coeus, message)
	print(message)
	coeus:Terminate()
	--os.exit(-1)
end

--[[
	Called when application code signals an error.
	Terminates the program if FatalErrors are enabled.
	Should not be called directly.
]]
function Coeus.LogHandlers.Error(coeus, message)
	if (coeus.Config.FatalErrors) then
		coeus.LogHandlers.Fatal(coeus, message)
	else
		print(message)
	end
end

--[[
	Called when application code signals a warning.
	Terminates the program is FatalWarnings are enabled.
	Should not be called directly.
]]
function Coeus.LogHandlers.Warning(coeus, message)
	if (coeus.Config.FatalWarnings) then
		coeus.LogHandlers.Fatal(coeus, message)
	else
		print(message)
	end
end

--[[
	Called when application code reports information.
	Will never terminate the program.
	Should not be called directly.
]]
function Coeus.LogHandlers.Info(coeus, message)
	print(message)
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
	local leaf = (name:match("%.?([^%.]+)$"))

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
		path = path,
		leaf = leaf
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

			return this
		end,

		Get = function(this, key, flags)
			local piece = self:Load(name .. "." .. key, flags)
			this[key] = piece

			return piece
		end
	}

	local patch = self:Load(name .. "._", {safe = true})

	if (patch) then
		self.loaded[name_to_id(name) .. "._"] = nil
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
	Called automatically if the file we're looking for is determined to be on
	the VFS.
]]
function Coeus:LoadVFSEntry(name, flags)
	flags = flags or {}
	local id = name_to_id(name)
	local entry = self.vfs[id]
	local leaf = (name:match("%.?([^%.]+)$"))

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
			leaf = leaf,
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

----------------------------------------------------------
--Don't put any new core additions to this past this line!
----------------------------------------------------------

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