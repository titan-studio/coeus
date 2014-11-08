local Coeus = (...)

return {
	Name = "Bindings.libvorbis",

	Tests = {
		{
			"Load", 
			function(self, result)
				Coeus:Load(self.Name)
			end
		}
	}
}