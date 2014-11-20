--[[
	Table Utilities

	Provides useful utility functions for handling tables in both dictionary and
	array data.
]]

local C = (...)
local Coeus = C:Get("Coeus")
local Table = {}

--[[
	Returns whether or not any dictionary keys are defined in the table.
]]
function Table.IsDictionary(source)
	for key in pairs(source) do
		if (type(key) ~= "number") then
			return true
		end
	end

	return false
end

--[[
	Returns whether the table has sequential numeric keys.
	This assumes that ipairs iterates in order, which may not be correct.
]]
function Table.IsSequence(source)
	local last = 0

	for key in ipairs(source) do
		if (key ~= last + 1) then
			return false
		else
			last = key
		end
	end

	return (last ~= 0)
end

--[[
	Clears the target array and fills it with the extra arguments passed to
	ArrayData.
]]
function Table.ArrayData(target, ...)
	for key, value in ipairs(target) do
		target[key] = nil
	end

	for key = 1, select("#", ...) do
		target[key] = select(key, ...)
	end

	return target
end

--[[
	Fills the table's array part with the extra arguments passed to ArrayUpdate.
	Unlike ArrayData, ArrayUpdate does not clear the target table.
]]
function Table.ArrayUpdate(target, ...)
	for key = 1, select("#", ...) do
		target[key] = select(key, ...)
	end

	return target
end

--[[
	Checks whether two tables have the same values for each of their keys.
]]
function Table.Equal(first, second, no_reverse)
	for key, value in pairs(first) do
		if (second[key] ~= value) then
			return false, key
		end
	end

	if (not no_reverse) then
		return Table.Equal(second, first, true)
	else
		return true
	end
end

--[[
	Iterates through two tables and compares all values. This differs from
	Equals in that tables are in turn iterated through instead of hard-compared.
]]
function Table.Congruent(first, second, no_reverse)
	for key, value in pairs(first) do
		local value2 = second[key]

		if (type(value) == type(value2)) then
			if (type(value) == "table") then
				if (not Table.Congruent(value, value2)) then
					return false, key
				end
			else
				if (value ~= value2) then
					return false, key
				end
			end
		else
			return false, key
		end
	end

	if (not no_reverse) then
		return Table.Congruent(second, first, true)
	else
		return true
	end
end

--[[
	Performs a shallow copy of the source table.
	Creates a new table unless a target table is specified for data output.
]]
function Table.Copy(source, target)
	target = target or {}

	for key, value in pairs(source) do
		target[key] = value
	end

	return target
end

--[[
	Performs a deep copy of the source table.
	Creates a new table unless a target table is specified for data output.
	Calls the 'Copy' method of any userdata objects if they have one.
	Does not protect against infinite loops in any way.
]]
function Table.DeepCopy(source, target)
	target = target or {}

	for key, value in pairs(source) do
		local typeof = type(value)

		if (typeof == "table") then
			target[key] = Table.DeepCopy(value)
		elseif (typeof == "userdata" and value.Copy) then
			target[key] = value:Copy()
		else
			target[key] = value
		end
	end

	return target
end

--[[
	Performs a shallow merge from a source table to a target table.
	This is essentially a shallow copy with any keys already existing in the
	target table ignored instead of overridden.
]]
function Table.Merge(source, target)
	if (not target) then
		return nil
	end

	for key, value in pairs(source) do
		if (not target[key]) then
			target[key] = value
		end
	end

	return target
end

--[[
	Performs a shallow copymerge from a source table to a target table.
	This is the same as a regular shallow merge except that tables and userdata
	are both copied and placed into the target.
]]
function Table.CopyMerge(source, target)
	if (not target) then
		return nil
	end

	for key, value in pairs(source) do
		if (not target[key]) then
			local typeof = type(value)

			if (typeof == "table") then
				target[key] = Table.Copy(value)
			elseif (typeof == "userdata" and value.Copy) then
				target[key] = value:Copy()
			else
				target[key] = value
			end
		end
	end

	return target
end

--[[
	Performs a deep copymerge from a source table into a target table.
	This is just like a shallow CopyMerge, except that tables are deep copied.
]]
function Table.DeepCopyMerge(source, target)
	if (not target) then
		return nil
	end

	for key, value in pairs(source) do
		if (not target[key]) then
			local typeof = type(value)

			if (typeof == "table") then
				target[key] = Table.DeepCopy(value)
			elseif (typeof == "userdata" and value.Copy) then
				target[key] = value:Copy()
			else
				target[key] = value
			end
		end
	end

	return target
end

--[[
	Inverts the keys and values of a table and puts them into a target table,
	which by default is a new table.
	The behavior of this function is defined if duplicate values exist.
]]
function Table.Invert(source, target)
	target = target or {}

	for key, value in pairs(source) do
		target[value] = key
	end

	return target
end

--[[
	Iterates through both the table's array and dictionary parts and returns
	whether a given value exists in the table.
]]
function Table.Contains(source, value)
	for key, compare in pairs(source) do
		if (compare == value) then
			return true
		end
	end

	return false
end

return Table