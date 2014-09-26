local Coeus 	= (...)
local oop		= Coeus.Utility.OOP 

--[[
Simple use case:

Code:
	local ev = Event:New(true)

	local listener1 = ev:Listen(function(x, consume, disconnect)
		print("listener 1 checking in!",x)
		if x == "round 2" then
			disconnect()
		end
	end, false, 2)
	local listener2 = ev:Listen(function(x)
		print("listener 2 checking in!",x)
	end, true, 1)

	ev:Fire("round 1")
	ev:Fire("round 2")
	ev:Fire("round 3")

Output:
>	listener 2 checking in!	round 1
	(listener 2 comes first because it had the lower priority number
	 if you call consume() in listener 2, it won't reach listener 1)
> 	listener 1 checking in!	round 1
	(listener 2 is disposable so it drops out after round 1)
>	listener 1 checking in! round 2
 	(round 3 reaches nothing because listener 1 called disconnect() in round 2)

Any questions? Ask Kyle
]]

local Event = oop:Class() {
	listeners = {},
	use_priority = false
}

function Event:_new(use_priority)
	self.use_priority = use_priority or self.use_priority
end

function Event:Fire(...)
	local args = {...}
	local consumed = false
	local disconnected = false
	args[#args+1] = function() consumed = true end
	args[#args+1] = function() disconnected = true end

	for i=1,#self.listeners do 
		local v = self.listeners[i]
		if v == nil then break end --the disconnections might cause nil values at the end

		local callback = v.callback
		callback(unpack(args))
		if consume then
			break
		end
		if disconnected or v.disposable then
			table.remove(self.listeners, i)
		end
		disconnected = false
	end
	return consumed
end

function Event:Listen(func, disposable, priority)
	local listener = {}
	listener.callback = func
	listener.disposable = disposable or false
	listener.priority = priority or 0
	listener.Disconnect = function()
		self:Disconnect(listener)
	end
	self.listeners[#self.listeners+1] = listener
	if self.use_priority then
		self:Sort()
	end
	return listener
end

function Event:Disconnect(listener)
	for i,v in pairs(self.listeners) do
		if v == listener then
			table.remove(self.listeners, i)
			return
		end
	end
end

function Event:Sort()
	table.sort(self.listeners, function(a,b)
		return a.priority < b.priority
	end)
end

function Event:Destroy()
	--free the listeners
	self.listeners = {}
end

return Event