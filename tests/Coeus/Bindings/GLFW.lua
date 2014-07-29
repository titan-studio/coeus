local Coeus = ...

return {
	Name = "Bindings.GLFW",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.GLFW")
		end
	}
}