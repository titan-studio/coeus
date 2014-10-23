local Coeus = (...)
local OOP = Coeus.Utility.OOP

local Color = OOP:Class() {
	Red = 0,
	Green = 0,
	Blue = 0,
	Alpha = 0
}

function Color:_new(r, g, b, a)
	self.Red = r or 0
	self.Green = g or 0
	self.Blue = b or 0
	self.Alpha = a or 1
end

return Color