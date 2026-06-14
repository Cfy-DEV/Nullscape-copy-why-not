local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
local NetModule = require(ReplicatedStorage.Shared.Modules.NetModule)
local values = {
    SharedRoundTimeValue =

    NetModule.New(
    "RoundTime",
    "NumberValue",
    ReplicatedStorage,
    nil
    ),
    
    SharedRoundStageValue =
    
    NetModule.New(
    "RoundStage",
    "NumberValue",
    ReplicatedStorage,
    nil
    ),

    IsRoundHappening =
    
    NetModule.New(
    "IsRoundHapenning",
    "BoolValue",
    ReplicatedStorage,
    {Value = false}
    ),

    OrbCollected = Signal.new()
}

return values 