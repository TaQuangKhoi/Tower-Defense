--!strict
-- Stages.luau
-- Stage configuration

local Stages = {
	TotalStages = 10,  -- Total number of stages in the game
	DefaultSpawn = CFrame.new(0, 5, 0),  -- Default spawn for Stage 1
	CheckpointTag = "Checkpoint",  -- Tag used to identify checkpoint parts
	CoinTag = "Coin",  -- Tag used to identify coin parts
	CoinRespawnTime = 30,  -- Seconds before a coin respawns
}

return Stages
