local Coeus = (...)

return {
	Name = "Bindings.C",

	Tests = {
		{
			"Load", 
			function(self, result)
				Coeus:Load(self.Name)
			end
		}
	}
}