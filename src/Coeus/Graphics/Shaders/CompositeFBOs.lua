local Coeus = (...)
local ShaderData = Coeus.Graphics.ShaderData

return ShaderData:New(ShaderData.ShaderType.VertexFragment, {
	VertexCode = [[

#version 330
layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord_;

out vec2 texcoord;

void main() {
	gl_Position = vec4(position, 1.0);
	texcoord = texcoord_;
}

	]],
	FragmentCode = [[

#version 330

layout(location=0) out vec4 FinalColor;

uniform sampler2D DiffuseBuffer;
uniform sampler2D LightBuffer;

in vec2 texcoord;

void main() {
	vec4 diffuse = texture(DiffuseBuffer, texcoord);
	vec4 light = texture(LightBuffer, texcoord);

	FinalColor = vec4(diffuse.xyz, 1.0);//vec4((diffuse.xyz * light.xyz + light.w), 1.0);
}
	]]
})