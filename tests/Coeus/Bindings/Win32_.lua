local Coeus = ...

return {
	Name = "Bindings.Win32_",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.Win32_")
		end
	}
}