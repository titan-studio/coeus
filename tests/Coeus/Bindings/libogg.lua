local Coeus = ...

return {
	Name = "Bindings.libogg",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.libogg")
		end
	}
}