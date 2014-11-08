local Coeus = (...)

return {
	Name = "Bindings.GLFW",

	Tests = {
		{
			"Load", 
			function(self, result)
				Coeus:Load(self.Name)
			end
		}
	}
}