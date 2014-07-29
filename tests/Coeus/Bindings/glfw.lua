local Coeus = ...

return {
	Name = "Bindings.glfw",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.glfw")
		end
	}
}