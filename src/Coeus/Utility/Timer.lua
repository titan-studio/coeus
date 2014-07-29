local Coeus = (...)
local ffi = require("ffi")
local OOP = Coeus.Utility.OOP

local CPSleep = Coeus.Utility.CPSleep

local GLFW = Coeus.Bindings.GLFW
local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local Timer = OOP:Class() { 
	FPSUpdatePeriod = 1,

	current = 0,
	previous = 0,

	frame_count = 0,
	frame_time = 0,
	fps = 0
}

function Timer:_new()
	self.current = 0
	self.previous = 0
	self.frame_count = 0
	self.frame_time = 0
	self.fps = 0
end

function Timer:GetTime()
	return glfw.GetTime()
end

function Timer:Sleep(time)
	CPSleep(time)
end

function Timer:Step()
	self.current = self.GetTime()
	self.delta = self.current - self.previous
	self.fps = 1 / self.delta
	self.previous = self.current

	self.frame_time = self.frame_time + self.delta
	self.frame_count = self.frame_count + 1

	if self.frame_time > self.FPSUpdatePeriod then
		self.FPS = self.frame_count / self.frame_time

		self.frame_time = 0
		self.frame_count = 0
	end
end

function Timer:GetDelta()
	return self.delta
end

function Timer:GetFPS()
	return math.ceil(self.fps)
end

return Timer