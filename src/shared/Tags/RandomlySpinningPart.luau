local module = {

	Client = function(part)
		while task.wait(0.1) do
			local randomX = math.random(-10, 10)
			local randomY = math.random(-10, 10)
			local randomZ = math.random(-10, 10)

			part.CFrame *= CFrame.Angles(math.rad(randomX), math.rad(randomY), math.rad(randomZ))
		end
	end,
}

return module
