local C = (...)
local Coeus = C:Get("Coeus")
local OOP = Coeus.Utility.OOP

local Actor = Coeus.World.Actor

local Rectangle2D = OOP:Class(Actor) {
	ClassName = "Rectangle2D"	
}

function Rectangle2D:_new(scene, position, rotation, scale, offset)
	Actor._new(self, scene)

	local root_trans = Coeus.World.Component.Transform2D:New(position, rotation, scale, offset)
	self:AddComponent(root_trans)

	local quad = Coeus.Graphics.QuadRenderer:New()
	self:AddComponent(quad)
end

function Rectangle2D:SetColorRGBA(r, g, b, a)
	self.Components.QuadRenderer.Color = {r, g, b, a}
end

function Rectangle2D:GetColorRGBA()
	local tab = self.Components.QuadRenderer.Color
	return tab[1], tab[2], tab[3], tab[4]
end

return Rectangle2D