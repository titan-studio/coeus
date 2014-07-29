local Coeus = ...

return {
	Name = "Bindings.openal",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.openal")
		end
	}
}