--[[
	Vector2 Tests

	TODO:
	- Add arithmetic tests when those operators are rewritten
]]

local Coeus = (...)
local Vector2 = Coeus.Math.Vector2

local ran = {16, 48}
local ran2 = {34, 12}
local double_ran = {32, 96}
local half_ran = {8, 24}
local garbage = {"Hello,", "World!"}
local garbage2 = "monkeys"

return {
	Name = "Math.Vector2",

	Tests = {
		{
			"Compare",
			Critical = true,
			function(self, test)
				local v_ran = Vector2:New(unpack(ran))
				local v_ran2 = Vector2:New(unpack(ran2))

				if (not Vector2.Compare(v_ran, v_ran)) then
					return test:Fail("Comparison failed for true case!")
				end

				if (Vector2.Compare(v_ran, v_ran2)) then
					return test:Fail("Comparison failed for false case!")
				end
			end
		},

		{
			"Constructors",
			Critical = true,
			function(self, test)
				local release_ran = Vector2:RELEASE_New(unpack(ran))
				local debug_ran = Vector2:DEBUG_New(unpack(ran))
				local v_garbage = Vector2:DEBUG_New(garbage)
				local v_garbage2 = Vector2:DEBUG_New(garbage2)
				local zero = Vector2:New()
				local ezero = Vector2:New(0, 0)

				if (Coeus:IsError(release_ran)) then
					return test:Fail("Release constructor failed: " .. release_ran.Message)
				end

				if (Coeus:IsError(debug_ran)) then
					return test:fail("Debug constructor failed: " .. debug_ran.Message)
				end

				if (not Vector2.Compare(release_ran, debug_ran)) then
					return test:Fail("Release and debug constructors gave different results!")
				end

				if (not Coeus:IsError(v_garbage) or not Coeus:IsError(v_garbage2)) then
					return test:Fail("Debug constructor succeeded with garbage inputs!")
				end

				if (not Vector2.Compare(zero, ezero)) then
					return test:Fail("Implicit constructor did not equal zero constructor!")
				end
			end
		}
	}
}