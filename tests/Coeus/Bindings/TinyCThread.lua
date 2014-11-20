local C = (...)
local Coeus = C:Get("Coeus")

return {
	Name = "Bindings.TinyCThread",

	Tests = {
		{
			"Load", 
			function(self, result)
				C:Get(self.Name)
			end
		}
	}
}