local Coeus = (...)
local ShaderData = Coeus.Graphics.ShaderData

return ShaderData:New(ShaderData.ShaderType.VertexFragment, {
	VertexCode = [[

#version 330
layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord_;
layout(location=2) in vec3 normal_;

uniform mat4 ModelViewProjection;
uniform mat4 Model;

out vec2 texcoord;
out vec3 normal;
out vec2 depth;
out float f_log_z;
out float linear_depth;

void main() {
	gl_Position = ModelViewProjection * vec4(position, 1.0);
	f_log_z = 1.0 + gl_Position.w;
	depth = gl_Position.zw;

	texcoord = texcoord_;
	normal = (Model * vec4(normal_, 0.0)).xyz;
}

	]],
	FragmentCode = [[
	
#version 330

layout(location=0) out vec4 DiffuseColor;
layout(location=1) out vec4 NormalColor;
layout(location=2) out float LinearDepth;

uniform sampler2D ModelTexture;
uniform vec4 ModelColor;
uniform float ZNear;
uniform float ZFar;

in vec2 texcoord;
in vec3 normal;
in vec2 depth;
in float f_log_z;

void main() {
	vec3 norm = normalize(normal);
	norm = norm * 0.5 + 0.5;

	DiffuseColor = ModelColor * texture(ModelTexture, texcoord);
	NormalColor = vec4(norm, 1.0);

	LinearDepth = gl_FragCoord.z;

	float coefficient_half = (2.0 / log2(ZFar + ZNear)) * 0.5;
	gl_FragDepth = log2(f_log_z) * coefficient_half;
}

	]]
})