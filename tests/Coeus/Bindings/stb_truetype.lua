local Coeus = ...

return {
	Name = "Bindings.stb_truetype",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.stb_truetype")
		end
	}
}