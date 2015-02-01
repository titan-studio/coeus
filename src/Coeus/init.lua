--[[
	Graphene 1.0.0-beta
	https://github.com/LPGhatguy/lua-graphene

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

-- Current graphene version
local g_version = {1, 0, 0, "beta"}
local g_versionstring = ("%s.%s.%s-%s"):format((unpack or table.unpack)(g_version))

-- Determine Lua capabilities and library support
local support = {}

--[[
	string Support:Report()

	Generates a stringified report of supported features and extensions.
]]
function support:Report()
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

-- Contains our actual core
local G = {
	_loaded = {}, -- Dictionary of loaded modules for caching
	_rebasing = {}, -- Contains rebasing information
	Support = support, -- Table for fast support lookups

	Version = g_version, -- Version table for programmatic comparisons
	VersionString = g_versionstring, -- Version string for user-facing reporting

	-- Filesystem abstraction
	FS = {
		Providers = {}
	},

	-- Configuration
	Config = {
		Lib = true,
		FileExtensions = {".lua"},
		InitFile = "_"
	}
}

-- Do we have LFS?
local ok, lfs = pcall(require, "lfs")
if (not ok) then
	lfs = nil
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
-- Also check for OS in this path.
if (jit) then
	support.jit = true

	if (jit.os == "Windows") then
		support.windows = true
	else
		support.nix = true
	end
else
	local win = package.config:sub(1, 1) == "\\"

	if (win) then
		support.windows = true
	else
		support.nix = true
	end
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

-- {% if (support.love) then %}
-- Are we running in LOVE?
if (love) then
	support.love = {}

	-- return a nice report of the current LOVE version
	function support.love:report()
		return ("love %d.%d.%d (%s)"):format(unpack(self.version))
	end

	if (love.getVersion) then
		-- LOVE 0.9.1+
		support.love.Version = {love.getVersion()}
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
			support.love.Version = {0, 9, 0, "Baby Inspector"}
		else
			-- 0.8.0 and older; definitely not supported
			support.love = false
		end
	end
end
-- {% end %}

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
	function load_with_env(source, from, environment)
		environment = environment or getfenv()
		local chunk, err = loadstring(source, from)

		if (not chunk) then
			return chunk, err
		end

		setfenv(chunk, environment)

		return chunk
	end
elseif (support.lua52) then
	function load_with_env(source, from, environment)
		return load(source, from, nil, environment)
	end
end

-- Provider is_directory and is_file fallbacks for systems without LFS.
local is_directory
local is_file

if (support.lfs) then
	function is_file(path)
		return (lfs.attributes(path, "mode") == "file")
	end

	function is_directory(path)
		return (lfs.attributes(path, "mode") == "directory")
	end
else
	-- Reduced file functionality without LFS
	function is_file(path)
		local handle = io.open(path, "r")

		if (handle) then
			handle:close()

			return true
		end

		return false
	end

	if (support.windows) then
		function is_directory(path)
			return (os.execute(("cd %q 2>nul"):format(path)) == 0)
		end
	else
		function is_directory(path)
			return (os.execute(("stat %q"):format(path)) == 0)
		end
	end
end

-- Find out a path for the directory above graphene
local g_root
local g_file = support.debug and debug.getinfo(1, "S").source:match("@(.+)$")

if (g_file) then
	-- Normalize slashes; this is okay for Windows
	g_root = g_file:gsub("\\", "/"):match("^(.+)/.-$") or "./"
else
	print("Could not locate lua-graphene source file; is debug info stripped?")
	print("This code path is untested.")
	g_root = (...):match("(.+)%..-$")
end

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
	local fsource = source:gsub("%..-$", "")
	local is_file = (fsource ~= source)
	return (fsource:gsub("[/\\]+", "."):gsub("^%.*", ""):gsub("%.*$", "")), is_file
end

--[[
	string module_join(string first, string second)
		first: The first part of the path.
		second: The second part of the path.

	Joins two module names with a period and removes any extraneous periods.
]]
local function module_join(first, second)
	return ((first .. "." .. second):gsub("%.%.+", "."):gsub("^%.+", ""):gsub("%.+$", ""))
end

--[[
	string path_join(string first, string second)
		first: The first part of the path.
		second: The second part of the path.

	Joins two path names with a period and removes any extraneous slashes.
]]
local function path_join(first, second)
	return ((first .. "/" .. second):gsub("//+", "/"):gsub("/+$", ""))
end

--[[
	string[] file_paths(string name, [bool is_directory, string[] paths])
		name: The path to transform
		is_directory: Whether or not this points to a directory
		paths: The 

	Create a list of all acceptable file paths for a module path on a real filesystem.
]]
local function file_paths(name, is_directory, paths)
	local extensions = is_directory and {""} or G.Config.FileExtensions
	local paths = paths or {""}
	local filename = module_to_file(name)
	local result = {}

	for i, path in ipairs(paths) do
		for j, extension in ipairs(extensions) do
			table.insert(result, path_join(path, name) .. extension)
		end
	end

	return result
end

--[[
	table dictionary_shallow_copy(table from, [table to])
		from: The table to source data from.
		to: The table to copy data into.

	Performs a shallow copy from one table to another.
]]
local function dictionary_shallow_copy(from, to)
	to = to or {}

	for key, value in pairs(from) do
		to[key] = value
	end

	return to
end

--[[
	table dictionary_shallow_merge(table from, table to)
		from: The table to source data from.
		to: The table to copy data into.

	Performs a shallow copy from one table to another without overwriting keys.
]]
local function dictionary_shallow_merge(from, to)
	to = to or {}

	for key, value in pairs(from) do
		if (to[key] == nil) then
			to[key] = value
		end
	end

	return to
end

-- Filesystem Abstractions

--[[
	File? FS:GetFile(string path)
		path: The file to find a provider for.

	Returns the file from whatever filesystem provider it's located on.
]]
function G.FS:GetFile(path)
	for i, provider in ipairs(self.Providers) do
		if (provider.GetFile) then
			local file = provider:GetFile(path)

			if (file) then
				return file
			end
		end
	end

	return nil
end

--[[
	directory? FS:GetDirectory(string path)
		path: The directory to find a provider for.

	Returns the directory from whatever filesystem provider it's located on.
]]
function G.FS:GetDirectory(path)
	for i, provider in ipairs(self.Providers) do
		if (provider.GetDirectory) then
			local directory = provider:GetDirectory(path)

			if (directory) then
				return directory
			end
		end
	end

	return nil
end

--[[
	provider? FS:GetProvider(string id)
		id: The ID of the FS provider to search for.

	Returns the provider with the given ID if it exists.
]]
function G.FS:GetProvider(id)
	for i, provider in ipairs(self.Providers) do
		if (provider.ID == id) then
			return provider
		end
	end

	return nil
end

--[[
	Filesystem provider schema:

	Provider.ID
		An ID to look up the provider with.

	Provider.Name
		A friendly name to describe the provider.

	Provider.Path (LOVE and vanilla IO only)
		Similar to a system PATH, where the provider looks for files.

	bool Provider:IsFile(string path)
			path: The module path to check.

	Returns whether the specified path exists on this filesystem provider.

	File Provider:GetFile(string path)
		path: The module path to check.

		Returns a file object corresponding to the given file on this filesystem.

	bool Provider:IsDirectory(string path)
		path: The module path to check.

		Returns whether the specified path exists on this filesystem provider.

	Directory Provider:GetDirectory(string path)
		path: The module path to check.

		Returns a directory object corresponding to the given directory on this filesystem.

	string File:Read()
		contents: The complete contents of the file.

		Reads the entire file into a string and returns it.

	void File:Close()
	
		Closes the file, allowing it to be reused by the system.

	string[] Directory:List()
		files: The files and folders contained in this directory.

		Returns a list of files contained in the directory.

	void Directory:Close()
	
		Closes the directory, allowing it to be reused by the system.
]]

-- {% if (support.love) then %}
-- LOVE filesystem provider
if (support.love) then
	local love_fs = {
		ID = "love",
		Name = "LOVE Filesystem",
		Path = {"", g_root}
	}

	table.insert(G.FS.providers, love_fs)

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

	function love_fs:GetFile(path, filepath)
		filepath = filepath or module_to_file(path)

		for i, base in ipairs(self.Path) do
			local fullpath = path_join(base, filepath)

			if (self:IsFile(path, fullpath)) then
				local file = file_buffer[#file_buffer]
				file_buffer[#file_buffer] = nil

				if (file) then
					file.Path = path
					file.FilePath = fullpath

					return file
				else
					return {
						Close = file_close,
						Read = file_read,
						Path = path,
						FilePath = fullpath
					}
				end
			end
		end
	end

	function love_fs:IsFile(path, filepath)
		filepath = filepath or module_to_file(path)

		return love.filesystem.isFile(filepath)
	end

	function love_fs:GetDirectory(path, filepath)
		filepath = filepath or module_to_file(path, true)

		for i, base in ipairs(self.Path) do
			local fullpath = path_join(base, filepath)

			if (self:IsDirectory(path, fullpath)) then
				local directory = directory_buffer[#directory_buffer]
				directory_buffer[#directory_buffer] = nil

				if (directory) then
					directory.Path = path
					directory.FilePath = fullpath

					return directory
				else
					return {
						Close = directory_close,
						List = directory_list,
						Path = path,
						FilePath = fullpath
					}
				end
			end
		end
	end

	function love_fs:IsDirectory(path, filepath)
		filepath = filepath or module_to_file(path, true)

		return love.filesystem.isDirectory(filepath)
	end
end
-- {% end %}

-- {% if (support.io) then %}

-- Only support the full filesystem if we have IO
-- No FullyLoad method without LFS
-- FS provider to read from the actual filesystem
if (support.io) then
	local full_fs = {
		ID = "io",
		Name = "Full Filesystem",
		Path = {"", g_root}
	}

	table.insert(G.FS.Providers, full_fs)

	local file_buffer = {}
	local directory_buffer = {}

	-- File:Close() method
	local function file_close(self)
		table.insert(file_buffer, self)
	end

	-- File:Read() method
	local function file_read(self)
		local handle, err = io.open(self.FilePath, "r")

		if (handle) then
			local body = handle:read("*a")
			handle:close()

			return body
		else
			return nil, err
		end
	end

	-- Directory:Close() method
	local function directory_close(self)
		table.insert(directory_buffer, self)
	end

	-- Directory:List() method
	local function directory_list(self)
		if (not support.lfs) then
			error("Cannot list directory without LFS!", 2)
		end

		local paths = {}

		for name in lfs.dir(self.FilePath) do
			if (name ~= "." and name ~= "..") then
				table.insert(paths, (file_to_module(name)))
			end
		end

		return paths
	end

	function full_fs:GetFile(path, filepath)
		local paths = file_paths(path, false, self.Path)
		filepath = filepath or module_to_file(path)

		for i, base in ipairs(self.Path) do
			local fullpath = path_join(base, filepath)

			if (self:IsFile(path, fullpath)) then
				local file = file_buffer[#file_buffer]
				file_buffer[#file_buffer] = nil

				if (file) then
					file.Path = path
					file.FilePath = fullpath

					return file
				else
					return {
						Close = file_close,
						Read = file_read,
						Path = path,
						FilePath = fullpath
					}
				end

				break
			end
		end
	end

	-- Is this a file?
	function full_fs:IsFile(path, filepath)
		filepath = filepath or module_to_file(path)

		return is_file(filepath)
	end

	-- Returns a directory object
	function full_fs:GetDirectory(path, filepath)
		filepath = filepath or module_to_file(path, true)

		for i, base in ipairs(self.Path) do
			local fullpath = path_join(base, filepath)

			if (self:IsDirectory(path, fullpath)) then
				local directory = directory_buffer[#directory_buffer]
				directory_buffer[#directory_buffer] = nil

				if (directory) then
					directory.Path = path
					directory.FilePath = fullpath

					return directory
				else
					return {
						Close = directory_close,
						List = directory_list,
						Path = path,
						FilePath = fullpath
					}
				end

				break
			end
		end
	end

	-- Is this a directory?
	function full_fs:IsDirectory(path, filepath)
		filepath = filepath or module_to_file(path, true)

		return is_directory(filepath)
	end
end
-- {% end %}

-- {% if (support.vfs) then %}
-- Virtual Filesystem for Graphene
-- Used when packing for platforms that don't have real filesystem access
do
	local vfs = {
		ID = "vfs",
		Name = "Virtual Filesystem",
		Enabled = false,

		Nodes = {},
		Directory = true
	}

	table.insert(G.FS.Providers, vfs)

	-- File:Read() method
	local function file_read(self)
		return self._contents
	end

	-- File:Close() method
	-- a stub, since this doesn't apply to a VFS
	local function file_close()
	end

	-- Directory:List() method
	local function directory_list(self)
		local list = {}

		for name in pairs(self._nodes) do
			table.insert(list, name)
		end

		return list
	end

	-- Directory:Close() method
	-- a stub, since this doesn't apply to a VFS
	local function directory_close()
	end

	-- Starts at a root node and navigates according to a module name
	-- Add auto_dir to automatically create directories
	-- If the path does not exist, or cannot be reached due to an invalid node,
	-- the function will return nil, the furthest location reached, and a list of node names navigated.
	function vfs:Navigate(path, auto_dir)
		local location = self
		local nodes = {}

		for node in path:gmatch("[^%.]+") do
			if (not location.Nodes) then
				return nil, location, nodes
			end

			if (location.Nodes[node]) then
				location = location.Nodes[node]
				table.insert(nodes, node)
			elseif (auto_dir) then
				location = vfs:AddDirectory(table.concat(nodes, "."))
				table.insert(nodes, node)
			else
				return nil, location, nodes
			end
		end

		return location
	end

	-- Performs string parsing and navigates to the parent node of a given path
	function vfs:LeafedNavigate(path, auto_dir)
		local leafless, leaf = path:match("^(.-)%.([^%.]+)$")

		if (leafless) then
			local parent = self:Navigate(leafless, auto_dir)

			-- Couldn't get there! Ouch!
			if (not parent) then
				return nil, ("Could not navigate to parent node '%s': invalid path"):format(leafless)
			end

			if (not parent.Directory) then
				return nil, ("Could not create node in node '%s': not a directory"):format(leafless)
			end

			return parent, leafless, leaf
		else
			leafless = ""
			leaf = path

			return self, leafless, leaf
		end
	end

	function vfs:GetFile(path)
		if (not self.Enabled) then
			return false
		end

		local object = self:Navigate(path)

		if (object and object.File) then
			return {
				_contents = object.Contents,
				Read = file_read,
				Close = file_close,
				Path = path
			}
		end
	end

	function vfs:IsFile(path)
		if (not self.Enabled) then
			return false
		end

		local object = self:Navigate(path)

		return (object and object.File)
	end

	function vfs:AddFile(path, contents)
		self.Enabled = true
		local parent, leafless, leaf = self:LeafedNavigate(path, true)

		-- leafless contains error state if parent is nil
		if (not parent) then
			return nil, leafless
		end

		local node = {
			File = true,
			Contents = contents
		}

		parent.Nodes[leaf] = node

		return node
	end

	function vfs:GetDirectory(path)
		if (not self.Enabled) then
			return false
		end

		local object = self:Navigate(path)

		if (object and object.Directory) then
			return {
				_nodes = object.Nodes,
				List = directory_list,
				Close = directory_close,
				Path = path
			}
		end
	end

	function vfs:IsDirectory(path)
		if (not self.Enabled) then
			return false
		end

		local object = self:Navigate(path)

		return (object and object.Directory)
	end

	function vfs:AddDirectory(path)
		self.Enabled = true
		local parent, leafless, leaf = self:LeafedNavigate(path, true)

		-- leafless contains error state if parent is nil
		if (not parent) then
			return nil, leafless
		end

		local node = {
			Directory = true,
			Nodes = {}
		}

		parent.Nodes[leaf] = node

		return node
	end
end
-- {% end %}

local directory_interface = {}

--[[
	G Directory:GetGrapheneCore()

	Returns the Graphene core, defined as G in this file.
	Not affected by any rebasing rules.
]]
function directory_interface:GetGrapheneCore()
	return G
end

--[[
	void Directory:AddGrapheneSubmodule(string path)
		path: The path to the submodule relative to this directory.

	Adds a submodule relative to this directory.
]]
function directory_interface:AddGrapheneSubmodule(path)
	return G:AddSubmodule(module_join(self._directory.Path, path))
end

--[[
	void Directory:FullyLoad()

	Recursively loads all members of the directory.
]]
function directory_interface:FullyLoad()
	local list = self._directory:List()

	for i, member in ipairs(list) do
		local object = self[member]

		-- Make sure we have an object that isn't this one (necessary because of _.lua).
		-- Also make sure that it's got a FullyLoad method, which makes it either a directory
		-- or something trying to emulate a directory, probably.
		if (object and object ~= self and type(object) == "table" and object.FullyLoad) then
			object:FullyLoad()
		end
	end
end

--[[
	any? load_file(string path, any? base)
		path: The module path of the file.
		base: The root to pass to the module, defaults to G.Base.

	Loads a file and executes it, returning the result.
	Uses the built-in filesystem abstractions.
]]
local function load_file(file, base)
	local body, err = file:Read()

	if (not body) then
		-- This really should never happen!
		error(("File at %q could not be loaded: %s"):format(file.Path, err))
	end

	local method = assert(load_with_env(file:Read(), file.Path))
	local result = method(base or G.Base, file.Path)

	return result
end

--[[
	Directory? load_directory(string path)
		path: The module path of the file.

	Loads a directory and its init file, returning the result.
	Uses the built-in filesystem abstractions.
]]
local function load_directory(directory)
	local initializing = {}

	local object = dictionary_shallow_copy(directory_interface)
	object._directory = directory

	object.GrapheneGet = function(self, key)
		local path = module_join(self._directory.Path, key)

		if (initializing[key]) then
			error(("Circular reference loading %q!"):format(path), 2)
		end

		initializing[key] = true

		local result = G:Get(path, self, key)

		initializing[key] = false

		return result
	end

	setmetatable(object, {
		__index = object.GrapheneGet
	})

	return object
end

--===============--
-- GRAPHENE API --
--===============--

-- This library can be accessed by any codefile by using
-- Directory:GetGrapheneCore()
-- on any Graphene directory.

--[[
	void G:AddRebase(string path)
		path: The path to have as a submodule

	Adds a rebasing rule for modules that match this rule.
	Used for embedding existing Graphene modules.

	Components should use directory:AddGrapheneSubmodule instead unless wrapping Graphene itself.
]]
function G:AddSubmodule(path)
	assert(type(path) == "string", "Bad argument #1 to G:AddRebase, must be a string!")

	table.insert(self._rebasing, {"^" .. path:gsub("%.", "%%."), path})
end

--[[
	void G:ClearRebases()

	Removes all rebasing rules from the core.
]]
function G:ClearRebases()
	for key, value in pairs(self._rebasing) do
		self._rebasing[key] = nil
	end
end

--[[
	any? G:Get(string path, [table target, any key])
		path: The path to the module, period delimitted
		target: A container to load the result into.
		key: The index of the container to place the result at.

	Returns the object relative to this namespace's root, if it exists.
]]
function G:Get(path, target, key)
	path = path or ""

	-- Flag to determine whether to use target and key as out.
	local do_placement = not not (target and key)

	-- Check for already loaded module!
	if (self._loaded[path]) then
		if (do_placement) then
			target[key] = self._loaded[path]
		end

		return self._loaded[path]
	end

	-- Run path through our rebasing rules
	local base = G.Base
	for i, rebase in ipairs(self._rebasing) do
		if (path:match(rebase[1])) then
			base = self._loaded[rebase[2]] or G.Base

			break
		end
	end

	-- Is this a file?
	local file = G.FS:GetFile(path)

	if (file) then
		local object = load_file(file, base)
		file:Close()

		if (object) then
			self._loaded[path] = object

			if (do_placement) then
				target[key] = object
			end

			return object
		end
	else
		-- How about a directory?
		local directory = G.FS:GetDirectory(path)

		if (directory) then
			local object = load_directory(directory)

			if (object) then
				self._loaded[path] = object

				if (do_placement) then
					target[key] = object
				end

				-- Check for init file
				local init = self:Get(module_join(path, self.Config.InitFile))

				if (init) then
					-- If init is a table, we should merge against it
					if (type(init) == "table") then
						-- Merge in our directory object
						dictionary_shallow_merge(object, init)

						-- Merge in our directory metatable
						if (not getmetatable(init)) then
							setmetatable(init, getmetatable(object))
						end
					end

					self._loaded[path] = init

					if (do_placement) then
						target[key] = init
					end

					return init
				end

				return object
			end
		else
			return nil
		end
	end
end

-- If the Lib switch is set, make our base the current namespace instead of the Graphene core.
-- This is the default and recommended functionality.
-- To retrieve the core, use :GetGrapheneCore() on this.
if (G.Config.Lib) then
	G:Get(nil, G, "Base")
else
	G.Base = G
end

return G.Base