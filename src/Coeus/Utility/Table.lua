local Coeus = (...)
local Table = {}

function Table.IsDictionary(source)
	for key in pairs(source) do
		if (type(key) ~= "number") then
			return true
		end
	end

	return false
end

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

function Table.ArrayData(target, ...)
	for key, value in ipairs(target) do
		target[key] = nil
	end

	for key, value in ipairs({...}) do
		target[key] = value
	end

	return target
end

function Table.ArrayUpdate(target, ...)
	for key, value in ipairs({...}) do
		target[key] = value
	end

	return target
end

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

function Table.Copy(source, target)
	target = target or {}

	for key, value in pairs(source) do
		target[key] = value
	end

	return target
end

function Table.DeepCopy(source, target, break_lock)
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

function Table.CopyMerge(source, target, break_lock)
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

function Table.DeepCopyMerge(source, target, break_lock)
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

function Table.Invert(source, target)
	target = target or {}

	for key, value in pairs(source) do
		target[value] = key
	end

	return target
end

function Table.Contains(source, value)
	for key, compare in pairs(source) do
		if (compare == value) then
			return true
		end
	end

	return false
end

return Table