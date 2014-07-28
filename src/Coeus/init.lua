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

	print("loadfile", name, path)

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

	print("loaddir", name, path)

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

return Coeus