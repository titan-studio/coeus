local Coeus = (...)
local OOP = Coeus.Utility.OOP
local bit = require('bit')

local floor = math.floor
local xor = bit.bxor
local band = bit.band
local function normalize(num)
	return num % 0x80000000
end

local Random = OOP:Class() {
	index = 0,
	state = {},

}

function Random:_new(seed)
	self:SetSeed(seed)
end

function Random:SetSeed(seed)
	self.state[0] = seed or normalize(os.time())
	for i = 1, 623 do
		self.state[i] = normalize(0x6c078965 * xor(self.state[i - 1], floor(self.state[i - 1] / 0x40000000)) + i)
	end
end

function Random:Get(lower, upper)
	local y
	if self.index == 0 then
		for i = 0, 623 do
			y = self.state[(i + 1) % 624] % 0x80000000
			self.state[i] = xor(self.state[(i + 397) % 624], floor(y / 2))

			if y % 2 ~= 0 then
				self.state[i] = xor(self.state[i], 0x9908b0df)
			end
		end
	end

	y = self.state[self.index]
	y = xor(y, floor(y / 0x800))
	y = xor(y, band(normalize(y * 0x80), 0x9d2c5680))
	y = xor(y, band(normalize(y * 0x8000), 0xefc60000))
	y = xor(y, floor(y / 0x40000))
	self.index = (self.index + 1) % 624

	if not lower then
		return y / 0x80000000
	elseif not upper then
		if lower == 0 then
			return y
		else
			return 1 + (y % lower)
		end
	else
		return lower + (y % (upper - lower + 1))
	end
end

return Random