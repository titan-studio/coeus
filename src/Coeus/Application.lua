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

	while (glfw.WindowShouldClose(self.Window.handle) == 0) do
		self.Timer:Step()
		self.Window.Mouse:Update(self.Timer:GetDelta())
		local start = self.Timer:GetTime()

		glfw.PollEvents()
		self.Window:Use()

		gl.ClearDepth(1.0)
		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(bit.bor(tonumber(GL.COLOR_BUFFER_BIT), tonumber(GL.DEPTH_BUFFER_BIT)))
		self:Render()
		
		local err = gl.GetError()
		if err ~= GL.NO_ERROR then
			error("GL error: " .. err)
		end

		glfw.SwapBuffers(self.Window.handle)

		local diff = self.Timer:GetTime() - start
		self.Timer:Sleep(math.max(0, (1 / self.TargetFPS) - diff))
	end
	
	self:Destroy()
end

return Application