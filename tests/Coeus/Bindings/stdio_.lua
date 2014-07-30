local Coeus = ...

return {
	Name = "Bindings.stdio_",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.stdio_")
		end
	}
}