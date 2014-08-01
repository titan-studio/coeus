local Coeus = ...

return {
	Name = "Bindings.LuaJIT",

	Tests = {
		Load = function(self, result)
			Coeus:Load("Bindings.LuaJIT")
		end
	}
}