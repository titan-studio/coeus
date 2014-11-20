local C = (...)
local Coeus = C:Get("Coeus")

return {
	Name = "Bindings.libvorbis",

	Tests = {
		{
			"Load", 
			function(self, result)
				C:Get(self.Name)
			end
		}
	}
}