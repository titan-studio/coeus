local Coeus = (...)

return {
	Name = "Bindings.libvorbisfile",

	Tests = {
		{
			"Load", 
			function(self, result)
				Coeus:Load(self.Name)
			end
		}
	}
}