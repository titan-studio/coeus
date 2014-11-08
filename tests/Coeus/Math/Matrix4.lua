local Coeus = (...)
local Matrix4 = Coeus.Math.Matrix4
local Utility = Coeus.Utility.Table

local ran16 = {
	115, 512, 657, 132,
	101, 000, 273, 326,
	051, 943, 746, 444,
	123, 226, 386, 590
}

local ran16_2 = {
	051, 943, 746, 444,
	115, 512, 657, 132,
	123, 226, 386, 590,
	101, 000, 273, 326
}

local ord16 = {
	01, 02, 03, 04,
	05, 06, 07, 08,
	09, 10, 11, 12,
	13, 14, 15, 16
}

local dord16 = {
	02, 04, 06, 08,
	10, 12, 14, 16,
	18, 20, 22, 24,
	26, 28, 30, 32
}

return {
	Name = "Math.Matrix4",

	Tests = {
		{
			"Constructors",
			Critical = true,
			function(self, test)
				local release_ran16 = Matrix4:RELEASE_New(unpack(ran16))
				local debug_ran16 = Matrix4:DEBUG_New(unpack(ran16))
				local uninitialized = Matrix4:New()
				local zero = Matrix4:Filled(0)
				local identity = Matrix4:Identity()

				if (Coeus:IsError(release_ran16)) then
					return test:Fail("Release constructor failed: " .. release_ran16.Message)
				end

				if (Coeus:IsError(debug_ran16)) then
					return test:Fail("Debug constructor failed: " .. debug_ran16.Message)
				end

				if (not Matrix4.Compare(release_ran16, debug_ran16)) then
					return test:Fail("Debug and release constructors gave different results!")
				end

				if (Coeus:IsError(uninitialized)) then
					return test:Fail("Uninitialized constructor failed: " .. uninitialized.Message)
				end

				if (Coeus:IsError(zero)) then
					return test:Fail("Zero constructor failed: " .. zero.Message)
				end

				if (Coeus:IsError(identity)) then
					return test:Fail("Identity constructor failed: " .. identity.Message)
				end
			end
		},

		{
			"Compare",
			Critical = true,
			function(self, test)
				local m_ran16 = Matrix4:New(unpack(ran16))
				local m_ran16_2 = Matrix4:New(unpack(ran16_2))

				if (not Matrix4.Compare(m_ran16, m_ran16)) then
					return test:Fail("Comparison failed for true case!")
				end

				if (Matrix4.Compare(m_ran16, m_ran16_2)) then
					return test:Fail("Comparison failed for false case!")
				end
			end
		},

		{
			"Addition",
			function(self)
				local zero = Matrix4:Filled(0)
				local m_ord16 = Matrix4:New(unpack(ord16))
				local m_dord16 = Matrix4:New(unpack(dord16))
				local m_ran16 = Matrix4:New(unpack(ran16))
				local m_ran16_2 = Matrix4:New(unpack(ran16_2))
				local m_out = Matrix4:New()

				if (not Matrix4.Compare(zero, Matrix4.Add(zero, zero))) then
					return test:Fail("Summed zero matrices did not result in a zero matrix")
				end

				if (not Matrix4.Compare(m_ord16, Matrix4.Add(m_ord16, zero))) then
					return test:Fail("Adding zero matrix to ord16 did not result in ord16")
				end

				if (not Matrix4.Compare(m_dord16, Matrix4.Add(m_ord16, m_ord16))) then
					return test:Fail("Adding matrix to itself did not result in values doubling")
				end

				if (not Matrix4.Compare(Matrix4.Add(m_ran16, m_ran16_2), Matrix4.Add(m_ran16_2, m_ran16))) then
					return test:Fail("Addition was not communative for ran16 and ran16_2")
				end
			end
		}
	}
}