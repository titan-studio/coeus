local Coeus = (...)

return {
	Name = "Bindings.Win32_",

	Tests = {
		{
			"Load", 
			function(self, result)
				Coeus:Load(self.Name)
			end
		}
	}
}