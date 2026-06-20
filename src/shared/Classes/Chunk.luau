local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networking = require(ReplicatedStorage.Shared.Config.Networking)
local Types = require(ReplicatedStorage.Shared.Config.Types)
local module = {}

local chunk = {}
chunk.__index = chunk

function module.new(Size: Vector3): Types.Chunk
	local self = setmetatable({}, chunk)

	self.WorldCenter = Vector3.zero
	self.Size = Size
	self.Chunks = {}

	self.NodeToChunk = {}
	self.NodeIndex = {}

	return self
end

local function roundPos(pos: Vector3, size: Vector3, center: Vector3)
	assert(typeof(pos) == "Vector3")
	assert(typeof(size) == "Vector3")
	assert(typeof(center) == "Vector3")

	local relative = pos - center

	local x = not (size.X == 0)
		and ((size.X == math.huge) and center.X or math.round(relative.X / size.X) * size.X + center.X)

	local y = not (size.Y == 0)
		and ((size.Y == math.huge) and center.Y or math.round(relative.Y / size.Y) * size.Y + center.Y)

	local z = not (size.Z == 0)
		and ((size.Z == math.huge) and center.Z or math.round(relative.Z / size.Z) * size.Z + center.Z)

	return Vector3.new(x, y, z)
end

local function crypt(pos: Vector3)
	assert(typeof(pos) == "Vector3", "Wrong parameter type given")
	return ("%sx%sx%s"):format(tostring(math.floor(pos.X)), tostring(math.floor(pos.Y)), tostring(math.floor(pos.Z)))
end

function module.decrypt(key: string)
	local splitNums = string.split(key, "x")
	assert(#splitNums == 3, ("%s is not a encrypted message."):format(key))
	local result = Vector3.new(tonumber(splitNums[1]), tonumber(splitNums[2]), tonumber(splitNums[3]))
	return result
end

--[[
Destroy every single chunk and rebuild it.
]]
function chunk:RebuildChunks()
	local oldChunks = self.Chunks
	self.Chunks = {}

	for _, partList in pairs(oldChunks) do
		for _, part in ipairs(partList) do
			self:AddNode(part)
		end
	end

	return self.Chunks
end

--[[
Sets the world center to the given position.
]]
function chunk:SetWorldCenter(center: Vector3)
	assert(typeof(center) == "Vector3")

	if center == self.WorldCenter then
		return
	end

	self.WorldCenter = center
	self:RebuildChunks()
end

--[[
Returns all the existing chunk IDS within given radius
]]
function chunk:GetChunksInRadius(centerPos: Vector3, radius: number)
	assert(typeof(centerPos) == "Vector3", "Wrong parameter type given")
	assert(typeof(radius) == "number", "Wrong parameter type given")
	local chunks = {}
	local existingChunks = self.Chunks

	local pos = roundPos(centerPos, self.Size, self.WorldCenter)

	local radiusX = math.ceil(radius / self.Size.X) * self.Size.X
	local radiusY = math.ceil(radius / self.Size.Y) * self.Size.Y
	local radiusZ = math.ceil(radius / self.Size.Z) * self.Size.Z

	-- 🦅 FUCK READIBILITY 🦅

	local loopX = (self.Size.X == math.huge) and { [1] = 0, [2] = 0, [3] = 1 }
		or { [1] = pos.X - radiusX, [2] = pos.X + radiusX, [3] = self.Size.X }
	local loopY = (self.Size.Y == math.huge) and { [1] = 0, [2] = 0, [3] = 1 }
		or { [1] = pos.Y - radiusY, [2] = pos.Y + radiusY, [3] = self.Size.Y }
	local loopZ = (self.Size.Z == math.huge) and { [1] = 0, [2] = 0, [3] = 1 }
		or { [1] = pos.Z - radiusZ, [2] = pos.Z + radiusZ, [3] = self.Size.Z }

	for x = loopX[1], loopX[2], loopX[3] do
		for y = loopY[1], loopY[2], loopY[3] do
			for z = loopZ[1], loopZ[2], loopZ[3] do
				local chunkKey = crypt(Vector3.new(x, y, z))
				if existingChunks[chunkKey] then
					table.insert(chunks, chunkKey)
				end
			end
		end
	end

	return chunks
end

--[[
Adds a node (Instance) to the appropriate chunk based on 
vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
Please notice that it DOES NOT support moving parts!!!
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
]]
function chunk:AddNode(node: BasePart)
	local pos = node.Position
	local chunkPos = roundPos(pos, self.Size, self.WorldCenter)
	local chunkKey = crypt(chunkPos)

	if not self.Chunks[chunkKey] then
		self.Chunks[chunkKey] = {}
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Block
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(0, 255, 0)
		part.Transparency = 0.75
		part.CanCollide = false
		part.Anchored = true
		part.CanTouch = false
		part.CanQuery = false
		part.Parent = Networking.ScriptJunk
		part.Position = pos
		part.Size = self.Size
	end

	local chunkData = self.Chunks[chunkKey]

	table.insert(chunkData, node)

	self.NodeToChunk[node] = chunkKey
	self.NodeIndex[node] = #chunkData

	return chunkKey
end

--[[
Returns all parts within a radius around the given position
]]
function chunk:GetPartsInRadius(pos: Vector3, radius: number)
	assert(typeof(pos) == "Vector3", "Wrong parameter type given")
	assert(typeof(radius) == "number", "Wrong parameter type given")
	local parts = {}
	local chunkKeys = self:GetChunksInRadius(pos, radius)

	for _, key in ipairs(chunkKeys) do
		for _, part in ipairs(self.Chunks[key]) do
			table.insert(parts, part)
		end
	end

	return parts
end

--[[
Returns all parts stored in all chunks
]]
function chunk:GetAllParts()
	local parts = {}
	for _, chunkParts in pairs(self.Chunks) do
		for _, part in ipairs(chunkParts) do
			table.insert(parts, part)
		end
	end
	return parts
end

--[[
Returns the chunk key of a certain position, and also return if it exists
]]
function chunk:GetChunkAtPosition(pos: Vector3)
	assert(typeof(pos) == "Vector3", "Wrong parameter type given")
	local chunkPos = roundPos(pos, self.Size, self.WorldCenter)
	local chunkKey = crypt(chunkPos)
	local find = self.Chunks[chunkKey]
	return chunkKey, find ~= nil
end

--[[
Returns all parts in the chunk at the given position
]]
function chunk:GetPartsInChunk(key)
	local chunks = self.Chunks
	local find = chunks[key]
	return find
end

--[[
Cleans up all chunks and removes metatable
]]
function chunk:Destroy()
	self:Cleanup()
	setmetatable(self, nil)
end

--[[
Removes all chunks from the data structure
]]
function chunk:Cleanup()
	table.clear(self.Chunks)
end

--[[
Removes a node (Instance) from the appropriate chunk based on position
]]
function chunk:RemoveNode(node: BasePart)
	local chunkKey = self.NodeToChunk[node]

	if not chunkKey then
		return
	end

	local chunkData = self.Chunks[chunkKey]

	if not chunkData then
		return
	end

	local index = self.NodeIndex[node]
	local lastIndex = #chunkData
	local lastNode = chunkData[lastIndex]

	chunkData[index] = lastNode
	chunkData[lastIndex] = nil

	if lastNode ~= node then
		self.NodeIndex[lastNode] = index
	end

	self.NodeToChunk[node] = nil
	self.NodeIndex[node] = nil

	if #chunkData == 0 then
		self.Chunks[chunkKey] = nil
	end
end

return module
