local Coeus = ...

return {
	Name = "Bindings.OpenAL",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.OpenAL")
		end
	}
}