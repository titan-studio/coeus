--[[
	IQM Loader (stub)

	Loads IQM models (.iqm)
]]

local Coeus = (...)
local ffi = require("ffi")

local OOP = Coeus.Utility.OOP
local ModelData = Coeus.Asset.Model.ModelData
local MeshData = Coeus.Asset.Model.MeshData

local IQM = OOP:Static(Coeus.Asset.Format)()

function IQM:Load(filename)

end

function IQM:Match(filename)
	return not not filename:match("%.iqm$")
end

return IQM