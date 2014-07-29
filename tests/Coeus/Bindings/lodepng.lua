local Coeus = ...

return {
	Name = "Bindings.lodepng",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.lodepng")
		end
	}
}