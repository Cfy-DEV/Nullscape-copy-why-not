local module = {

	Client = function(part)
		local hue = 0
		while true do
			part.Color = Color3.fromHSV(hue, 1, 1)
			hue = (hue + 0.05) % 1
			task.wait(0.25)
		end
	end,
}

return module
