local module = {

	Client = function(part)
		while task.wait(0.75) do
			local randomRotation = math.random(15, 45)
			part.CFrame = part.CFrame
				* CFrame.Angles(math.rad(randomRotation), math.rad(randomRotation), math.rad(randomRotation))
		end
	end,
}

return module
