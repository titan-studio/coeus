local Coeus = ...

return {
	Name = "Bindings.libvorbisfile",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.libvorbisfile")
		end
	}
}