local ffi = require("ffi")
local Coeus 		= (...)
local OOP			= Coeus.Utility.OOP

local Texture 		= Coeus.Graphics.Texture
local ImageData 	= Coeus.Asset.Image.ImageData
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

function Framebuffer:_new(context, width, height, formats, with_depth, with_stencil)
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

	self.draw_buffers_data = ffi.new("int[?]", #formats)
	for i = 0, #formats - 1 do
		local image_data = ImageData:New()
		image_data.image = nil
		image_data.Width = width
		image_data.Height = height
		image_data.format = formats[i+1]


		local texture = Texture:New(image_data)
		gl.FramebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0 + i, GL.TEXTURE_2D, texture.handle, 0)
		gl.DrawBuffer(GL.COLOR_ATTACHMENT0 + i)

		self.textures[#self.textures + 1] = texture
		self.draw_buffers_data[i] = GL.COLOR_ATTACHMENT0 + i
	end

	if with_depth then
		local image_data = ImageData:New()
		image_data.image = nil
		image_data.Width = width
		image_data.Height = height
		if with_stencil == true then
			image_data.format = ImageData.Format.DepthStencil
		else
			image_data.format = ImageData.Format.Depth
		end

		self.depth = Texture:New(image_data)

		if with_stencil == true then
			gl.FramebufferTexture2D(GL.FRAMEBUFFER, GL.DEPTH_STENCIL_ATTACHMENT, GL.TEXTURE_2D, self.depth.handle, 0)
		else
			gl.FramebufferTexture2D(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.TEXTURE_2D, self.depth.handle, 0)
		end
	end

	gl.BindFramebuffer(GL.FRAMEBUFFER, prev_fbo[0])
	local status = gl.CheckFramebufferStatus(GL.FRAMEBUFFER)
	--print("status: " .. status)

	self.shader = self.GraphicsContext.Shaders.FramebufferRender
	if not self.shader then
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
		self.GraphicsContext.Shaders.FramebufferRender = self.shader
	end
	self.mesh = self.GraphicsContext.FullscreenQuad
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
	shader:Send("FBOTexture", self.textures[1])
	self.mesh:Render()
end

function Framebuffer:Destroy()
	self.textures = {}
	local fb = ffi.new("int[1]", self.fbo)
	gl.BindFramebuffer(GL.FRAMEBUFFER, 0)
	gl.DeleteFramebuffers(1, fb)
end

return Framebuffer