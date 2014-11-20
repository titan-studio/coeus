local C = (...)
local Coeus = C:Get("Coeus")

return {
	Name = "Bindings.C_",

	Tests = {
		{
			"Load", 
			function(self, result)
				C:Get(self.Name)
			end
		}
	}
}