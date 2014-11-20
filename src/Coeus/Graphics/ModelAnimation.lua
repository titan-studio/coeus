local C = (...)
local Coeus = C:Get("Coeus")
local OOP = Coeus.Utility.OOP

local ModelAnimation = OOP:Class() {
	Name = "Unnamed Animation",

	Model = false,

	Looping = false,
	Framerate = 0,

	Frames = {}
}

function ModelAnimation:_new()

end

return ModelAnimation