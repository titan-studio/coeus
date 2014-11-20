local C = (...)
local Coeus = C:Get("Coeus")
local OOP = Coeus.Utility.OOP

local ModelJoint = OOP:Class() {
	Name = "Unnamed Joint",
	Parent = false,

	Model = false,
	Pose = false
}

function ModelJoint:_new()

end

return ModelJoint