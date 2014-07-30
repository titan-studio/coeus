local Coeus			= (...)
local OOP			= Coeus.Utility.OOP

local next_priority = 1
local RenderPass = OOP:Class() {
	name = "Default Pass",
	pass_tag = false,
	priority = 1,

	entities = {}
}
RenderPass.PassTag = {
	Default 		= 1,
	Transparent 	= 2,
	HUD				= 3
}

function RenderPass:_new(name, tag, priority)
	self.name = name
	self.pass_tag = tag or RenderPass.PassTag.Default
	self.priority = priority or next_priority
	next_priority = next_priority + 1
end

function RenderPass:AddEntity(entity)
	for i, v in pairs(self.entities) do
		if v == entity then
			return
		end
	end

	self.entities[#self.entities + 1] = entity
end
function RenderPass:RemoveEntity(entity)
	for i, v in pairs(self.entities) do
		if v == entity then
			table.remove(self.entities, i)
			return
		end
	end
end

function RenderPass:Render()
	for i,v in pairs(self.entities) do
		v:Render()
	end
end

return RenderPass