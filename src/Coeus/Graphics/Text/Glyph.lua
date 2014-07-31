local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local Glyph = OOP:Class() {
	Texture = false,
	Vertices = false,
	Codepoint = 0,
	Spacing = 0,
	BearingX = 0
}

return Glyph