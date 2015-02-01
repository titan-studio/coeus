--[[
	Timer

	Provides sleep mechanics for relatively precise timing.
	Can be used as a global timer by using the object as-is or instanced for
	specific timing needs.
]]

local Coeus = (...)
local ffi = require("ffi")
local OOP = Coeus.Graphite.OOP

local GLFW = Coeus.Bindings.GLFW
local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local Timer = OOP:Class() 
	:Members { 
		FPSUpdateRate = 1,
		SleepUntilPollingRate = 0.1,

		current = 0,
		previous = 0,

		frame_count = 0,
		frame_time = 0,
		fps = 0
	}

--[[
	Creates a new timer object and resets its properties.
]]
function Timer:_init()
	self.current = 0
	self.previous = 0
	self.frame_count = 0
	self.frame_time = 0
	self.fps = 0
end

--[[
	Returns the current global time of the game. Recommended for use only for
	relative timing, as it may not start at 0.
]]
function Timer:GetTime()
	return glfw.GetTime()
end

--[[
	Sleeps for at least the period of time, given in seconds.
]]
function Timer:Sleep(time)
	Coeus.System.Sleep(time)
end

--[[
	Polls the given method according to SleepUntilPollingRate until it returns
	true. Any additional arguments to the method can be passed in as extra
	arguments to SleepUntil. 
]]
function Timer:SleepUntil(method, ...)
	while (not method(...)) do
		self:Sleep(self.SleepUntilPollingRate)
	end
end

--[[
	Intended for use in an event loop, Step captures the time since the last
	call to Step and calculates frame delta and frames per second.
]]
function Timer:Step()
	self.current = self.GetTime()
	self.delta = self.current - self.previous
	self.previous = self.current

	self.frame_time = self.frame_time + self.delta
	self.frame_count = self.frame_count + 1

	if self.frame_time > self.FPSUpdateRate then
		self.fps = self.frame_count / self.frame_time

		self.frame_time = 0
		self.frame_count = 0
	end
end

--[[
	Returns the amount of time the last frame took according to Step.
]]
function Timer:GetDelta()
	return self.delta
end

--[[
	Returns an integer representation of the current frames per second, rounded
	to the nearest integer. This only updates every FPSUpdateRate seconds.
]]
function Timer:GetFPS()
	return math.ceil(self.fps)
end

return Timer