local Coeus = (...)
local OOP = Coeus.Utility.OOP

local BaseComponent = Coeus.Entity.BaseComponent
local Shader = Coeus.Graphics.Shader
local Vector3 = Coeus.Math.Vector3

local PointLight = OOP:Class(BaseComponent) {
	GraphicsContext = false,

	shader = false,

	LightRadius = 5,
	LightColor = Vector3:New(1.0, 1.0, 1.0),
	LightIntensity = 10.0,
}
local VertexShaderSource = [[
#version 330
layout(location=0) in vec3 position;

uniform mat4 ModelViewProjection;

//out vec4 ScreenPosition;

void main() {
	gl_Position = ModelViewProjection * vec4(position, 1.0);
	//ScreenPosition = gl_Position;
}
]]
local FragmentShaderSource = [[
#version 330

layout(location=0) out vec4 OutColor;

//in vec4 ScreenPosition;

uniform vec3 EyePosition;
uniform mat4 InverseViewProjection;
uniform mat4 proj;
uniform mat4 view;

uniform sampler2D NormalBuffer;
uniform sampler2D DepthBuffer;
uniform sampler2D WorldBuffer;
uniform vec3 ScreenSize;

uniform vec3 LightPosition;
uniform float LightRadius;
uniform vec3 LightColor;
uniform float LightIntensity;

void main() {
	vec2 texcoord = gl_FragCoord.xy / ScreenSize.xy;
	vec4 normal = texture(NormalBuffer, texcoord);
	normal.xyz = normalize(normal.xyz * 2.0 - 1.0);

	//Get the depth value for this pixel
	float depth = texture(DepthBuffer, texcoord).x;
	depth = depth * 2.0 - 1.0;

	//Get the pixel position
	vec3 view_space = vec3(
		texcoord.xy * 2.0 - 1.0,
		depth
	);
	vec4 world_space = InverseViewProjection * vec4(view_space, 1.0);
	world_space.xyz /= world_space.w;

	//Calculate the vector to the light from the pixel
	vec3 light_vec = LightPosition - world_space.xyz;

	//Then calculate attenuation...
	float radius = LightRadius * 1.0;
	float attenuation = 1.0 - pow((clamp(length(light_vec), 0.0, radius)/radius), 2.0);

	//Normalize the light vector, we don't need its magnitude anymore
	light_vec = normalize(light_vec);

	//Specular calculations
	float cosine = clamp(dot(normal.xyz, light_vec), 0.0, 1.0);
	vec3 diffuse = cosine * LightColor;
	vec3 reflection = normalize(reflect(-light_vec, normal.xyz));
	vec3 to_camera = normalize(EyePosition - world_space.xyz);

	float specular = 0.2 * pow(clamp(dot(reflection, to_camera), 0.0, 1.0), 256.0);

	OutColor = LightIntensity * attenuation * vec4(diffuse, specular);
}
]]

function PointLight:_new(context)
	self.GraphicsContext = context
	table.insert(self.GraphicsContext.PointLights, self)
	self.shader = self.GraphicsContext.Shaders.PointLight
	if not self.shader then
		self.shader = Shader:New(self.GraphicsContext, VertexShaderSource, FragmentShaderSource)
		self.GraphicsContext.Shaders.PointLight = self.shader
	end
end

function PointLight:Render(light)
	if not light then return end

	local camera = self.GraphicsContext.ActiveCamera
	if not camera then 
		return 
	end
	local cam_entity = camera:GetEntity()
	if not cam_entity then 
		return 
	end
	
	local geom_fbo = self.GraphicsContext.GeometryFramebuffer

	

	local model = self.entity:GetRenderTransform()
	local view = camera:GetViewTransform()
	local proj = camera:GetProjectionTransform()
	local mvp = proj * view * model
	local inv_view_proj = (proj * view):GetInverse()

	local eye_pos = cam_entity:GetRenderTransform():GetTranslation()
	local light_pos = self.entity:GetRenderTransform():GetTranslation()

	if (eye_pos - light_pos):LengthSquared() < (self.LightRadius*1.1) ^ 2 then
		self.entity:SetScale(-self.LightRadius, -self.LightRadius, -self.LightRadius)
	else
		self.entity:SetScale(self.LightRadius, self.LightRadius, self.LightRadius)
	end

	self.shader:Use()

	self.shader:Send("ModelViewProjection", mvp)

	self.shader:Send("EyePosition", eye_pos)
	self.shader:Send("InverseViewProjection", inv_view_proj)

	self.shader:Send("NormalBuffer", geom_fbo.textures[2])
	self.shader:Send("DepthBuffer", geom_fbo.depth)

	local w,h = self.GraphicsContext.Window:GetSize()
	self.shader:Send("ScreenSize", Vector3:New(w, h, 0))

	self.shader:Send("LightPosition", light_pos)
	self.shader:Send("LightRadius", self.LightRadius)
	self.shader:Send("LightColor", self.LightColor)
	self.shader:Send("LightIntensity", self.LightIntensity)

	self.GraphicsContext.UnitSphere:Render()
end

return PointLight