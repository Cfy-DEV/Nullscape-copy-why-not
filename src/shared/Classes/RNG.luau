local module = {}
local RNG = {}
RNG.__index = RNG

--[[
Creates a new object with RNG class.

    Store items with certain chances or weight
    Roll within given range
]]
function module.new()
	local self = setmetatable({}, RNG)

	self.Items = {}

	return self
end

--[[
Adds a new item to the RNG container.
]]
function RNG:AddItem(item, percentage)
	assert(percentage >= 0 and percentage <= 100, "Percentage must be between 0 and 100")
	table.insert(self.Items, { item, percentage })
	table.sort(self.Items, function(a, b)
		return a[2] < b[2]
	end)
end

--[[
Rolls items relative to their percentage and returns whatever the result was.
]]
function RNG:Roll()
	local perc = math.random() * 100
	for i = #self.Items, 1, -1 do
		local item = self.Items[i]
		if item[2] >= perc then
			return item[1]
		end
	end
end

return module
