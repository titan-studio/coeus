local Coeus = (...)

return {
	Name = "Bindings.LuaJIT",

	Tests = {
		{
			"Load", 
			function(self, result)
				Coeus:Load(self.Name)
			end
		}
	}
}