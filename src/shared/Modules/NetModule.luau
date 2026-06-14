local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Trove = require(ReplicatedStorage.Packages.Trove)
local module = {}

module.CreateTag = function(Object: Instance)
	local trove = Trove.new()

	trove:Add(Object.Destroying:Connect(function(...)
		trove:Clean()
		trove:Destroy()
	end))

	local tag = Instance.new("ObjectValue", script)
	tag.Name = Object.Name

	trove:Add(tag)

	tag.Value = Object
end

function module.New(Name, Class, Parent, Properties)
	if RunService:IsServer() then
		local find = script:FindFirstChild(Name)

		if find then
			return find.Value
		end

		local find2 = Parent:FindFirstChild(Name)

		if find2 then
			module.CreateTag(find2)
			return find2
		end

		local exist, result = pcall(function(...)
			return Instance.new(Class)
		end)

		assert(exist, "Given Class does not exist | " .. Class)

		result.Name = Name
		result.Parent = Parent

		module.CreateTag(result)

		if Properties then
			for property, value in pairs(Properties) do
				local success = pcall(function()
					result[property] = value
				end)

				if not success then
					warn(("Invalid property %s for %s"):format(property, Class))
				end
			end
		end

		return result
	elseif RunService:IsClient() then
		local find = script:WaitForChild(Name)

		assert(find, "Value wasnt created by the server")

		return find.Value
	end

	return
end

return module