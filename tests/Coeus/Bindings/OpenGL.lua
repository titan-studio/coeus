local Coeus = (...)

return {
	Name = "Bindings.OpenGL",

	Tests = {
		{
			"Load", 
			function(self, result)
				Coeus:Load(self.Name)
			end
		}
	}
}