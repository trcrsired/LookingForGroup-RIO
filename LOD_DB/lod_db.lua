local _, ns = ...

local RIO = RaiderIO
if RIO then
	local exposed_rio_ns =  RIO.exposed_rio_ns
	if exposed_rio_ns == nil then
		RIO.exposed_rio_ns = ns
	end
end
