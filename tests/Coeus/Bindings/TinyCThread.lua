local Coeus = (...)

return {
	Name = "Bindings.TinyCThread",

	Tests = {
		{
			"Load", 
			function(self, result)
				Coeus:Load(self.Name)
			end
		}
	}
}