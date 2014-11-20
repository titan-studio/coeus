local C = (...)
local Coeus = C:Get("Coeus")

return {
	Name = "Bindings.stb_truetype",

	Tests = {
		{
			"Load", 
			function(self, result)
				C:Get(self.Name)
			end
		}
	}
}