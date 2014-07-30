local Coeus = ...

return {
	Name = "Bindings.FreeType",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.FreeType")
		end
	}
}