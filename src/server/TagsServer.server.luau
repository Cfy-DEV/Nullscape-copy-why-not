local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

for _, v in pairs(ReplicatedStorage.Shared.Tags:GetChildren()) do
	if v:IsA("ModuleScript") then
		local req

		task.spawn(function()
			req = require(v)
		end)

		assert(typeof(req) == "table")

		if not req.Server then
			warn(("No server method found in %s tag's module"):format(v.Name))
		end

		task.spawn(function()
			for _, instance in ipairs(CollectionService:GetTagged(v.Name)) do
				req.Server(instance)
			end
		end)

		CollectionService:GetInstanceAddedSignal(v.Name):Connect(function(instance)
			req.Server(instance)
		end)
	end
end
