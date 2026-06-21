local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(ReplicatedStorage.Shared.Config.Types)

local module = {}
local Timer = {}
Timer.__index = Timer

function module.new(time): Types.Timer
	local self = setmetatable({}, Timer)

	self.Time = time
	self.Threshold = 0
	self.Done = Signal.new()
	self.Loop = Signal.new()
	self.Trove = Trove.new()
	self.RuntimeTrove = Trove.new()
	self.CurrentValue = nil
	self.CurrentThreshold = 0
	self.Started = false

	self.Trove:Add(self.Done)
	self.Trove:Add(self.Loop)

	if time == 0 then
		self.Time = math.huge
	end

	return self
end

function Timer:Resume()
	if self.Started then
		return
	end

	self.Started = true

	local function decrease(delta)
		if self.Time == 0 then
			return
		end

		if self.Threshold > 0 then
			self.CurrentThreshold += delta

			if self.CurrentThreshold >= self.Threshold then
				self.CurrentThreshold -= self.Threshold

				self.Loop:Fire()
			end
		end

		self.Time -= delta

		if self.CurrentValue ~= nil then
			self.CurrentValue.Value = self.Time
		end

		if self.Time <= 0 then
			self.Time = 0
			self.Started = false
			self.RuntimeTrove:Clean()
			self.Done:Fire()
		end
	end

	if RunService:IsClient() then
		self.RuntimeTrove:Add(RunService.RenderStepped:Connect(function(delta: number)
			decrease(delta)
		end))
	elseif RunService:IsServer() then
		self.RuntimeTrove:Add(RunService.Heartbeat:Connect(function(delta: number)
			decrease(delta)
		end))
	end
end

function Timer:Pause()
	self.RuntimeTrove:Clean()
	self.Started = false
end

function Timer:Destroy()
	self:Pause()
	self.Trove:Destroy()
end

function Timer:BindToValue(value: NumberValue)
	assert(value:IsA("NumberValue"), "Must be a numberValue")

	self.CurrentValue = value
end

function Timer:Reset(time)
	self:Pause()

	self.Time = time
	self.CurrentThreshold = 0
end

--[[
Unbind 
]]
function Timer:UnbindFromValue()
	self.CurrentValue = nil
end

return module
