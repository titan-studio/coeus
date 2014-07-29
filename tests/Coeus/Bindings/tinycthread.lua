local Coeus = ...

return {
	Name = "Bindings.tinycthread",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.tinycthread")
		end
	}
}