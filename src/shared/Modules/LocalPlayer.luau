local UserSettings = UserSettings()
local GameSettings = UserSettings:GetService("UserGameSettings")

local module = {}

-- estimated render distances
local QUALITY_DISTANCES = {
	[1] = 150,
	[2] = 200,
	[3] = 250,
	[4] = 325,
	[5] = 400,
	[6] = 500,
	[7] = 650,
	[8] = 800,
	[9] = 1000,
	[10] = 1250,
}

function module.GetQualityLevel()

	local quality = GameSettings.SavedQualityLevel

	-- automatic graphics mode
	if quality == Enum.SavedQualitySetting.Automatic then

		-- fallback estimate
		return 5
	end

	return tonumber(
		string.match(
			quality.Name,
			"%d+"
		)
	)
end

function module:GetEstimatedRenderDistance()
	local quality = module.GetQualityLevel()

	return QUALITY_DISTANCES[quality] or 400
end

return module
