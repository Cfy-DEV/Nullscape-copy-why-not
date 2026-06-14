local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local NetModule = require(script.Parent.NetModule)
local roomsFolder = ServerStorage.Rooms

local module = {}

module.Cache = NetModule.New("Cache", "Folder", workspace, nil)

module.DestroyBranch = function(room: Model, visited)
	task.wait()

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

			local parameters = OverlapParams.new()
			parameters.FilterType = Enum.RaycastFilterType.Exclude
			parameters.FilterDescendantsInstances = {
				clone,
				previousRoom,
			}

			local cframe, size = clone:GetBoundingBox()

			local partsIn = workspace:GetPartBoundsInBox(cframe, size * 0.9, parameters)

			local blocked = false

			for _, part in ipairs(partsIn) do
				if part.Name == "Barrier" then
					blocked = true
					break
				end

				if part.CanCollide and not part:IsDescendantOf(clone) then
					blocked = true
					break
				end
			end

			if blocked then
				clone:Destroy()
				continue
			end

			local currentTag = Instance.new("ObjectValue")
			currentTag.Name = "__Connecting"
			currentTag.Parent = previousRoom
			currentTag.Value = clone

			local previousTag = Instance.new("ObjectValue")
			previousTag.Name = "__Previous"
			previousTag.Parent = clone
			previousTag.Value = PreviousEnd

			return clone
		end

		--[[

		local findPreviousTag = previousRoom:FindFirstChild("__Previous")

		if findPreviousTag and findPreviousTag.Value then
			local previousEnd = findPreviousTag.Value
		
			module.DestroyBranch(previousRoom)
			previousRoom:Destroy()

			task.spawn(function()
				if previousEnd and previousEnd.Parent then
					module.NextRoom(previousEnd)
				end
			end)
		end
	
		]]
	end

	local rayOrigin = PreviousEnd.Position
	local rayDirection = (PreviousEnd.CFrame * CFrame.Angles(0, math.rad(180), 0)).LookVector
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {
		previousRoom,
	}

	-- Rojo connected

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

module.NewBranch = function(StartingEnd, MaxDepth)
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
		end

		table.clear(ends)
		ends = table.clone(temp)
		table.clear(temp)
	end
	
	return branch
end

return module