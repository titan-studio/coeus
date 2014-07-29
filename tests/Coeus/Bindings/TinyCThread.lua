local Coeus = ...

return {
	Name = "Bindings.TinyCThread",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.TinyCThread")
		end
	}
}