local Coeus = ...

return {
	Name = "Bindings.zlib",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.zlib")
		end
	}
}