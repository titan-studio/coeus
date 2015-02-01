local Coeus = (...)
Coeus:AddGrapheneSubmodule("Graphite")

return {
	Config = {
		Debug = true,
		Graphics = Coeus.Graphite.Configuration:Create("Coeus.Config.Graphics") {
			Backend = "GLFW"
		}
	}
}