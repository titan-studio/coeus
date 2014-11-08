local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local next_priority = 1
local Layer = OOP:Class() {
	Name = "Unnamed Layer",
	flag = false,
	scene = false,

	Sorted = false
}
Layer.Flag = {
	None = 0,
	UnlitBackground = 1,
	Geometry = 2,
	TransparentGeometry = 3,
	Unlit2D = 4,
	Lights = 5
}

function Layer:_new(scene, flag, name)
	self.scene = scene
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

function Layer:Render()
	for i, v in ipairs(self.scene.Actors) do
		v:Render(self.flag)
	end
end

return Layer