local CollectionService = game:GetService("CollectionService")
local module = {

	Client = function(part)
		local randomX = math.random(-360, 360) / 360
		local randomY = math.random(-360, 360) / 360
		local randomZ = math.random(-360, 360) / 360

		part.CFrame *= CFrame.Angles(math.rad(randomX), math.rad(randomY), math.rad(randomZ))
	end,
}

return module
