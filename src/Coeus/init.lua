--[[
	Coeus Core

	Provides the basis of Coeus, including module loading, error handling, and
	logging. Only core Coeus functionality should be placed in this file.

	See the included documentation for more information on how to use Coeus.
]]

local PATH = (...)
local lfs = require("lfs")
local Coeus

--The Lua module-relative path to the folder containing Coeus's source
local SRC_PATH = PATH:match("^(.-)%.[^%.]+$"):gsub("%.", "/")

--This system's end-of-line character
local EOL = (jit.os == "Windows") and "\r\n" or "\n"

--Determine the default pathing based on how deep Coeus is in the filesystem
local DEFAULT_PATH
if (SRC_PATH) then
	--Coeus is nested (ie src.Coeus), load top-level modules first
	DEFAULT_PATH = {"./", SRC_PATH}
else
	--Coeus is in the same level as our current module
	DEFAULT_PATH = {"./"}
end

--[[
	Takes a module name and yields a possible file path
]]
local function name_to_file(name)
	local path = (name:gsub("%.", "/"):gsub("//+", "/")) .. ".lua"

	if (path:sub(1, 1) == "/") then
		return path:sub(2)
	else
		return path
	end
end

--[[
	Takes a module name and yields a possible directory path
]]
local function name_to_directory(name)
	local path = (name:gsub("%.", "/"):gsub("//+", "/"))

	if (path:sub(1, 1) == "/") then
		return path:sub(2)
	else
		return path
	end
end

--[[
	Takes a file and yields a possible module name
]]
local function file_to_name(name)
	return (name:gsub("%.[^%.]*$", ""):gsub("/+", "%."))
end

--[[
	Normalizes a module name to be used for internal memoization
]]
local function name_to_id(name)
	return name:lower()
end

--[[
	Takes a list of paths and joins them together to make one path
]]
local function path_join(...)
	return (table.concat({...}, "/"):gsub("//+", "/"))
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

local C = {
	--Public members
	Config = {
		Debug = true, --Is this build a developer build?
		Platform = platform_short[jit.os], --What are we running on?
		Architecture = arch_short[jit.arch], --How many bits do we have?
		BinDir = "./bin/", --Location of binaries
		SourceDir = "./src/", --Location of all source files
		CoeusDir = "./src/Coeus/", --Location of Coeus source files,
		Path = DEFAULT_PATH, --Where Coeus will search for modules to load

		Version = {0, 2, 0, "dev"}, --The current version of the engine in the form MAJOR.MINOR.PATCH-STAGE
		VersionString = "0.2.0-dev", --A string version of the above version
	
		LogLevel = 3, --Log entries greater than this level will be ignored
		LogFileEnabled = true, --Whether Coeus will log to disk
		LogFile = "Coeus-log.txt", --The file to output logging information to
		LogBufferMaxSize = 5, --The number of logs before the buffer will flush to disk
		FatalErrors = true, --Whether errors will stop execution or not
		FatalWarnings = false --Whether warnings will stop execution or not
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

	logs_since_flush = 0, --The number of logs since the last flush to disk
	log_buffer = {}, --Contains the logging information yet to be written to disk
	log_level_longest = 0, --The longest log level name; used for pretty output
	i_log_level = {} --The inverse of LogLevel for reverse lookups
}

--[[
	Initialize Coeus with an optional configuration structure.
]]
function C:Initialize(config)
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

	--Build CoeusDir
	self.Config.CoeusDir = path_join(self.Config.SourceDir, "Coeus")

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
		self:Get("Coeus").Bindings.Win32_.SetDllDirectoryA(self.Config.BinDir)
	end

	self.Initialized = true
end

--[[
	Terminate Coeus and call all finalizers on modules.
]]
function C:Terminate()
	if (not self.Initialized) then
		print("Coeus already terminated; ignoring call.")
		return
	end

	self:Info("Terminating...", "Coeus")

	for key, item in pairs(self.loaded) do
		if (type(item) == "table") then
			local term = rawget(item, "Terminate")

			if (term) then
				local success, err = pcall(term, item)
				
				if (not success) then
					self:Warning("Termination failed: " .. err, key)
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

	Does nothing if LogFileEnabled is set to false.
]]
function C:FlushLogBuffer()
	local path = self.Config.LogFile

	self.logs_since_flush = 0

	if (not path or not self.Config.LogFileEnabled) then
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
	Creates an error object to be returned to denote that something went wrong.
	Produced by C:Error and C:Warning automatically.
]]
function C:CreateError(message)
	return {
		Message = message,
		__error = true
	}
end

--[[
	Checks that the given value is a Coeus Error.
]]
function C:IsError(value)
	return (type(value) == "table" and value.__error)
end

--[[
	Generic log function given a message level, a message, and an optional
	location. The location will be automatically defined if not specified, and
	differs based on the Debug setting.
]]
function C:Log(level, message, location)
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
	Method to raise a fatal error.
	Will always terminate the program.
	Should be used when, no matter what, the program cannot continue.
]]
function C:Fatal(message, location)
	self:Log(self.LogLevel.Fatal, message, location)
end

--[[
	Method to raise an error.
	Will terminate the program if LogLevel is greater than LogLevel.Error and
	FatalErrors are enabled.
	Should be used when the program can not continue under normal circumstances.
]]
function C:Error(message, location)
	self:Log(self.LogLevel.Error, message, location)

	return self:CreateError(message)
end

--[[
	Method to raise a warning.
	Will terminate the program if LogLevel is greater than LogLevel.Warning and
	FatalWarnings are enabled.
	Should be used when 
]]
function C:Warning(message, location)
	self:Log(self.LogLevel.Warning, message, location)

	return self:CreateError(message)
end

--[[
	Method to report non-critical information.
]]
function C:Info(message, location)
	self:Log(self.LogLevel.Info, message, location)

	return self:CreateError(message)
end

--[[
	Called when a fatal error or fatal warning occurs.
	Should not be called directly.
]]
function C.LogHandlers.Fatal(coeus, message)
	print(debug.traceback(message, 4))
	coeus:Terminate()
	--os.exit(-1)
end

--[[
	Called when application code signals an error.
	Terminates the program if FatalErrors are enabled.
	Should not be called directly.
]]
function C.LogHandlers.Error(coeus, message)
	if (coeus.Config.FatalErrors) then
		print(debug.traceback(message, 4))
		coeus:Terminate()
	else
		print(message)
	end
end

--[[
	Called when application code signals a warning.
	Terminates the program is FatalWarnings are enabled.
	Should not be called directly.
]]
function C.LogHandlers.Warning(coeus, message)
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
function C.LogHandlers.Info(coeus, message)
	print(message)
end

--[[
	Returns the file path to the module in question, or nil if it doesn't exist.
]]
function C:ModulePath(name)
	local tried = {}
	local paths = self.Config.Path

	for i = 1, #paths do
		local joined = path_join(paths[i], name)
		local file = name_to_file(joined)
		local file_mode = lfs.attributes(file, "mode")

		if (file_mode == "file") then
			return file, "file"
		end

		local dir = name_to_directory(joined)
		local dir_mode = lfs.attributes(dir, "mode")

		if (dir_mode == "directory") then
			return dir, "directory"
		end

		table.insert(tried, file)
		table.insert(tried, dir)
	end

	return nil, tried
end

--[[
	Loads a module given an identifying string.
	The module can exist either on the real filesystem or in the VFS.
]]
function C:Get(name, flags)
	flags = flags or {}
	local id = name_to_id(name)

	--Is the module already in memory?
	if (self.loaded[id]) then
		return self.loaded[id]
	end

	--The module on the VFS?
	if (self.vfs[id]) then
		return self:LoadVFSEntry(name, flags)
	end

	--Load the module from where it should be loaded from
	local path, mode = self:ModulePath(name)
	
	--The module wasn't found!
	if (not path) then
		local err = ("Unable to load module '%s' from %s: module does not exist. Tried paths:\n%s"):format(
			name or "nil",
			flags.LoadFrom or "Path",
			table.concat(mode, "\n")
		)

		if (flags.safe) then
			return self:CreateError(err)
		else
			return self:Error(err)
		end
	end

	if (mode == "file") then
		return self:LoadFile(name, path, flags)
	elseif (mode == "directory") then
		return self:LoadDirectory(name, path, flags)
	end
end

--[[
	Loads a Lua chunk with the associated module metadata.
	Used internally and called by all Load* methods.
]]
function C:LoadChunk(chunk, meta, flags)
	flags = flags or {}
	meta = meta or {}
	local success, object = pcall(chunk, self, meta)

	--Check for Lua error condition
	if (not success) then
		if (flags.safe) then
			return self:Warning(object)
		else
			return self:Error(object)
		end
	end

	--Check for Coeus error condition
	if (self:IsError(object)) then
		return object
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
function C:LoadFile(name, path, flags)
	flags = flags or {}
	local id = name_to_id(name)
	local leaf = (name:match("%.?([^%.]+)$"))

	local chunk, err = loadfile(path)

	if (not chunk) then
		if (flags.safe) then
			return self:Warning(err)
		else
			return self:Error(err)
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
function C:LoadDirectory(name, path)
	local id = name_to_id(name)

	local container = {
		FullyLoad = function(this)
			for filepath in lfs.dir(path) do
				if (filepath ~= "." and filepath ~= "..") then
					local filename = file_to_name(filepath)
					this[filename] = self:Get(name .. "." .. filename)
				end
			end

			return this
		end,

		Get = function(this, key, flags)
			local piece = self:Get(name .. "." .. key, flags)
			this[key] = piece

			return piece
		end
	}

	--Does the directory have a patch file?
	local patch = self:Get(name .. "._", {safe = true})

	if (patch and not self:IsError(patch)) then
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
function C:GetLoadedModules()
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
function C:LoadVFSEntry(name, flags)
	flags = flags or {}
	local id = name_to_id(name)
	local entry = self.vfs[id]
	local leaf = (name:match("%.?([^%.]+)$"))

	if (entry.file) then
		local chunk, err = loadstring(entry.body)

		if (not chunk) then
			if (flags.safe) then
				return self:Warning(err)
			else
				return self:Error(err)
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
			return self:Warning("Could not load VFS entry")
		else
			return self:Error("Could not load VFS entry")
		end
	end
end

--[[
	Registers a new directory in the virtual file system table
	Used by the automagic build system
]]
function C:AddVFSDirectory(name)
	self.vfs[name_to_id(name)] = {directory = true}
end

--[[
	Registers a new file in the virtual file system table
	Used by the automagic build system
]]
function C:AddVFSFile(name, body)
	self.vfs[name_to_id(name)] = {file = true, body = body}
end

----------------------------------------------------------
--Don't put any new core additions to this past this line!
----------------------------------------------------------

setmetatable(C, {
	__gc = function(self)
		self:Terminate()
	end
})

--Register the Coeus namespace with the C core
C.Coeus = C:Get("Coeus")

--Load built-in modules
--@builtins

return C