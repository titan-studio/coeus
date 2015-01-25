local Coeus = (...)
local OOP = Coeus.Utility.OOP 

--[[
Simple use case:
Code:
	local ev = Event:New(true)
	local listener1 = ev:Listen(function(x, e)
		print("listener 1 checking in!",x)
		if x == "round 2" then
			e:Disconnect()
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
	 if you call e:Consume() in listener 2, it won't reach listener 1)
> 	listener 1 checking in!	round 1
	(listener 2 is disposable so it drops out after round 1)
>	listener 1 checking in! round 2
 	(round 3 reaches nothing because listener 1 called e:Disconnect() in round 2)
Any questions? Ask Kyle
]]

local function consume(self)
	self.consumed = true
end
local function disconnect(self)
	self.disconnected = true
end

local Event = OOP:Class() {
	listeners = {},
	use_priority = false
}

function Event:_new(use_priority)
	self.use_priority = use_priority or self.use_priority
end

function Event:Fire(...)
	local args = {...}
	local ev = {}
	ev.Event = self
	ev.consumed = false
	ev.disconnected = false
	ev.Consume = consume
	ev.Disconnect = disconnect
	

	for i = 1, #self.listeners do 
		local v = self.listeners[i]
		if (not v) then
			break
		end

		v.callback(unpack(args))
		if (ev.consumed) then
			break
		end

		if (ev.disconnected or v.disposable) then
			table.remove(self.listeners, i)
		end
		ev.disconnected = false
	end

	return ev.consumed
end

function Event:Listen(func, disposable, priority)
	local listener = {}
	listener.callback = func
	listener.disposable = disposable or false
	listener.priority = priority or 0

	listener.Disconnect = function()
		self:Disconnect(listener)
	end

	self.listeners[#self.listeners + 1] = listener

	if (self.use_priority) then
		self:Sort()
	end

	return listener
end

function Event:Disconnect(listener)
	for i, v in pairs(self.listeners) do
		if (v == listener) then
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
	self.listeners = nil
end

return Event