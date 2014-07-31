local Coeus = (...)
local oop = Coeus.Utility.OOP
local GLFW = Coeus.Bindings.GLFW
local OpenGL = Coeus.Bindings.OpenGL
local ffi = require("ffi")

local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL

local Vector3 = Coeus.Math.Vector3
local Matrix4 = Coeus.Math.Matrix4
local Table = Coeus.Utility.Table

local Texture = Coeus.Graphics.Texture

local Shader = oop:Class() {
	context = false,
	program = false,
	uniforms = {}
}

local function check_item(shader, get, log, status_check)
	local status = ffi.new("int[1]")
	get(shader, status_check, status)
	if status[0] == GL.FALSE then
		local length = ffi.new("int[1]")
		get(shader, GL.INFO_LOG_LENGTH, length)
		local str = ffi.new("char[" .. length[0] .. "]")
		log(shader, length[0], length, str)
		print("Error in shader: " .. ffi.string(str, length[0]))
		return false
	end
	return true
end

local function create_shader(source, type)
	local shader = gl.CreateShader(type)
	local str = ffi.new("const char*[1]")
	str[0] = source
	local len = ffi.new("int[1]")
	len[0] = source:len()
	gl.ShaderSource(shader, 1, str, len)
	gl.CompileShader(shader)

	check_item(shader, gl.GetShaderiv, gl.GetShaderInfoLog, GL.COMPILE_STATUS)
	return shader
end


function Shader:_new(context, vertex_source, fragment_source, geometry_source)
	self.context = context

	local vertex_shader
	if vertex_source then
		vertex_shader = create_shader(vertex_source, GL.VERTEX_SHADER)
	end
	local fragment_shader
	if fragment_source then
		fragment_shader = create_shader(fragment_source, GL.FRAGMENT_SHADER)
	end

	local program
	if vertex_shader and fragment_shader then
		program = gl.CreateProgram()
		gl.AttachShader(program, vertex_shader)
		gl.AttachShader(program, fragment_shader)

		gl.LinkProgram(program)
		check_item(program, gl.GetProgramiv, gl.GetProgramInfoLog, GL.LINK_STATUS)
		self.program = program
	end
end

function Shader:get_uniform(name)
	local uni = self.uniforms[name]
	if not uni then
		local str = ffi.cast('char*', name)
		uni = gl.GetUniformLocation(self.program, str)
		print("location of uniform " .. name .. ": " .. uni)
		self.uniforms[name] = uni
	end
	return uni
end

function Shader:Send(name, ...)
	local uniform = self:get_uniform(name)
	if uniform == -1 then
		--TODO: better error handling here
		error("Couldn't set shader uniform " .. name .. ": location not found (did you forget to use it?)")
	end

	local values = {...}
	local first = values[1]
	if not first then return end
	local size = 1
	if type(first) ~= 'number' then
		if first.GetClass and first:GetClass() == Vector3 then
			--convert the data now...
			local data = ffi.new('float[' .. (3 * #values) .. ']')
			local idx = 0
			for i=1,#values do
				data[idx+0] = values[i].x
				data[idx+1] = values[i].y 
				data[idx+2] = values[i].z
				idx = idx + 3
			end
			return
		end
		if first.GetClass and first:GetClass() == Matrix4 then
			local data = ffi.new('float[' .. (16 * #values) .. ']')
			local idx = 0
			for i=1,#values do
				for j=0,15 do
					data[idx] = values[i].m[j]
					idx = idx + 1
				end
			end
			gl.UniformMatrix4fv(uniform, #values, GL.FALSE, data)
			return
		end
		if first.GetClass and first:GetClass() == Texture then
			local data = ffi.new('int[' .. #values .. ']')
			for i = 1, #values do
				data[i-1] = self.context:BindTexture(values[i])
			end
			gl.Uniform1iv(uniform, #values, data)
			return
		end
		print("Unhandled type of uniform")
		return
	end

	--If a single number...
	local data = ffi.new('float[' .. #values .. ']')
	for i = 1, #values do
		data[i-1] = values[i]
	end
	gl.Uniform1fv(uniform, #values, data)
end

function Shader:SendInt(name, ...)
	--TODO: implement this
end

function Shader:Use()
	gl.UseProgram(self.program)
end

return Shader