local Coeus = (...)
local Table = Coeus.Utility.Table
local OOP = {}

function OOP:Class(...)
	local new = Table.DeepCopy(self.Object)
	new:Inherit(...)

	return function(target)
		if (target) then
			new.Is:GetInternal()[target] = true
			Table.Merge(new, target)
			return target
		else
			new.Is:GetInternal()[new] = true
			return new
		end
	end
end

function OOP:Static(...)
	local new = Table.DeepCopy(self.StaticObject)
	new:Inherit(...)

	return function(target)
		if (target) then
			new.Is:GetInternal()[target] = true
			Table.Merge(new, target)
			return target
		else
			new.Is:GetInternal()[new] = true
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

	if (object.__metatable) then
		for key, value in pairs(object.__metatable) do
			imeta[key] = value
		end
	end

	return interface
end

OOP.Object = {
	__metatable = {}
}

OOP.Object.Is = OOP:Wrap({[OOP.Object] = true})

--Class Methods
function OOP.Object:Inherit(...)
	local is = Table.Copy(self.Is:GetInternal())

	for key, item in ipairs({...}) do
		Table.DeepCopyMerge(item, self)

		if (item.Is) then
			for key, value in pairs(item.Is:GetInternal()) do
				is[key] = value or is[key]
			end
		end

		local imeta = item.__metatable or getmetatable(item)
		if (imeta) then
			Table.Merge(imeta, self.__metatable)
		end
	end

	self.Is = OOP:Wrap(is)

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

OOP.StaticObject = {}
OOP.StaticObject.Is = OOP:Wrap({[OOP.StaticObject] = true})
OOP.StaticObject.Inherit = OOP.Object.Inherit

return OOP