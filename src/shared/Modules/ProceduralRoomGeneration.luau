local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Chunk = require(ReplicatedStorage.Shared.Classes.Chunk)
local NetModule = require(script.Parent.NetModule)
local roomsFolder = ServerStorage.Rooms

local module = {}

module.Chunk = Chunk.new(Vector3.new(25, 25, 25), false)
module.Cache = NetModule.New("Cache", "Folder", workspace, nil)

if workspace:FindFirstChild("WorldCenter") then
	module.Chunk:SetWorldCenter(workspace.WorldCenter.Position)
end

for _, cloneInstance in pairs(module.Cache.StartingRoom:GetChildren()) do
	if cloneInstance.Name == "Chunk" then
		module.Chunk:AddNode(cloneInstance)
	end
end

module.RoomNodes = {}

local MAX_RETRIES = 3

module.CleanupRoomChunks = function(room: Model)
	local nodes = module.RoomNodes[room]
	if not nodes then
		return
	end

	for _, node in ipairs(nodes) do
		module.Chunk:RemoveNode(node)
	end

	module.RoomNodes[room] = nil
end

local function RetryRoom(room)
	local retries = room:GetAttribute("Retries") or 0

	if retries < MAX_RETRIES then
		room:SetAttribute("Retries", retries + 1)

		local ends = module.GetEnds(room)

		for _, endPart in pairs(ends) do
			task.spawn(function()
				module.NextRoom(endPart)
			end)
		end

		return
	end

	local previousTag = room:FindFirstChild("__Previous")

	if previousTag and previousTag.Value then
		local previousEnd = previousTag.Value

		module.DestroyBranch(room)
		module.CleanupRoomChunks(room)
		room:Destroy()

		task.spawn(function()
			if previousEnd and previousEnd.Parent then
				module.NextRoom(previousEnd)
			end
		end)
	end
end

module.DestroyBranch = function(room: Model, visited)
	visited = visited or {}

	if visited[room] then
		return
	end

	visited[room] = true

	for _, value in pairs(room:GetChildren()) do
		if value.Name == "__Connecting" and value:IsA("ObjectValue") then
			local nextRoom = value.Value

			if nextRoom and nextRoom.Parent == module.Cache then
				module.DestroyBranch(nextRoom, visited)
				module.CleanupRoomChunks(nextRoom)
				nextRoom:Destroy()
			end
		end
	end
end

module.NextRoom = function(PreviousEnd, Door)
	if not PreviousEnd or not PreviousEnd.Parent then
		return nil
	end

	local previousRoom = PreviousEnd.Parent

	if not previousRoom then
		return nil
	end

	if not Door then
		if previousRoom.Parent ~= module.Cache then
			previousRoom.Parent = module.Cache
		end

		local rooms = roomsFolder:GetChildren()

		while #rooms > 0 do
			local index = math.random(1, #rooms)
			local randomRoom: Model = rooms[index]

			table.remove(rooms, index)

			assert(randomRoom:IsA("Model"))

			if randomRoom.Name == previousRoom.Name then
				continue
			end

			local clone = randomRoom:Clone()
			clone.Parent = module.Cache

			local cloneStartPart = clone:FindFirstChild("Start")

			assert(cloneStartPart, "Room must have Start")

			clone.PrimaryPart = cloneStartPart

			clone:SetPrimaryPartCFrame(PreviousEnd.CFrame * CFrame.Angles(0, math.rad(180), 0))

			local blocked = false

			for _, cloneInstance in pairs(clone:GetChildren()) do
				if cloneInstance.Name == "Chunk" then
					local _, exist = module.Chunk:GetChunkAtPosition(cloneInstance.Position)
					if exist then
						blocked = true
					end
				end
			end

			if blocked then
				clone:Destroy()
				continue
			end

			module.RoomNodes[clone] = {}

			for _, cloneInstance in pairs(clone:GetChildren()) do
				if cloneInstance.Name == "Chunk" then
					module.Chunk:AddNode(cloneInstance)
					table.insert(module.RoomNodes[clone], cloneInstance)
				end
			end

			local currentTag = Instance.new("ObjectValue")
			currentTag.Name = "__Connecting"
			currentTag.Parent = previousRoom
			currentTag.Value = clone

			local previousTag = Instance.new("ObjectValue")
			previousTag.Name = "__Previous"
			previousTag.Parent = clone
			previousTag.Value = PreviousEnd

			clone:SetAttribute("Retries", 0)

			return clone
		end
	end

	local rayOrigin = PreviousEnd.Position
	local rayDirection = (PreviousEnd.CFrame * CFrame.Angles(0, math.rad(180), 0)).LookVector
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {
		previousRoom,
	}

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if not raycastResult then
		local door = ReplicatedStorage.Assets.Door:Clone()
		door.Parent = module.Cache
		door:SetPrimaryPartCFrame(PreviousEnd.CFrame * CFrame.Angles(0, math.rad(180), 0))
	end

	return nil
end

module.GetEnds = function(room)
	local Ends = {}

	for _, value in pairs(room:GetChildren()) do
		if string.lower(value.Name) == "end" then
			table.insert(Ends, value)
		end
	end

	return Ends
end

module.NewBranch = function(StartingEnd, MaxDepth, Delay)
	local ends = { StartingEnd }
	local temp = {}
	local branch = {}

	for depth = 1, MaxDepth + 1, 1 do
		for _, endPart in pairs(ends) do
			local nextRoom

			if depth == MaxDepth + 1 then
				nextRoom = module.NextRoom(endPart, true)
			else
				nextRoom = module.NextRoom(endPart, false)
			end

			if nextRoom then
				table.insert(branch, nextRoom)
				local nextEnds = module.GetEnds(nextRoom)

				for _, nextEnd in pairs(nextEnds) do
					table.insert(temp, nextEnd)
				end
			end

			task.wait(Delay or 0)
		end

		table.clear(ends)
		ends = table.clone(temp)
		table.clear(temp)
	end

	return branch
end

return module
