--!strict
-- Items.luau
-- Item definitions for the shop

local Types = require(script.Parent.Parent.Types)
type ItemConfig = Types.ItemConfig

local Items: {[string]: ItemConfig} = {
	SpeedBoost = {
		Id = "SpeedBoost",
		Name = "Speed Boost",
		Description = "Increases your walking speed permanently",
		Price = 100,
		Type = "Passive",
		Effects = {
			WalkSpeedMultiplier = 1.5
		}
	},
	
	DoubleJump = {
		Id = "DoubleJump",
		Name = "Double Jump",
		Description = "Allows you to jump twice in mid-air",
		Price = 250,
		Type = "Ability",
		Effects = {
			ExtraJumps = 1
		}
	},
	
	CheckpointWarp = {
		Id = "CheckpointWarp",
		Name = "Checkpoint Warp",
		Description = "Instantly teleport to your current checkpoint (1 use)",
		Price = 50,
		Type = "Consumable",
		Effects = {}
	},
	
	CoinMagnet = {
		Id = "CoinMagnet",
		Name = "Coin Magnet",
		Description = "Automatically collect nearby coins",
		Price = 500,
		Type = "Passive",
		Effects = {
			MagnetRadius = 20
		}
	}
}

return Items
