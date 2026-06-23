local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(ReplicatedStorage.Shared.Config.Types)

local module = {}
local Timer = {}
Timer.__index = Timer

--[[
	Timer.new(time: number): Types.Timer
	
	Creates a new Timer instance with the specified duration.
	If time is 0, it is set to math.huge (infinite timer).
	
	Parameters:
		time: number - The duration of the timer in seconds
	
	Returns:
		Types.Timer - A new Timer instance
]]
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

--[[
	Timer:Resume()
	
	Starts or resumes the timer countdown. If already running, this does nothing.
	Connects to either RenderStepped (client) or Heartbeat (server) for delta time updates.
	Fires the Loop signal at regular Threshold intervals.
	Fires the Done signal when time reaches zero.
]]
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

--[[
	Timer:Pause()
	
	Pauses the timer without resetting its state.
	The timer can be resumed later with Resume().
]]
function Timer:Pause()
	self.RuntimeTrove:Clean()
	self.Started = false
end

--[[
	Timer:Destroy()
	
	Completely destroys the timer, cleaning up all connections and signals.
	Should be called when the timer is no longer needed.
]]
function Timer:Destroy()
	self:Pause()
	self.Trove:Destroy()
end

--[[
	Timer:BindToValue(value: NumberValue)
	
	Binds the timer to a NumberValue instance, automatically updating its value each frame.
	
	Parameters:
		value: NumberValue - The NumberValue to bind to (must be a valid NumberValue)
	
	Throws:
		Assertion error if the provided value is not a NumberValue
]]
function Timer:BindToValue(value: NumberValue)
	assert(value:IsA("NumberValue"), "Must be a NumberValue")

	self.CurrentValue = value
end

--[[
	Timer:Reset(time: number)
	
	Resets the timer to a new duration and clears the threshold accumulator.
	Pauses the timer, so Resume() must be called to start it again.
	
	Parameters:
		time: number - The new duration in seconds
]]
function Timer:Reset(time)
	self:Pause()

	self.Time = time
	self.CurrentThreshold = 0
end

--[[
	Timer:UnbindFromValue()
	
	Unbinds the timer from any previously bound NumberValue.
	The timer will no longer update any external value.
]]
function Timer:UnbindFromValue()
	self.CurrentValue = nil
end

return module