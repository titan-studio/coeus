local Coeus = (...)
local ffi = require("ffi")
local CPSleep = Coeus.Utility.CPSleep
local GLFW = Coeus.Bindings.GLFW
local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local Timing = { 
	current = 0,
	previous = 0,

	frame_count = 0,
	frame_sum = 0,
	FPS = 0
}

function Timing.GetTime()
	return glfw.GetTime()
end

function Timing.Sleep(time)
	CPSleep(time)
end

function Timing.Step()
	Timing.current = Timing.GetTime()
	Timing.delta = Timing.current - Timing.previous
	Timing.previous = Timing.current

	Timing.frame_sum = Timing.frame_sum + Timing.delta
	Timing.frame_count = Timing.frame_count + 1
	if Timing.frame_count >= 30 then
		Timing.FPS = 1 / (Timing.frame_sum / Timing.frame_count)
		Timing.frame_sum = 0
		Timing.frame_count = 0
	end
end

function Timing.GetDelta()
	return Timing.delta
end

function Timing.GetFPS()
	return math.ceil(Timing.FPS)
end

return Timing