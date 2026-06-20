local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = require(ReplicatedStorage.Packages.Net)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Octree = require(ReplicatedStorage.Packages["octo-tree"])
local Chunk = require(ReplicatedStorage.Shared.Classes.Chunk)
local Networking = require(ReplicatedStorage.Shared.Config.Networking)

local clientOrbTree = Octree.new()
local serverChunk = Chunk.new(Vector3.new(125, 125, 125))

local serverOrbTrees = {}
local serverNodes = {}
local clientOrbs = {}

if RunService:IsServer() then
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

			local chunkKey = serverChunk:GetChunkAtPosition(pos)
			local octree = serverOrbTrees[chunkKey]

			if octree then
				local nearby = octree:SearchRadius(pos, 3)

				for _, orb in pairs(nearby) do
					local part = orb.Object
					local currentOctree = serverOrbTrees[chunkKey]
					if currentOctree then
						currentOctree:RemoveNode(orb)
						part:Destroy()
						Networking.OrbCollected:Fire(player)
					end
					serverNodes[part] = nil
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

	while task.wait(1) do
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
	end
end

local module = {

	Server = function(part)
		if serverNodes[part] then
			return
		end

		local chunkKey = serverChunk:AddNode(part)

		if not serverOrbTrees[chunkKey] then
			serverOrbTrees[chunkKey] = Octree.new()
		end

		local node = serverOrbTrees[chunkKey]:CreateNode(part.Position, part)
		serverNodes[part] = node
	end,

	Client = function(part: BasePart)
		local gleamOrbModel = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("GleamOrb")

		assert(gleamOrbModel, "GleamOrb model was not found")

		local clone = gleamOrbModel:Clone()

		clone.Parent = nil	
		clone.Position = part.Position
		clientOrbs[part] = {
			Model = clone,
			Visible = false,
		}

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
