local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

for _, v in pairs(ReplicatedStorage.Shared.Tags:GetChildren()) do
	if v:IsA("ModuleScript") then
		local req = require(v)

		assert(typeof(req) == "table")
		
		if not req.Client then 
			warn(("No client method found in %s tag's module"):format(v.Name))
		end

		for _, instance in ipairs(CollectionService:GetTagged(v.Name)) do
			req.Client(instance)
		end

		CollectionService:GetInstanceAddedSignal(v.Name):Connect(function(instance)
			req.Client(instance)
		end)
	end
end