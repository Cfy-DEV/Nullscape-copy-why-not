local module = {}
local RNG = {}

function module.new()
    local self = setmetatable({}, RNG)

    self.Items = {}

    return self
end

function RNG:AddItem(item, percentage)

end

return module