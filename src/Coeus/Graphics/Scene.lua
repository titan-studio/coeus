local Coeus 		= (...)
local OOP			= Coeus.Utility.OOP

local Scene = OOP:Class() {
	entities = {}
}

function Scene:_new()

end

function Scene:AddEntity(entity)
	for i, v in pairs(self.entities) do
		if v == entity then
			return
		end
	end
	self.entities[#self.entities + 1] = entity
	if entity.scene then
		entity.scene:RemoveEntity(entity)
	end
	entity:SetScene(self)
end
function Scene:RemoveEntity(entity)
	for i, v in pairs(self.entities) do
		if v == entity then
			table.remove(self.entities, i)
			return
		end
	end
end

function Scene:Update(dt)
	for i, v in ipairs(self.entities) do
		v:Update(dt)
	end
end

function Scene:Render()
	for i, v in ipairs(self.entities) do
		v:Render()
	end
end

return Scene