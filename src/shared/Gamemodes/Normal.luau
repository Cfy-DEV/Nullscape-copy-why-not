local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networking = require(ReplicatedStorage.Shared.Config.Networking)
local ProceduralRoomGeneration = require(ReplicatedStorage.Shared.Modules.ProceduralRoomGeneration)
local enemies = {}

ProceduralRoomGeneration.Chunk.CenterOfMass = ProceduralRoomGeneration.Cache.StartingRoom.End.Position

return function()
	ProceduralRoomGeneration.NewBranch(ProceduralRoomGeneration.Cache.StartingRoom.End, 15, 0.025)
end
