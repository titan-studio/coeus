local Coeus = require("src.Coeus")

local OOP = Coeus.Utility.OOP

local test_class = OOP:Class() {
	x = 1
}

function test_class:_new()
	print("I'm new!")

	self.y = 6
end

local test_instance = test_class:New()
print(test_instance.x, test_instance.y)