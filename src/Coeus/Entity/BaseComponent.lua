local Coeus 	= (...)
local OOP		= Coeus.Utility.OOP 
local Table		= Coeus.Utility.Table

local BaseComponent = OOP:Class() {
	entity = false,
}

function BaseComponent:_new()

end

function BaseComponent:SetEntity(entity)
	if self.entity then
		self.entity:RemoveComponent(self)
	end
	entity:AddComponent(self)
end
function BaseComponent:GetEntity()
	return self.entity
end

function BaseComponent:Update(dt)

end

function BaseComponent:Render()

end

return BaseComponent