local Coeus = (...)

return {
	Name = "Bindings.libogg",

	Tests = {
		{
			"Load", 
			function(self, result)
				Coeus:Load(self.Name)
			end
		}
	}
}