local Coeus = (...)
local OOP = Coeus.Utility.OOP

local BaseApplication = OOP:Class() {
	windows = {},

	Timer = false,

	TargetFPS = 60,

	quit = false
}

function BaseApplication:_new()
	self.Timer = Coeus.Utility.Timer:New()
end

function BaseApplication:RegisterWindow(window)
	table.insert(self.windows, window)
end

function BaseApplication:Initialize()
end

function BaseApplication:Update(dt)
end

function BaseApplication:Render()
end

function BaseApplication:Destroy()
end

function BaseApplication:Main()
	self:Initialize()

	while not self.quit do 
		self.Timer:Step()

		local dt = self.Timer:GetDelta()
		for i, v in ipairs(self.windows) do
			v:Update(dt)
		end
		self:Update(dt)

		for i, v in ipairs(self.windows) do
			
		end
	end
end

return BaseApplication