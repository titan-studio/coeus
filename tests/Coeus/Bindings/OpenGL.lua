local Coeus = ...

return {
	Name = "Bindings.OpenGL",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.OpenGL")
		end
	}
}