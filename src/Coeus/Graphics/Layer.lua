local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local next_priority = 1
local Layer = OOP:Class() {
	context = false,
	name = "Unnamed Layer",
	flag = false,
	components = {},
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

function Layer:RegisterComponent(component)
	for i, v in ipairs(self.components) do
		if v == component then
			return
		end
	end
	table.insert(self.components, component)
end

function Layer:DeregisterComponent(component)
	for i, v in ipairs(self.components) do
		if v == component then
			table.remove(self.components, i)
			return true
		end
	end
	return false
end

function Layer:Render()
	for i, v in ipairs(self.components) do
		v:Render()
	end
end

return Layer