--[[
	Standard OOP Interface

	Provides standardized object orientation facilities including multiple
	inheritance, instance pointers, typechecking, metamethod handling, and
	proper constructors and destructors.
]]

local Coeus = (...)
local Table = Coeus.Utility.Table
local OOP = {}

--[[
	Defines a new class, inheriting from all classes passed as arguments.
	Classes are inherited in decreasing priority, meaning the first class to
	define a property will have its definition stand.
]]
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

--[[
	Defines a new static object with inheritance capaibilities. These differ
	from regular classes only in that they cannot be instantiated.
]]
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

--[[
	Constructs a userdata instance pointer to the given object. This allows easy
	differentiation between classes and instances, provides garbage collection
	metamethod capability in LuaJIT, and allows easier data binding.

	A userdata object can optionally be passed in to be used as the pointer.
]]
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

--CLASS METHODS

--[[
	Inherits from a list of classes with decreasing priority.
]]
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

--[[
	Creates a new instance of a class, calling the class's constructor (_new) if
	it is defined.
]]
function OOP.Object:New(...)
	local internal = Table.DeepCopy(self)
	local instance = OOP:Wrap(internal)

	internal.GetClass = function()
		return self
	end

	if (instance._new) then
		local result = instance:_new(...)

		if (result) then
			return result
		end
	end

	return instance
end

--[[
	Creates a new instance of a class, calling the class's release constructor
	(RELEASE__new) if it is defined.
]]
function OOP.Object:RELEASE_New(...)
	local internal = Table.DeepCopy(self)
	local instance = OOP:Wrap(internal)

	internal.GetClass = function()
		return self
	end

	if (instance.RELEASE__new) then
		local result = instance:RELEASE__new(...)

		if (result) then
			return result
		end
	end

	return instance
end

--[[
	Creates a new instance of a class, calling the class's debug constructor
	(DEBUG__new) if it is defined.
]]
function OOP.Object:DEBUG_New(...)
	local internal = Table.DeepCopy(self)
	local instance = OOP:Wrap(internal)

	internal.GetClass = function()
		return self
	end

	if (instance.DEBUG__new) then
		local result = instance:DEBUG__new(...)

		if (result) then
			return result
		end
	end

	return instance
end

--[[
	Adds metamethods to be applied to instances of the class. This is preferred
	over setmetatable.
]]
function OOP.Object:AddMetamethods(methods)
	for key, value in pairs(methods) do
		self.__metatable[key] = value
	end
end

--INSTANCE METHODS

--[[
	Creates a copy of the object and wraps it with an instance pointer.
]]
function OOP.Object:Copy()
	return OOP:Wrap(Table.DeepCopy(self:GetInternal()))
end

--[[
	Repoints this instance pointer to point to another piece of data.
]]
function OOP.Object:PointTo(object)
	OOP:Wrap(object, self)
end

--[[
	A stub method.
	Classes that require a destructor should override this method as it's
	automatically called upon garbage collection and can also be called by other
	code.
]]
function OOP.Object:Destroy()
end

--These definitions line out the StaticObject class.
OOP.StaticObject = {}
OOP.StaticObject.Is = OOP:Wrap({[OOP.StaticObject] = true})
OOP.StaticObject.Inherit = OOP.Object.Inherit

return OOP