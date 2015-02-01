local Coeus = (...)
local OOP = Coeus.Graphite.OOP
local Timer = Coeus.System.Timer

local BaseApplication = OOP:Class() 
	:Members {
		CloseIfNoWindows = true,
		TargetFPS = 60,
		
		Timer = false,
		Windows = {},

		quit = false
	}

function BaseApplication:_init()
	self.Timer = Timer:New()
end

function BaseApplication:Initialize()
	-- Empty in BaseApplication
end

function BaseApplication:Update(delta_time)
	-- Empty in BaseApplication
end

function BaseApplication:Destroy()
	for i, v in ipairs(self.Windows) do
		v:Close()
		v:Destroy()
	end
	self.Windows = {}
	self.quit = true
	return
end

function BaseApplication:RegisterWindow(window, quit_on_close)
	table.insert(self.Windows, window)
	window.Application = self

	if (quit_on_close) then
		window.Closed:Listen(function()
			self.quit = true
		end)
	end
end

function BaseApplication:MainLoop()
	self:Initialize()

	while (not self.quit) do
		self.Timer:Step()

		local delta_time = self.Timer:GetDelta()
		local open = 0

		for i, v in ipairs(self.Windows) do
			if (not v.IsClosed) then
				v:Update(delta_time)
				open = open + 1
			end
		end
		self:Update(delta_time)

		for i, v in ipairs(self.Windows) do
			if (not v.IsClosed) then
				v:Draw()
			end
		end

		if (open == 0 and self.CloseIfNoWindows) then
			self.quit = true
		end
	end
end

return BaseApplication