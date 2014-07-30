local Coeus = ...

return {
	Name = "Bindings.luajit",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.luajit")
		end
	}
}