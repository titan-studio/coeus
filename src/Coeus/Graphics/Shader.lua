local Coeus = (...)
local oop = Coeus.Utility.OOP
local GLFW = Coeus.Bindings.GLFW
local OpenGL = Coeus.Bindings.OpenGL
local ffi = require("ffi")

local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL

local Shader = oop:Class() {
	
}

function Shader:_new()
	
end

return Shader