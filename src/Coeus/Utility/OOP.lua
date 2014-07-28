local Coeus = (...)
local Table = Coeus.Utility.Table
local OOP

OOP = {
	Objectify = function(self, target)
		Table.Merge(self.object, target)

		return target
	end,

	Class = function(self, ...)
		local new = Table.Merge(self.Object, {})
		new:Inherit(...)

		return function(target)
			target = target or {}
			
			Table.Merge(new, target)
			return target
		end
	end,

	Mix = function(self, ...)
		local result = {}
		local mixing = {}
		local imixing = {}
		local args = {...}

		for step, class in pairs(args) do
			for key, value in pairs(class) do
				local typed = type(value)

				if (typed == "function") then
					if (not mixing[key]) then
						mixing[key] = {value}
						imixing[value] = true
					else
						if (not imixing[value]) then
							imixing[value] = true
							table.insert(mixing[key], value)
						end
					end
				elseif (not result[key]) then
					if (typed == "table") then
						result[key] = Table.DeepCopy(value)
					else
						result[key] = value
					end
				end
			end
		end

		for key, value in pairs(mixing) do
			if (#value > 1) then
				result[key] = function(...)
					local result = {}

					for index, functor in ipairs(value) do
						result = {functor(...)}
					end

					return unpack(result)
				end
			else
				result[key] = value[1]
			end
		end

		return result
	end,

	Object = {
		Inherit = function(self, ...)
			local metatable = getmetatable(self)

			for key, item in ipairs({...}) do
				Table.Merge(item, self)
				Table.Merge(getmetatable(item), metatable)
			end

			setmetatable(self, metatable)

			return self
		end,

		Copy = function(self)
			local instance = Table.DeepCopy(self)

			setmetatable(instance, getmetatable(self))
			return instance
		end,

		New = function(self, ...)
			if (self._new) then
				local instance = self:Copy()
				instance.GetClass = function() return self end
				instance:_new(...)

				return instance
			else
				return self:Copy()
			end
		end,

		Destroy = function(self, ...)
		end,

		AddMetamethods = function(self, methods)
			local metatable = getmetatable(self)

			if (metatable) then
				Table.Copy(methods, metatable)
			else
				setmetatable(self, methods)
			end
		end
	}
}

return OOP