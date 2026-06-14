local module = {}

local chunk = {}
chunk.__index = chunk

function module.new(Size: Vector3)
	local self = setmetatable({}, chunk)

	self.Size = Size
	self.Chunks = {}

	return self
end

local function gridNum(a, b)
	assert(b ~= 0, "B cannot be 0")
	return math.round(a / b) * b
end

local function roundPos(pos: Vector3, size: Vector3)
	assert(typeof(pos) == "Vector3", "Wrong parameter type given")
	assert(typeof(size) == "Vector3", "Wrong parameter type given")
	local x = (size.X == math.huge) and 0 or gridNum(pos.X, size.X)
	local y = (size.Y == math.huge) and 0 or gridNum(pos.Y, size.Y)
	local z = (size.Z == math.huge) and 0 or gridNum(pos.Z, size.Z)
	return Vector3.new(x, y, z)
end

local function crypt(pos: Vector3)
	assert(typeof(pos) == "Vector3", "Wrong parameter type given")
	return ("%sx%sx%s"):format(tostring(math.floor(pos.X)), tostring(math.floor(pos.Y)), tostring(math.floor(pos.Z)))
end

--[[
Returns all the existing chunk IDS within given radius
]]
function chunk:GetChunksInRadius(centerPos: Vector3, radius: number)
	assert(typeof(centerPos) == "Vector3", "Wrong parameter type given")
	assert(typeof(radius) == "number", "Wrong parameter type given")
	local chunks = {}
	local existingChunks = self.Chunks

	local pos = roundPos(centerPos, self.Size)

	local radiusX = math.ceil(radius / self.Size.X) * radius
	local radiusY = math.ceil(radius / self.Size.Y) * radius
	local radiusZ = math.ceil(radius / self.Size.Z) * radius

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
Adds a node (Instance) to the appropriate chunk based on position
]]
function chunk:AddNode(node: Instance)
	assert(typeof(node) == "Instance", "Wrong parameter type given")
    assert(node:IsA("BasePart"), "Node must be a part base")
	local pos = node.Position
	local chunkPos = roundPos(pos, self.Size)
	local chunkKey = crypt(chunkPos)

	if not self.Chunks[chunkKey] then
		self.Chunks[chunkKey] = {}
	end

	table.insert(self.Chunks[chunkKey], node)
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
Returns the chunk data at the given position, or nil if not found
]]
function chunk:GetChunkAtPosition(pos: Vector3)
	assert(typeof(pos) == "Vector3", "Wrong parameter type given")
	local chunkPos = roundPos(pos, self.Size)
	local chunkKey = crypt(chunkPos)
	return self.Chunks[chunkKey]
end

--[[
Returns all parts in the chunk at the given position
]]
function chunk:GetPartsInChunk(pos: Vector3)
	assert(typeof(pos) == "Vector3", "Wrong parameter type given")
	return self:GetChunkAtPosition(pos) or {}
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
function chunk:RemoveNode(node: Instance)
	assert(typeof(node) == "Instance", "Wrong parameter type given")
	assert(node:IsA("BasePart"), "Parameter must be a part base")
	local pos = node.Position
	local chunkPos = roundPos(pos, self.Size)
	local chunkKey = crypt(chunkPos)
	local chunkData = self.Chunks[chunkKey]

	if chunkData then
		local index = table.find(chunkData, node)
		if index then
			table.remove(chunkData, index)
		end
	end
end

return module
