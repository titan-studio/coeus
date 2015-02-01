local Coeus = (...)
Coeus:AddGrapheneSubmodule("Graphite")
for k, v in pairs(Coeus.Graphite.Config) do print(k, v) end

return {
	Config = {
		Debug = true,
		Graphics = Coeus.Graphite.Config:Create("Coeus.Config.Graphics") {
			Backend = "GLFW"
		}
	}
}