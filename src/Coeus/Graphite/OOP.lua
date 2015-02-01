--[[
	Graphite for Lua
	Object Orientation System

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

local Graphite = (...)
local Dictionary = Graphite.Dictionary
local OOP = {}

local config = Graphite.Config.OOP

-- Method names
local name_initializer = config:_require("InitializerName")
local name_constructor = config:_require("ConstructorName")
local name_placement_constructor = config:_require("PlacementConstructorName")
local name_destructor = config:_require("DestructorName")
local name_copy = config:_require("CopyName")
local name_type_checker = config:_require("TypeCheckerName")

-- Attributes in the configuration
local default_attributes = config:_require("DefaultAttributes")
local default_static_attributes = config:_require("DefaultStaticAttributes")

config:_lock()

-- Utility methods
local function handle_indirection(class, instance)
	if (class.attributes.InstanceIndirection) then
		local internal = instance
		instance = newproxy(true)

		local meta = getmetatable(instance)
		meta.__index = internal
		meta.__newindex = internal
		meta.__pairs = internal
		meta.__ipairs = internal
		meta.__gc = function(self)
			if (self[name_destructor]) then
				return self[name_destructor](self)
			end
		end
	end

	return instance
end

local function apply_metatable(class, instance)
	if (class.attributes.InstanceIndirection) then
		-- If we wrapped the object in a userdata, we need to apply metatables a little differently.
		Dictionary.ShallowCopy(class.metatable, getmetatable(instance))
	else
		-- The InstancedMetatable attribute determines whether the metatable
		-- is class-specific or instance-specific.
		if (class.attributes.InstancedMetatable) then
			setmetatable(instance, Dictionary.ShallowCopy(class.metatable))
		else
			setmetatable(instance, class.metatable)
		end
	end
end

OOP.Attributes = {
	Class = {},
	PreConstructor = {},
	PostConstructor = {},
	Copy = {}
}

function OOP:RegisterAttribute(type, name, application)
	local typeset = self.Attributes[type]

	if (not typeset) then
		error(("Could not register attribute of type %q: unknown attribute type"):format(type), 2)
	end

	typeset[name] = application
end

OOP.BaseClass = {
	members = {},
	metatable = {},
	attributes = {},
	typecheck = {}
}

function OOP.BaseClass:Inherits(...)
	for i = 1, select("#", ...) do
		local object = select(i, ...)

		Dictionary.DeepCopyMerge(object.members, self.members)
		Dictionary.DeepCopyMerge(object.metatable, self.metatable)
		Dictionary.ShallowMerge(object.attributes, self.attributes)
		Dictionary.ShallowMerge(object.typecheck, self.typecheck)

		for attribute in pairs(object.attributes) do
			local found = OOP.Attributes.Class[attribute]
			if (found) then
				found(self)
			end
		end
	end

	return self
end

function OOP.BaseClass:Attributes(attributes)
	Dictionary.ShallowCopy(attributes, self.attributes)

	for attribute in pairs(attributes) do
		local found = OOP.Attributes.Class[attribute]
		if (found) then
			found(self)
		end
	end

	return self
end

function OOP.BaseClass:Metatable(metatable)
	Dictionary.ShallowCopy(metatable, self.metatable)

	return self
end

function OOP.BaseClass:Members(members)
	Dictionary.ShallowCopy(members, self.members)

	return self
end

OOP.Object = Dictionary.DeepCopy(OOP.BaseClass)
	--:Attributes(default_attributes)

OOP.Object.members.class = newproxy(true)
getmetatable(OOP.Object.members.class).__index = OOP.Object

OOP.Object.typecheck[OOP.Object] = true
OOP.Object[name_type_checker] = OOP.Object.typecheck

OOP.Object[name_placement_constructor] = function(self, instance, ...)
	local instance = {}

	if (self.attributes.SparseInstances) then
		setmetatable(instance, {__index = self.members})
	else
		Dictionary.DeepCopy(self.members, instance)
	end

	instance.self = instance.self or instance

	instance.class = newproxy(true)
	getmetatable(instance.class).__index = self

	-- We wrap the typechecking in a userdata so it doesn't get copied when our instance does.
	instance[name_type_checker] = newproxy(true)
	getmetatable(instance[name_type_checker]).__index = self.typecheck

	-- InstanceIndirection attribute wraps the object in a userdata
	-- This allows a __gc metamethod with Lua 5.1 and LuaJIT.
	-- As a side effect, 'self' becomes a userdata
	-- Get the internal table with self.self
	instance = handle_indirection(self, instance)
	apply_metatable(self, instance)

	for attribute in pairs(self.attributes) do
		local found = OOP.Attributes.PreConstructor[attribute]
		if (found) then
			found(self, instance)
		end
	end

	-- Call the defined constructor
	if (instance[name_initializer]) then
		instance[name_initializer](instance, ...)
	end

	for attribute in pairs(self.attributes) do
		local found = OOP.Attributes.PostConstructor[attribute]
		if (found) then
			found(self, instance)
		end
	end

	return instance
end

-- Constructor wrapper
OOP.Object[name_constructor] = function(self, ...)
	return self[name_placement_constructor](self, {}, ...)
end

OOP.Object.members[name_copy] = function(self)
	local copy = Dictionary.DeepCopy(self.self)

	if (self.class.attributes.SparseInstances) then
		setmetatable(copy, {__index = self.class.members})
	end

	copy = handle_indirection(self.class, copy)
	apply_metatable(self.class, copy)

	for attribute in pairs(self.class.attributes) do
		local found = OOP.Attributes.Copy[attribute]
		if (found) then
			found(self, copy)
		end
	end

	return copy
end

OOP.StaticObject = Dictionary.DeepCopy(OOP.BaseClass)
	--:Attributes(default_static_attributes)

OOP.StaticObject.members.class = newproxy(true)
getmetatable(OOP.StaticObject.members.class).__index = OOP.StaticObject

OOP.StaticObject.typecheck[OOP.StaticObject] = true
OOP.StaticObject[name_type_checker] = OOP.StaticObject.typecheck

function OOP:Class()
	local class = Dictionary.DeepCopy(self.BaseClass)

	Dictionary.DeepCopy(self.Object, class)

	class.typecheck[class] = true

	class.class = newproxy(true)
	getmetatable(class.class).__index = class

	setmetatable(class, {
		__newindex = class.members
	})

	return class
end

function OOP:StaticClass()
	local class = Dictionary.ShallowCopy(self.BaseClass)

	Dictionary.DeepCopy(self.StaticObject, class)

	class.typecheck[class] = true

	setmetatable(class, {
		__newindex = class.members
	})

	return class
end

return OOP