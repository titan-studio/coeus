local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local next_priority = 1
local Layer = OOP:Class() {
	context = false,
	name = "Unnamed Layer",
	flag = false,
	actors = {},

	Sorted = false
}
Layer.Flag = {
	None = 0,
	UnlitBackground,
	Geometry,
	TransparentGeometry,
	Unlit2D,
	Lights
}

function Layer:_new(context, flag, name)
	self.context = context
	self.flag = flag or Layer.Flag.Geometry

	self.name = name
	if not name then
		for i, v in ipairs(Layer.Flag) do
			if v == flag then
				self.name = i
				break
			end
		end
	end
end

function Layer:Resort()
	table.sort(self.actors, function(a, b)
		return a.DrawOrder < b.DrawOrder
	end)
end

function Layer:RegisterActor(actor)
	for i, v in ipairs(self.actors) do
		if v == actor then
			return
		end
	end
	table.insert(self.actors, actor)
	if self.Sorted then
		self:Resort()
	end
end

function Layer:DeregisterActor(actor)
	for i, v in ipairs(self.actors) do
		if v == actor then
			table.remove(self.actors, i)
			if self.Sorted then
				self:Resort()
			end
			return true
		end
	end
	return false
end

function Layer:Render()
	for i, v in ipairs(self.actors) do
		v:Render()
	end
end

return Layer