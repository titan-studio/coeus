local Coeus = (...)
local ShaderData = Coeus.Graphics.ShaderData

return ShaderData:New(ShaderData.ShaderType.VertexFragment, {
	VertexCode = [[

#version 330
layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord_;

out vec2 texcoord;

uniform mat4 ModelProjection;

void main() {
	gl_Position = ModelProjection * vec4(position, 1.0);
	texcoord = texcoord_;
}

	]], 
	FragmentCode = [[

#version 330

uniform sampler2D Texture;
uniform vec4 DiffuseColor;

in vec2 texcoord;

layout(location=0) out vec4 FinalColor;

void main() {
	FinalColor = texture(Texture, texcoord) * DiffuseColor;
}

	]]
})