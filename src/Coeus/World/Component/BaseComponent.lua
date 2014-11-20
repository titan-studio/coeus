local C = (...)
local Coeus = C:Get("Coeus")
local OOP = Coeus.Utility.OOP

local BaseComponent = OOP:Class() {
	ClassName = "BaseComponent",
	RenderLayerFlag = Coeus.Graphics.Layer.Flag.None,
	Actor = false,

	ShouldUpdate = true,

	AddedToActor = Coeus.Utility.Event:New()
}

function BaseComponent:_new()

end

function BaseComponent:Update(dt)

end

function BaseComponent:Copy()
	local actor = self.Actor
	self.Actor = false
	local copy = OOP.Object.Copy(self)
	self.Actor = actor
	return copy
end


return BaseComponent