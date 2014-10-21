local Coeus = (...)
local OOP = Coeus.Utility.OOP

local BaseApplication = OOP:Class() {
	Windows = {},

	Timer = false,

	TargetFPS = 60,
	CloseIfNoWindows = true,

	quit = false
}

function BaseApplication:_new()
	self.Timer = Coeus.Utility.Timer:New()
end

function BaseApplication:RegisterWindow(window, is_essential)
	table.insert(self.Windows, window)
	window.Application = self

	if is_essential then
		window.Closed:Listen(function()
			self.quit = true
		end)
	end
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
		local open = 0
		for i, v in ipairs(self.Windows) do
			v:Update(dt)
			if not v.IsClosed then
				open = open + 1
			end
		end
		self:Update(dt)

		for i, v in ipairs(self.Windows) do
			v:PreRender()
			v:Render()
			v:PostRender()
		end

		if open == 0 and self.CloseIfNoWindows then
			self.quit = true
		end
	end
end

return BaseApplication