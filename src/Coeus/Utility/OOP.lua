local Coeus = (...)
local Table = Coeus.Utility.Table
local OOP = {}

function OOP:Class(...)
	local new = Table.DeepCopy(self.Object)
	new:Inherit(...)

	return function(target)
		if (target) then
			Table.Merge(new, target)
			return target
		else
			return new
		end
	end
end

function OOP:Wrap(object, userdata)
	local interface = userdata or newproxy(true)
	local imeta = getmetatable(interface)

	object.GetInternal = function()
		return object
	end

	imeta.__index = object
	imeta.__newindex = object
	imeta.__gc = function(self)
		if (self.Destroy) then
			self:Destroy()
		end
	end

	for key, value in pairs(object.__metatable) do
		imeta[key] = value
	end

	return interface
end

OOP.Object = {
	__metatable = {}
}

--Class Methods
function OOP.Object:Inherit(...)
	for key, item in ipairs({...}) do
		Table.DeepCopyMerge(item, self)

		local imeta = item.__metatable or getmetatable(item)
		if (imeta) then
			Table.Merge(imeta, self.__metatable)
		end
	end

	return self
end

function OOP.Object:New(...)
	local internal = Table.DeepCopy(self)
	local instance = OOP:Wrap(internal)

	internal.GetClass = function()
		return self
	end

	if (instance._new) then
		instance:_new(...)
	end

	return instance
end

function OOP.Object:AddMetamethods(methods)
	for key, value in pairs(methods) do
		self.__metatable[key] = value
	end
end

--Object Methods
function OOP.Object:Copy()
	return OOP:Wrap(Table.DeepCopy(self:GetInternal()))
end

function OOP.Object:PointTo(object)
	OOP:Wrap(object, self)
end

function OOP.Object:Destroy()
end

return OOP