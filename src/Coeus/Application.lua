local Coeus = (...)
local OOP = Coeus.Utility.OOP
local Timer = Coeus.Utility.Timer

local GLFW = Coeus.Bindings.GLFW
local GL = Coeus.Bindings.OpenGL

local glfw = GLFW.glfw
GLFW = GLFW.GLFW

local gl = GL.gl
GL = GL.GL

local Application = OOP:Class() {
	Window = false,
	Timer = false,

	TargetFPS = 60
}

function Application:_new(window)
	self.Window = window
	self.Timer = Timer:New()
end

function Application:Initialize()
end

function Application:Update(dt)
end

function Application:Render()
end

function Application:Destroy()
end

function Application:Main()
	self:Initialize()
	self.Timer:Step()

	while not self.Window:IsClosing() do
		self.Timer:Step()
		self.Window:Update(self.Timer:GetDelta())
		local start = self.Timer:GetTime()

		self.Window:PreRender()
		self:Render()
	
		local err = gl.GetError()
		if err ~= GL.NO_ERROR then
			error("GL error: " .. err)
		end

		self.Window:PostRender()

		local diff = self.Timer:GetTime() - start
		self.Timer:Sleep(math.max(0, (1 / self.TargetFPS) - diff))
	end
end

return Application