local Coeus = (...)
local oop = Coeus.Utility.OOP
local GLFW = Coeus.Bindings.GLFW
local OpenGL = Coeus.Bindings.OpenGL
local ffi = require("ffi")

local glfw = GLFW.glfw
local GLFW = GLFW.GLFW

local gl = OpenGL.gl
local GL = OpenGL.GL

local Mesh = oop:Class() {
	vbo = -1,
	ibo = -1,
	vao = -1,

	num_vertices = 0,
	num_indices = 0
}

Mesh.DataFormat = {
	Position 						= 0,
	PositionTexCoordInterleaved		= 1
}

function Mesh:_new()
	local vao, vbo = ffi.new('int[1]'), ffi.new('int[1]')
	gl.GenVertexArrays(1, vao); vao = vao[0]
	gl.BindVertexArray(vao)
	self.vao = vao

	gl.GenBuffers(1, vbo); vbo = vbo[0]
	gl.BindBuffer(GL.ARRAY_BUFFER, vbo)
	self.vbo = vbo

	
end

function Mesh:SetData(vertices, indices, format)
	self.num_vertices = vertices

	gl.BindVertexArray(self.vao)

	if format == Mesh.DataFormat.Position then
		gl.EnableVertexAttribArray(0)
		gl.VertexAttribPointer(0, 3, GL.FLOAT, GL.FALSE, 3 * 4, ffi.cast('void *', 0))
	elseif format == Mesh.DataFormat.PositionTexCoordInterleaved then
		gl.EnableVertexAttribArray(0)
		gl.VertexAttribPointer(0, 3, GL.FLOAT, GL.FALSE, 5 * 4, ffi.cast('void *', 0))
		gl.EnableVertexAttribArray(1)
		gl.VertexAttribPointer(1, 2, GL.FLOAT, GL.FALSE, 5 * 4, ffi.cast('void *', 3 * 4))
	end

	local data = ffi.new('float['..#vertices..']')
	for i=1,#vertices do
		data[i-1] = vertices[i]
	end
	gl.BufferData(GL.ARRAY_BUFFER, 4 * #vertices, data, GL.STATIC_DRAW)

	if indices then
		self.num_indices = #indices
		local ibo = ffi.new('int[1]')
		gl.GenBuffers(1, ibo); ibo = ibo[0]
		gl.BindBuffer(GL.ELEMENT_ARRAY_BUFFER, ibo)
		self.ibo = ibo

		data = ffi.new('int[' .. #indices .. ']')
		for i=1,#indices do
			data[i-1] = indices[i]
		end
		gl.BufferData(GL.ELEMENT_ARRAY_BUFFER, 4 * #indices, data, GL.STATIC_DRAW)
	end
end

function Mesh:Render()
	gl.BindVertexArray(self.vao)
	if self.ibo ~= -1 then
		gl.DrawElements(GL.TRIANGLES, self.num_indices, GL.UNSIGNED_INT, nil)
	else
		gl.DrawArrays(GL.TRIANGLES, 0, self.num_vertices)
	end
end

function Mesh:Destroy()
	local buf = ffi.new('int[1]')
	buf[0] = self.vbo
	gl.DeleteBuffers(1, buf)
	buf[0] = self.ibo
	gl.DeleteBuffers(1, buf)
	gl.DeleteVertexArrays(self.vao)
end

return Mesh