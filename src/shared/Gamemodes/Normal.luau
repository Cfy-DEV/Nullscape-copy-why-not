local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networking = require(ReplicatedStorage.Shared.Config.Networking)
local ProceduralRoomGeneration = require(ReplicatedStorage.Shared.Modules.ProceduralRoomGeneration)
local enemies = {}

return function()
	ProceduralRoomGeneration.NewBranch(ProceduralRoomGeneration.Cache.StartingRoom.End, 10)
end
