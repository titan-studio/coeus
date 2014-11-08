local Coeus = (...)

return {
	Name = "Bindings.zlib",

	Tests = {
		{
			"Load", 
			function(self, result)
				Coeus:Load(self.Name)
			end
		}
	}
}