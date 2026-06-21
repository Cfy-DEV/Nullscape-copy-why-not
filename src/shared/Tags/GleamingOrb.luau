local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = require(ReplicatedStorage.Packages.Net)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Octree = require(ReplicatedStorage.Packages["octo-tree"])
local Chunk = require(ReplicatedStorage.Shared.Classes.Chunk)
local Networking = require(ReplicatedStorage.Shared.Config.Networking)

local gleamOrbModel = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("GleamOrb")

local clientOrbTree = Octree.new()
local serverChunk = Chunk.new(Vector3.new(12.5, 12.5, 12.5))

if workspace:FindFirstChild("WorldCenter") then
	serverChunk:SetWorldCenter(workspace.WorldCenter.Position)
end

local serverNodes = {}
local clientOrbs = {}

task.spawn(function()
	if RunService:IsServer() then
		local pickupRadius = 3

		while task.wait(0.05) do
			for _, player: Player in pairs(Players:GetPlayers()) do
				local char = player.Character
				if not char then
					continue
				end
				local hrs: BasePart = char:FindFirstChild("HumanoidRootPart")
				if not hrs then
					continue
				end

				local pos = hrs.Position
				local neighboorChunks = serverChunk:GetPartsInRadius(pos, 25)

				for _, part: BasePart in pairs(neighboorChunks) do
					if (pos - part.Position).Magnitude <= pickupRadius then
						serverChunk:RemoveNode(part)
						serverNodes[part] = nil
						part:Destroy()
						Networking.OrbCollected:Fire(player)
					end
				end
			end
		end
	end

	if RunService:IsClient() then
		local localPlayerModule = require(ReplicatedStorage.Shared.Modules.LocalPlayer)

		local renderDistance = localPlayerModule:GetEstimatedRenderDistance()

		local userSettings = UserSettings()
		local gameSettings = userSettings.GameSettings

		gameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(function()
			renderDistance = localPlayerModule:GetEstimatedRenderDistance()
		end)

		while task.wait(2) do
			local lp = Players.LocalPlayer
			local char = lp.Character

			if not char then
				continue
			end

			local root = char:FindFirstChild("HumanoidRootPart")

			if not root then
				continue
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
		end
	end
end)

local module = {

	Server = function(part)
		if serverNodes[part] then
			return
		end

		local key = serverChunk:AddNode(part)

		serverNodes[part] = key
	end,

	Client = function(part: BasePart)
		if clientOrbs[part] then
			return
		end

		assert(gleamOrbModel, "GleamOrb model was not found")

		local clone = gleamOrbModel:Clone()

		clone.Parent = Networking.ScriptJunk
		clone.Position = part.Position
		clientOrbs[part] = {
			Model = clone,
			Visible = false,
		}

		CollectionService:AddTag(clone, "Rainbow")
		CollectionService:AddTag(clone, "BlockySpin")

		local node = clientOrbTree:CreateNode(part.Position, part)
		local destroyed = false

		part.Destroying:Connect(function()
			if destroyed then
				return
			end
			destroyed = true
			clientOrbs[part] = nil
			clone:Destroy()
			clientOrbTree:RemoveNode(node)
		end)
	end,
}

return module
