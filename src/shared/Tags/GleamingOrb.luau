local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Octree = require(ReplicatedStorage.Packages["octo-tree"])
local Networking = require(ReplicatedStorage.Shared.Config.Networking)

local serverOrbTree = Octree.new()
local serverOrbNodes = {}

local clientOrbTree = Octree.new()
local clientOrbNodes = {}

local clientOrbs = {}

if RunService:IsServer() then
	RunService.Heartbeat:Connect(function(delta: number)
		for _, player: Player in pairs(Players:GetPlayers()) do
			local char = player.Character

			if not char then
				continue
			end

			local root = char:FindFirstChild("HumanoidRootPart")

			if not root then
				continue
			end

			local nearby = serverOrbTree:SearchRadius(root.Position, 5)

			for _, node in ipairs(nearby) do
				print("Nearby!")
				local orb = node.Object

				orb:Destroy()

				Networking.OrbCollected:FireDeferred(player, orb)
			end
		end
	end)
end

if RunService:IsClient() then
	local localPlayerModule = require(ReplicatedStorage.Shared.Modules.LocalPlayer)

	local renderDistance = localPlayerModule:GetEstimatedRenderDistance()

	local userSettings = UserSettings()
	local gameSettings = userSettings.GameSettings

	gameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(function()
		renderDistance = localPlayerModule:GetEstimatedRenderDistance()
	end)

	RunService.RenderStepped:Connect(function(delta: number)
		local lp = Players.LocalPlayer
		local char = lp.Character

		if not char then
			return
		end

		local root = char:FindFirstChild("HumanoidRootPart")

		if not root then
			return
		end

		local nearby = clientOrbTree:SearchRadius(root.Position, renderDistance)

		local visible = {}

		for _, node in ipairs(nearby) do
			local part = node.Object

			visible[part] = true

			local orbData = clientOrbs[part]

			if orbData and not orbData.Visible then
				orbData.Visible = true
				orbData.Model.Parent = workspace
			end
		end

		for part, orbData in pairs(clientOrbs) do
			if visible[part] then
				continue
			end

			if orbData.Visible then
				orbData.Visible = false
				orbData.Model.Parent = nil
			end
		end
	end)
end

local module = {

	Server = function(part)
		print("Created")
		local node = serverOrbTree:CreateNode(part.Position, part)

		serverOrbNodes[part] = node

		part.Destroying:Connect(function()
			local currentNode = serverOrbNodes[part]

			if currentNode then
				serverOrbTree:RemoveNode(currentNode)

				serverOrbNodes[part] = nil
			end
		end)
	end,

	Client = function(part: BasePart)
		local orbTrove = Trove.new()

		local gleamOrbModel = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("GleamOrb")

		assert(gleamOrbModel, "GleamOrb model was not found")

		local clone = gleamOrbModel:Clone()

		clone.Parent = nil
		clone.Position = part.Position
		clientOrbs[part] = {
			Model = clone,
			Visible = false,
		}

		CollectionService:AddTag(clone, "RandomlySpinningPart")

		local node = clientOrbTree:CreateNode(part.Position, part)

		clientOrbNodes[part] = node

		part.Destroying:Connect(function()
			local currentNode = clientOrbNodes[part]

			if currentNode then
				clientOrbTree:RemoveNode(currentNode)

				clientOrbNodes[part] = nil
			end

			clientOrbs[part] = nil
			orbTrove:Destroy()
			clone:Destroy()
		end)
		
	end,
}

return module
