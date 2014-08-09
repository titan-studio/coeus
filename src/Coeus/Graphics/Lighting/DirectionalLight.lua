local Coeus = (...)
local OOP = Coeus.Utility.OOP

local BaseComponent = Coeus.Entity.BaseComponent
local Shader = Coeus.Graphics.Shader

local DirectionalLight = OOP:Class(BaseComponent) {
	GraphicsContext = false,

	shader = false
}
local VertexShaderSource = [[
#version 330
layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord_;

out vec2 texcoord;

void main() {
	gl_Position = vec4(position, 1.0);
	texcoord = texcoord_;
}
]]
local FragmentShaderSource = [[
#version 330

layout(location=0) out vec4 OutColor;

uniform vec3 EyePosition;
uniform mat4 InverseViewProjection;

uniform sampler2D NormalBuffer;
uniform sampler2D DepthBuffer;

uniform vec3 LightDirection;
uniform vec3 LightColor;

in vec2 texcoord;

void main() {
	vec4 normal = vec4(texture(NormalBuffer, texcoord).xyz, 0.0);
	normal.xyz = normal.xyz * 2.0 - 1.0;

	vec4 light_dir = vec4(LightDirection, 0.0);
	light_dir = normalize(light_dir);

	float cosine = max(dot(light_dir, normal), 0.0);
	float specular = 0.0;

	float depth = texture(DepthBuffer, texcoord).x;
	depth = depth * 2.0 - 1.0;

	//Get the pixel position
	vec3 view_space = vec3(
		texcoord.xy * 2.0 - 1.0,
		depth
	);
	vec4 world_space = InverseViewProjection * vec4(view_space, 1.0);
	world_space.xyz /= world_space.w;
	vec3 to_pixel = normalize(EyePosition - world_space.xyz);
	//this is boned
	
	if (cosine > 0.0) {
		vec3 half_vec = normalize(light_dir.xyz + to_pixel);
		float half_vec_cos = dot(half_vec, to_pixel);
		specular = 1.0 * pow(clamp(half_vec_cos, 0.0, 1.0), 2.0);
	}

	OutColor = vec4(vec3(cosine) * LightColor, specular);
}
]]

function DirectionalLight:_new(context)
	self.GraphicsContext = context
	table.insert(self.GraphicsContext.DirectionalLights, self)
	self.shader = self.GraphicsContext.Shaders.DirectionalLight
	if not self.shader then
		self.shader = Shader:New(self.GraphicsContext, VertexShaderSource, FragmentShaderSource)
		self.GraphicsContext.Shaders.DirectionalLight = self.shader
	end
end

function DirectionalLight:Render(light)
	if not light then return end

	local camera = self.GraphicsContext.ActiveCamera
	if not camera then 
		return 
	end
	local cam_entity = camera:GetEntity()
	if not cam_entity then 
		return 
	end
	local eye_pos = cam_entity:GetRenderTransform():GetTranslation()
	local inv_view_proj = (camera:GetViewTransform() * camera:GetProjectionTransform()):GetInverse()
	local geom_fbo = self.GraphicsContext.GeometryFramebuffer

	self.shader:Use()

	self.shader:Send("EyePosition", eye_pos)
	self.shader:Send("InverseViewProjection", inverse_view_proj)

	self.shader:Send("NormalBuffer", geom_fbo.textures[2])
	self.shader:Send("DepthBuffer", geom_fbo.textures[3])

	self.shader:Send("LightDirection", self.LightDirection)
	self.shader:Send("LightColor", self.LightColor)

	self.GraphicsContext.FullscreenQuad:Render()
end

return DirectionalLight