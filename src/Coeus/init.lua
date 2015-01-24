--[[
	Coeus Core 0.1.0.
	Based on Lua Namespace 0.2.0
]]

--[[
	Lua Namespace 0.2.0

	Copyright (c) 2014 Lucien Greathouse (LPGhatguy)

	This software is provided 'as-is', without any express or implied warranty.
	In no event will the authors be held liable for any damages arising from the
	use of this software.

	Permission is granted to anyone to use this software for any purpose, including
	commercial applications, and to alter it and redistribute it freely, subject to
	the following restrictions:

	1. The origin of this software must not be misrepresented; you must not claim
	that you wrote the original software. If you use this software in a product, an
	acknowledgment in the product documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and must not be misrepresented
	as being the original software.

	3. This notice may not be removed or altered from any source distribution.
]]

-- Current namespace version
local n_version = {0, 2, 0, "alpha"}
local n_versionstring = ("%s.%s.%s-%s"):format(unpack(n_version))

-- Hopeful dependencies
local ok, lfs = pcall(require, "lfs")
if (not ok) then
	lfs = nil
end

local ok, hate = pcall(require, "hate")
if (not ok) then
	hate = nil
end

-- Determine Lua capabilities and library support
local support = {}

--[[
	string support:report()

	Generates a stringified report of supported features and extensions.
]]
function support:report()
	local features = {}

	for feature, enabled in pairs(self) do
		if (type(enabled) == "table" and enabled.report) then
			table.insert(features, enabled:report())
		elseif (type(enabled) ~= "function") then
			table.insert(features, feature)
		end
	end

	return table.concat(features, ", ")
end

-- What Lua are we running under?
-- For our purposes, 5.3 is a superset of 5.2.
if (table.unpack) then
	support.lua52 = true

	if (table.move) then
		support.lua53 = true
	end
else
	support.lua51 = true
end

-- LuaJIT 2.0+
if (jit) then
	support.jit = true
end

-- LuaFileSystem
if (lfs) then
	support.lfs = true
end

-- Lua debug library
if (debug) then
	support.debug = true
end

-- Lua os library
if (os) then
	support.os = true
end

-- Lua io library
if (io) then
	support.io = true
end

-- Is hate available?
if (hate) then
	support.hate = true
end

-- Are we running in LOVE?
if (love) then
	support.love = {}

	-- return a nice report of the current LOVE version
	function support.love:report()
		return ("love %d.%d.%d (%s)"):format(unpack(self.version))
	end

	if (love.getVersion) then
		-- LOVE 0.9.1+
		support.love.version = {love.getVersion()}
	else
		-- LOVE 0.9.0 and older; may be supported
		local major = love._version_minor
		local minor = love._version_minor

		-- What *IS* LOVE?
		if (major ~= 0) then
			support.love = false
		end

		if (minor == 9) then
			-- Definitely 0.9.0
			support.love.version = {0, 9, 0, "Baby Inspector"}
		else
			-- 0.8.0 and older; definitely not supported
			support.love = false
		end
	end
end

-- How about ROBLOX?
if (game and workspace and Instance) then
	support.roblox = true
end

-- Cross-version shims
local unpack = unpack or table.unpack

--[[
	loaded load_with_env(string source, table environment)
		source: The source code to compile into a function.
		environment: The environment to load the function into.

	Loads a function with a given environment.
	Essentially backports Lua 5.2's load function to LuaJIT and Lua 5.1.
]]
local load_with_env

if (support.lua51) then
	function load_with_env(source, environment)
		environment = environment or getfenv()
		local chunk, err = loadstring(source)

		if (not chunk) then
			return chunk, err
		end

		setfenv(chunk, environment)

		return chunk
	end
elseif (support.lua52) then
	load_with_env = load
end

-- Find out a path for the directory above namespace
local n_root
local n_file = support.debug and debug.getinfo(1, "S").source:match("@(.+)$")

if (n_file) then
	-- Normalize slashes; this is okay for Windows
	n_root = n_file:gsub("\\", "/"):match("^(.+)/.-$")
else
	print("Could not locate lua-namespace source file; is debug info stripped?")
	print("This code path is untested.")
	n_root = (...):match("(.+)%..-$")
end

-- Contains our actual core
local N = {
	_loaded = {},
	simple = {}, -- Fallback and default methods
	-- Filesystem methods
	fs = {
		providers = {}
	},
	support = support, -- Table for fast support lookups

	version = n_version, -- Version table for programmatic comparisons
	versionstring = n_versionstring, -- Version string for user-facing reporting

	config = {
		lib = true
	}
}

-- Utility Methods


--[[
	module_to_file(string source, bool is_directory=false)
		source: The module path to parse
		is_directory: Whether the output should be a file or directory.

	Takes a module path (a.b.c) and turns it into a somewhat well-formed file path.
	If is_directory is true, the output will look like:
		a/b/c
	Otherwise:
		a/b/c.lua
]]
local function module_to_file(source, is_directory)
	return (source:gsub("%.", "/") .. (is_directory and "" or ".lua"))
end

--[[
	(string module, bool is_directory) file_to_module(string source)
		source: The file path to be turned into a module path.

	Takes a file path (a/b/c or a/b/c.ext) and turns it into a well-formed module path.
	Also returns whether the file is most likely a directory object or not.
]]
local function file_to_module(source)
	locaN.fsource = source:gsub("%..-$", "")
	local is_file = (fsource ~= source)
	return (fsource:gsub("[/\\]+", "."):gsub("^%.*", ""):gsub("%.*$", "")), is_file
end

--[[
	(string result) module_join(string first, string second)
		first: The first part of the path.
		second: The second part of the path.

	Joins two module names with a period and removes any extraneous periods.
]]
local function module_join(first, second)
	return ((first .. "." .. second):gsub("%.%.+", "."))
end

--[[
	(string result) path_join(string first, string second)
		first: The first part of the path.
		second: The second part of the path.

	Joins two path names with a period and removes any extraneous slashes.
]]
local function path_join(first, second)
	return ((first .. "/" .. second):gsub("//+", "/"):gsub("/+$", ""))
end

-- Filesystem Abstractions

--[[
	file? fs:get_file(string path)
		path: The file to find a provider for.

	Returns the file from whatever filesystem provider it's located on.
]]
function N.fs:get_file(path)
	for i, provider in ipairs(self.providers) do
		if (provider.get_file) then
			local file = provider:get_file(path)

			if (file) then
				return file
			end
		end
	end

	return nil
end

--[[
	directory? fs:get_directory(string path)
		path: The directory to find a provider for.

	Returns the directory from whatever filesystem provider it's located on.
]]
function N.fs:get_directory(path)
	for i, provider in ipairs(self.providers) do
		if (provider.get_directory) then
			local directory = provider:get_directory(path)

			if (directory) then
				return directory
			end
		end
	end

	return nil
end

--[[
	provider? fs:get_provider(string id)
		id: The ID of the FS provider to search for.

	Returns the provider with the given ID if it exists.
]]
function N.fs:get_provider(id)
	for i, provider in ipairs(self.providers) do
		if (provider.id == id) then
			return provider
		end
	end

	return nil
end

--[[
	Filesystem provider schema:

	provider.name
		A friendly name to describe the provider

	bool provider:is_file(string path)
			path: The module path to check.

	Returns whether the specified path exists on this filesystem provider.

	file provider:get_file(string path)
		path: The module path to check.

	Returns a file object corresponding to the given file on this filesystem.

	bool provider:is_directory(string path)
		path: The module path to check.

	Returns whether the specified path exists on this filesystem provider.

	directory provider:get_directory(string path)
		path: The module path to check.

	Returns a directory object corresponding to the given directory on this filesystem.

	string file:read()
		contents: The complete contents of the file.

	Reads the entire file into a string and returns it.

	void file:close()
	
	Closes the file, allowing it to be reused by the system.

	string[] directory:list()
		files: The files and folders contained in this directory.

	Returns a list of files contained in the directory.

	void directory:close()
	
	Closes the directory, allowing it to be reused by the system.
]]

-- Only support the full filesystem if we have LFS
-- FS provider to read from the actual filesystem
if (support.io and support.lfs) then
	local full_fs = {
		id = "io",
		name = "Full Filesystem",
		path = {n_root}
	}

	table.insert(N.fs.providers, full_fs)

	local file_buffer = {}
	local directory_buffer = {}

	-- file:close() method
	local function file_close(self)
		table.insert(file_buffer, self)
	end

	-- file:read() method
	local function file_read(self)
		local handle, err = io.open(self.filepath, "r")

		if (handle) then
			local body = handle:read("*a")
			handle:close()

			return body
		else
			return nil, err
		end
	end

	-- directory:close() method
	local function directory_close(self)
		table.insert(directory_buffer, self)
	end

	-- directory:list() method
	local function directory_list(self)
		local paths = {}

		for name in lfs.dir(self.filepath) do
			if (name ~= "." and name ~= "..") then
				table.insert(paths, module_join(self.path, path_to_module(name)))
			end
		end

		return paths
	end

	function full_fs:get_file(path, filepath)
		filepath = filepath or module_to_file(path)

		for i, base in ipairs(self.path) do
			local fullpath = path_join(base, filepath)

			if (self:is_file(path, fullpath)) then
				local file = file_buffer[#file_buffer]
				file_buffer[#file_buffer] = nil

				if (file) then
					file.path = path
					file.filepath = filepath

					return file
				else
					return {
						close = file_close,
						read = file_read,
						path = path,
						filepath = fullpath
					}
				end

				break
			end
		end
	end

	-- Is this a file?
	function full_fs:is_file(path, filepath)
		filepath = filepath or module_to_file(path)

		return (lfs.attributes(filepath, "mode") == "file")
	end

	-- Returns a directory object
	function full_fs:get_directory(path, filepath)
		filepath = filepath or module_to_file(path, true)

		for i, base in ipairs(self.path) do
			local fullpath = path_join(base, filepath)

			if (self:is_directory(path, fullpath)) then
				local directory = directory_buffer[#directory_buffer]
				directory_buffer[#directory_buffer] = nil

				if (directory) then
					directory.path = path
					directory.filepath = fullpath

					return directory
				else
					return {
						close = directory_close,
						list = directory_list,
						path = path,
						filepath = fullpath
					}
				end

				break
			end
		end
	end

	-- Is this a directory?
	function full_fs:is_directory(path, filepath)
		filepath = filepath or module_to_file(path, true)

		return (lfs.attributes(filepath, "mode") == "directory")
	end
end

-- LOVE filesystem provider
if (support.love) then
	local love_fs = {
		id = "love",
		name = "LOVE Filesystem"
	}

	table.insert(N.fs.providers, love_fs)

	local file_buffer = {}
	local directory_buffer = {}

	local function file_close(self)
		table.insert(file_buffer, self)
	end

	local function file_read(self)
		return love.filesystem.read(self.filepath)
	end

	local function directory_close(self)
		table.insert(directory_buffer, self)
	end

	local function directory_list(self)
		local items = love.filesystem.getDirectoryItems(self.filepath)

		for i = 1, #items do
			items[i] = module_join(self.path, file_to_module(items[i]))
		end

		return items
	end

	function love_fs:get_file(path, filepath)
		filepath = filepath or module_to_file(path)

		if (self:is_file(path, filepath)) then
			local file = file_buffer[#file_buffer]
			file_buffer[#file_buffer] = nil

			if (file) then
				file.path = path
				file.filepath = filepath

				return file
			else
				return {
					close = file_close,
					read = file_read,
					path = path,
					filepath = filepath
				}
			end
		end
	end

	function love_fs:is_file(path, filepath)
		filepath = filepath or module_to_file(path)

		return love.filesystem.isFile(filepath)
	end

	function love_fs:get_directory(path, filepath)
		filepath = filepath or module_to_file(path, true)

		if (self:is_directory(path, filepath)) then
			local directory = directory_buffer[#directory_buffer]
			directory_buffer[#directory_buffer] = nil

			if (directory) then
				directory.path = path
				directory.filepath = filepath

				return directory
			else
				return {
					close = directory_close,
					list = directory_list,
					path = path,
					filepath = filepath
				}
			end
		end
	end

	function love_fs:is_directory(path, filepath)
		filepath = filepath or module_to_file(path, true)

		return love.filesystem.isDirectory(filepath)
	end
end

-- ROBLOX "filesystem" provider
-- TODO
if (support.roblox) then
end

-- Virtual Filesystem for namespace
-- Used when packing for platforms that don't have real filesystem access
do
	local vfs = {
		id = "vfs",
		name = "Virtual Filesystem",
		enabled = false,

		nodes = {},
		directory = true
	}

	table.insert(N.fs.providers, vfs)

	-- file:read() method
	local function file_read(self)
		return self._contents
	end

	-- file:close() method
	-- a stub, since this doesn't apply to a VFS
	local function file_close()
	end

	-- directory:list() method
	local function directory_list(self)
		return self._nodes
	end

	-- directory:close() method
	-- a stub, since this doesn't apply to a VFS
	local function directory_close()
	end

	-- Starts at a root node and navigates according to a module name
	-- Add auto_dir to automatically create directories
	-- If the path does not exist, or cannot be reached due to an invalid node,
	-- the function will return nil, the furthest location reached, and a list of node names navigated.
	function vfs:navigate(path, auto_dir)
		local location = self
		local nodes = {}

		for node in path:gmatch("[^%.]+") do
			if (not location.nodes) then
				return nil, location, nodes
			end

			table.insert(nodes, node)

			if (location.nodes[node]) then
				location = location.nodes[node]
			elseif (auto_dir) then
				location = vfs:add_directory(table.concat(nodes, "."))
			else
				return nil, location, nodes
			end
		end

		return location
	end

	-- Performs string parsing and navigates to the parent node of a given path
	function vfs:navigate_leafed(path, auto_dir)
		local leafless, leaf = path:match("^(.-)%.([^%.]+)$")

		if (leafless) then
			local parent = self:navigate(leafless, auto_dir)

			-- Couldn't get there! Ouch!
			if (not parent) then
				return nil, ("Could not navigate to parent node '%s': invalid path"):format(leafless)
			end

			if (not parent.directory) then
				return nil, ("Could not create node in node '%s': not a directory"):format(leafless)
			end

			return parent, leafless, leaf
		else
			leafless = ""
			leaf = path

			return self, leafless, leaf
		end
	end

	function vfs:get_file(path)
		if (not self.enabled) then
			return false
		end

		local object = self:navigate(path)

		if (object) then
			return {
				_contents = object.contents,
				read = file_read,
				close = file_close,
				path = path
			}
		end
	end

	function vfs:is_file(path)
		if (not self.enabled) then
			return false
		end

		local object = self:navigate(path)

		return (object and object.file)
	end

	function vfs:add_file(path, contents)
		self.enabled = true
		local parent, leafless, leaf = self:navigate_leafed(path, true)

		-- leafless contains error state if parent is nil
		if (not parent) then
			return nil, leafless
		end

		local node = {
			file = true,
			contents = contents
		}

		parent.nodes[leaf] = node

		return node
	end

	function vfs:get_directory(path)
		if (not self.enabled) then
			return false
		end

		local object = self:navigate(path)

		if (object) then
			return {
				_nodes = object.nodes,
				list = directory_read,
				close = directory_close,
				path = path
			}
		end
	end

	function vfs:is_directory(path)
		if (not self.enabled) then
			return false
		end

		local object = self:navigate(path)

		return (object and object.directory)
	end

	function vfs:add_directory(path)
		self.enabled = true
		local parent, leafless, leaf = self:navigate_leafed(path)

		-- leafless contains error state if parent is nil
		if (not parent) then
			return nil, leafless
		end

		local node = {
			directory = true,
			nodes = {}
		}

		parent.nodes[leaf] = node

		return node
	end
end

local function load_file(file)
	local method = assert(load_with_env(file:read()))
	local result = method(file.path, N.base)

	return result
end

local function load_directory(directory)
	local object = {}

	setmetatable(object, {
		__index = function(self, key)
			local path = module_join(directory.path, key)
			local result = N:get(path)
			self[key] = result

			return result
		end
	})

	return object
end

-- Namespace API
function N:get(path)
	path = path or ""

	if (self._loaded[path]) then
		return self._loaded[path]
	end

	local file = N.fs:get_file(path)

	if (file) then
		local object = load_file(file)
		file:close()

		if (object) then
			self._loaded[path] = object
			return object
		end
	else
		local directory = N.fs:get_directory(path)

		if (directory) then
			local object = load_directory(directory)
			directory:close()

			if (object) then
				self._loaded[path] = object
				return object
			end
		else
			return nil
		end
	end
end

if (N.config.lib) then
	N.base = N:get()
else
	N.base = N
end

return N.base