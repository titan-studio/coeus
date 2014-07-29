local PATH = (...)
local lfs = require("lfs")

local function name_to_file(name)
	return name:gsub("%.", "/") .. ".lua"
end

local function name_to_directory(name)
	return name:gsub("%.", "/")
end

local simple_lr_composite = {
	__tostring = function(self)
		local buf = {}
		for key, value in ipairs(self) do
			table.insert(buf, tostring(value))
		end

		return table.concat(buf, "\n")
	end
}

local results_metatable = {
	__tostring = function(self)
		local breakdown_buffer = {}

		for name, result in pairs(self.TestResults) do
			table.insert(breakdown_buffer,
				result.Name .. "\n\t\t\t" ..
				(result.Passed and "PASSED" or "FAILED") ..
				(result.Message and ("\n\t\t\t" .. result.Message) or "")
			)
		end

		return ([[
%s
	%s
	Tests Run: %d
	Tests Passed: %d
	Tests Failed: %d
	Test Breakdown:
		%s
		]]):format(
			self.Name,
			(self.TestsFailed == 0) and "PASSED" or "FAILED",
			self.TestsRun,
			self.TestsPassed,
			self.TestsFailed,
			table.concat(breakdown_buffer, "\n\n\t\t")
		)
	end
}

local Tests = {
	Root = PATH .. ".",
	Coeus = nil
}

function Tests:Init(coeus)
	self.Coeus = coeus
end

function Tests:RunTestModule(object)
	local results = {
		Name = object.Name or "[unknown]",
		TestsRun = 0,
		TestsPassed = 0,
		TestsFailed = 0,
		TestResults = {}
	}

	setmetatable(results, results_metatable)

	if (object.Tests) then
		if (object.TestStart) then
			object:TestStart()
		end

		for name, value in pairs(object.Tests) do
			local result = {
				Name = name,
				Passed = true,
				Message = nil,
			}

			if (type(value) == "function") then
				local success, err = pcall(value, object, result)

				if (not success) then
					result.Passed = false
					result.Message = err
				end
			end

			results.TestsRun = results.TestsRun + 1
			if (result.Passed) then
				results.TestsPassed = results.TestsPassed + 1
			else
				results.TestsFailed = results.TestsFailed + 1
			end

			table.insert(results.TestResults, result)
		end

		if (object.TestEnd) then
			object:TestEnd()
		end
	end

	return results
end

function Tests:RunTestFile(name, path)
	path = path or name_to_file(self.Root .. name)
	local mode = lfs.attributes(path, "mode")

	if (mode == "file") then
		local chunk, err = loadfile(path)

		if (not chunk) then
			error("Test Error: " .. err)
		end

		local success, object = pcall(chunk, self.Coeus)

		if (not success) then
			return nil, object
		end

		return self:RunTestModule(object)
	else
		error("Could not load test at '" .. path .. "': file does not exist")
	end
end

function Tests:RunTestFolder(name, path)
	path = path or name_to_directory(self.Root .. name)
	local mode = lfs.attributes(path, "mode")

	if (mode == "directory") then
		local result_set = {}
		setmetatable(result_set, simple_lr_composite)

		for file in lfs.dir(path) do
			if (file ~= "." and file ~= "..") then
				local full = path .. "/" .. file
				local mode = lfs.attributes(full, "mode")
				local result

				if (mode == "file") then
					result = self:RunTestFile(nil, full)
				elseif (mode == "directory") then
					result = self:RunTestFolder(nil, full)
				else
					print("Unknown error loading '" .. result .. "' of mode '" .. (mode or "nil") .. "'")
				end

				table.insert(result_set, result)
			end
		end

		return result_set
	else
		error("Could not load test folder at '" .. path .. "': folder does not exist")
	end
end

return Tests