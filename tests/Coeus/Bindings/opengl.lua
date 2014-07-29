local Coeus = ...

return {
	Name = "Bindings.opengl",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.opengl")
		end
	}
}