local Coeus = ...

return {
	Name = "Bindings.libvorbis",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.libvorbis")
		end
	}
}