local Coeus = ...

return {
	Name = "Bindings.Win32",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.Win32")
		end
	}
}