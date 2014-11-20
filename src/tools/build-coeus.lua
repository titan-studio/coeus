--[[
USAGE:
build-coeus indir outfile

Takes a Coeus source from indir and produces a mashed-up version at outfile.
Use to get a single file distribution.
]]
local lfs = require("lfs")
local input, output = ...
io.write("Compile modules? (y)/n: ")
local compile_modules = (io.read() ~= "n")
io.write("Compile full package? (y)/n: ")
local compile_full = (io.read() ~= "n")

local strip_debug
if (compile_modules or compile_full) then
	io.write("Strip debug information? (y)/n: ")
	strip_debug = (io.read() ~= "n")
end
print("")

if (not input:sub(-1, -1):match("[\\/]")) then
	input = input .. "/"
end

--STEP ONE: Read engine
local function readfile(path)
	local handle, err = io.open(path, "rb")

	if (not handle) then
		error(err)
	end

	local body = handle:read("*a")
	handle:close()
	
	return body
end

local function load_dir(path, filebuf, dirbuf)
	for file in lfs.dir(path) do
		if (file ~= "." and file ~= ".." and file ~= "init") then
			local full = path .. file
			local mode = lfs.attributes(full, "mode")

			if (mode == "file") then
				table.insert(filebuf, {full, readfile(full)})
			elseif (mode == "directory") then
				table.insert(dirbuf, {full})
				load_dir(full .. "/", filebuf, dirbuf)
			else
				error("Unknown file mode '" .. (mode or "nil") .. "'")
			end
		end
	end
end

print("Loading engine files...")
local base = readfile(input .. "init.lua")
local filebuf, dirbuf = {}, {}
load_dir(input, filebuf, dirbuf)
print(("Loaded %d files and %d directories"):format(#filebuf, #dirbuf))

print("Processing directory paths...")
for key, value in ipairs(dirbuf) do
	value[1] = value[1]:match(input .. "(.+)"):gsub("[\\/]", ".")
end

print("Processing file paths...")
for key, value in ipairs(filebuf) do
	value[1] = value[1]:match(input .. "(.*)%.lua$"):gsub("[\\/]", ".")
end

if (compile_modules) then
	print("Compiling modules...")

	for key, value in ipairs(filebuf) do
		value[2] = string.dump(loadstring(value[2]), strip_debug)
	end

	print("Modules compiled successfully!")
end

print("Generating VFS call buffer...")
local vfs_buf = {}

table.insert(vfs_buf, [[
Coeus.Magikarp = {}
]])

for key, value in ipairs(dirbuf) do
	table.insert(vfs_buf, ("C:AddVFSDirectory(%q)"):format(value[1]))
end

for key, value in ipairs(filebuf) do
	table.insert(vfs_buf, ("C:AddVFSFile(%q, %q)"):format(value[1], value[2]))
end

print("Generating VFS-injected code...")
--This would use gsub were it not so finnicky with percent signs
local vfs_calls = table.concat(vfs_buf, "\n")
local s, e = base:find("--@builtins")
local injected = base:sub(1, s - 1) .. vfs_calls .. base:sub(e + 1)

if (compile_full) then
	print("Compiling injected code...")
	local chunk, err = loadstring(injected)

	if (not chunk) then
		error(err)
	end

	injected = string.dump(chunk, strip_debug)
end

print("Writing compiled code to disk...")
local handle, err = io.open(output, "wb")

if (not handle) then
	error(err)
end

handle:write(injected)
handle:close()

print("\nBuild complete!")