local Coeus = ...

return {
	Name = "Bindings.win32",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.win32")
		end
	}
}