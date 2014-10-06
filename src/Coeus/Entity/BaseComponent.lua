local Coeus 	= (...)
local OOP		= Coeus.Utility.OOP 
local Table		= Coeus.Utility.Table
local Event		= Coeus.Utility.Event

local BaseComponent = OOP:Class() {
	entity = false,
	layer_flag = Coeus.Graphics.Layer.Flag.None,

	AddedToEntity = Event:New(),
	RemovedFromEntity = Event:New()
}

function BaseComponent:_new()

end

function BaseComponent:SetEntity(entity)
	if self.entity then
		self.entity:RemoveComponent(self)
		self.RemovedFromEntity:Fire(self, entity)
	end
	entity:AddComponent(self)
	self.AddedToEntity:Fire(self, entity)
end
function BaseComponent:GetEntity()
	return self.entity
end

function BaseComponent:Update(dt)

end

function BaseComponent:Render()

end

function BaseComponent:RenderLight()

end

return BaseComponent