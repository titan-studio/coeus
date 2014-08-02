local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local OpenGL		= Coeus.Bindings.OpenGL
local gl = OpenGL.gl
local GL = OpenGL.GL

local Mesh	= Coeus.Graphics.Mesh
local Material		= Coeus.Graphics.Material

local TextRenderer = OOP:Class(Material) {
	context = false,
	text = "",
	font = false,

	width = 0,
	height = 0,

	draws = false
}

function TextRenderer:_new(context)
	self.context = context
	self.Mesh = Mesh:New()

	self.Shader = Coeus.Graphics.Shader:New(context, [[
		#version 330
		layout(location=0) in vec3 position;
		layout(location=1) in vec2 texcoord_;
		layout(location=2) in vec3 normal;

		uniform mat4 ModelViewProjection;

		out vec2 texcoord;

		void main() {
			gl_Position = ModelViewProjection * vec4(position, 1.0);
			texcoord = texcoord_;
		}
		]],[[
		#version 330
		
		layout(location=0) out vec4 FragColor;

		uniform sampler2D FontAtlas;

		in vec2 texcoord;

		void main() {
			float brightness = texture(FontAtlas, texcoord).x;
			//if (brightness == 0) discard;
			FragColor = vec4(vec3(1.0) * brightness, 1.0);
		}
	]])
end

function TextRenderer:RebuildText()
	local text = self.text
	local vertex_data, draws, width, height = self.font:GenerateMesh(text)
	self.Mesh:SetData(vertex_data, nil, Mesh.DataFormat.PositionTexCoordInterleaved)
	self.width = width
	self.height = height

	self.draws = draws
end

function TextRenderer:Use()
	Material.Use(self)
end

function TextRenderer:Render()
	if not self.draws then return end
	gl.BlendFunc(GL.ONE, GL.ONE)
	gl.BindVertexArray(self.Mesh.vao)
	local camera = self.context.ActiveCamera
	local model = self.entity:GetRenderTransform()
	local view_projection = camera:GetViewProjection()
	local mvp = view_projection * model
	
	self.Shader:Use()
	for i, v in ipairs(self.draws) do
		self.Shader:Send("FontAtlas", v.texture)
		self.Shader:Send("ModelViewProjection", mvp)
		gl.DrawArrays(GL.TRIANGLES, v.start, v.count)
	end
	gl.BlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
end

return TextRenderer