local ffi = require("ffi")
local Coeus 		= (...)
local OOP			= Coeus.Utility.OOP

local Texture 		= Coeus.Graphics.Texture
local Mesh			= Coeus.Graphics.Mesh
local Shader		= Coeus.Graphics.Shader

local OpenGL 	= Coeus.Bindings.OpenGL
local gl 	 	= OpenGL.gl
local GL 		= OpenGL.GL

local Framebuffer = OOP:Class() {
	fbo = -1,
	textures = {},
	depth = false,

	shader = false,
	mesh = false,

	GraphicsContext = false,
	width = 0, height = 0,
}
Framebuffer.Format = {
	R8G8B8A8 = GL.RGBA8
}

function Framebuffer:_new(context, width, height, format, num_color_buffers, with_depth)
	self.width = width
	self.height = height
	self.GraphicsContext = context

	num_color_buffers = num_color_buffers or 1

	local fbo = ffi.new("int[1]")
	gl.GenFramebuffers(1, fbo)
	self.fbo = fbo[0]

	local prev_fbo = ffi.new("int[1]")
	gl.GetIntegerv(GL.DRAW_FRAMEBUFFER_BINDING, prev_fbo)
	gl.BindFramebuffer(GL.FRAMEBUFFER, self.fbo)

	self.draw_buffers_data = ffi.new("int[?]", num_color_buffers)
	for i = 0, num_color_buffers do
		local texture = Texture:New(width, height)
		texture:Bind()
		gl.FramebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0 + i, GL.TEXTURE_2D, texture.handle, 0)
		gl.DrawBuffer(GL.COLOR_ATTACHMENT0 + i)

		self.textures[#self.textures + 1] = texture
		self.draw_buffers_data[i] = GL.COLOR_ATTACHMENT0 + i
	end
	
	if with_depth then
		self.depth = Texture:New()
		self.depth:Bind()

		gl.TexImage2D(GL.TEXTURE_2D, 0, GL.DEPTH_COMPONENT, width, height, 0, GL.DEPTH_COMPONENT, GL.UNSIGNED_BYTE, nil)
		gl.FramebufferTexture2D(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.TEXTURE_2D, self.depth.handle, 0)
	end

	gl.BindFramebuffer(GL.FRAMEBUFFER, prev_fbo[0])

	self.shader = Shader:New(self.GraphicsContext, [[
#version 330
layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord_;

out vec2 texcoord;

void main() {
	gl_Position = vec4(position, 1.0);
	texcoord = texcoord_;
}
		]],[[
#version 330

layout(location=0) out vec4 FragColor;

uniform sampler2D FBOTexture;

in vec2 texcoord;

void main() {
	FragColor = texture(FBOTexture, texcoord);
}
	]])

	self.mesh = Mesh:New()
	self.mesh:SetData({
		-1.0, -1.0, 0.0, 	0.0, 0.0,
		 1.0, -1.0, 0.0,	1.0, 0.0,
		-1.0,  1.0, 0.0, 	0.0, 1.0,
		 1.0,  1.0, 0.0,	1.0, 1.0
	}, {
		0, 1, 2,
		2, 1, 3
	}, Mesh.DataFormat.PositionTexCoordInterleaved)
end

function Framebuffer:Bind()
	gl.BindFramebuffer(GL.FRAMEBUFFER, self.fbo)
	gl.DrawBuffers(#self.textures, self.draw_buffers_data)
end

function Framebuffer:Clear()
	gl.Clear(bit.bor(tonumber(GL.COLOR_BUFFER_BIT), tonumber(GL.DEPTH_BUFFER_BIT)))
end

function Framebuffer.Unbind()
	gl.BindFramebuffer(GL.FRAMEBUFFER, 0)
end

function Framebuffer:Render(shader)
	local shader = shader or self.shader

	shader:Use()
	shader:Send("FBOTexture", self.textures[2])
	self.mesh:Render()
end

function Framebuffer:RenderTo(shader)
	shader:Use()
	self.mesh:Render()
end

function Framebuffer:Destroy()
	self.textures = {}
	local fb = ffi.new("int[1]", self.fbo)
	gl.BindFramebuffer(GL.FRAMEBUFFER, 0)
	gl.DeleteFramebuffers(1, fb)
end

return Framebuffer