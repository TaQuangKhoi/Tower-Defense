--!strict
-- ProgressService.luau
-- Server-authoritative progress tracking

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Stages = require(ReplicatedStorage.Shared.Config.Stages)

type PlayerData = Types.PlayerData

local ProgressService = {}
ProgressService.__index = ProgressService

-- Store player progress in memory
local playerProgress: {[Player]: {StageIndex: number, SpawnCFrame: CFrame}} = {}

function ProgressService.Init()
	print("[ProgressService] Initialized")
end

function ProgressService.GetStage(player: Player): number
	local progress = playerProgress[player]
	return progress and progress.StageIndex or 1
end

function ProgressService.SetStage(player: Player, stageIndex: number): boolean
	-- Validate stage index
	if stageIndex < 1 or stageIndex > Stages.TotalStages then
		warn("[ProgressService] Invalid stage index:", stageIndex)
		return false
	end
	
	local currentStage = ProgressService.GetStage(player)
	
	-- Anti-skip: only allow sequential progression
	if stageIndex > currentStage + 1 then
		warn("[ProgressService] Player", player.Name, "tried to skip from stage", currentStage, "to", stageIndex)
		return false
	end
	
	-- Update progress
	if not playerProgress[player] then
		playerProgress[player] = {StageIndex = 1, SpawnCFrame = Stages.DefaultSpawn}
	end
	
	playerProgress[player].StageIndex = stageIndex
	
	print("[ProgressService] Player", player.Name, "advanced to stage", stageIndex)
	return true
end

function ProgressService.SetSpawnPoint(player: Player, spawnCFrame: CFrame)
	if not playerProgress[player] then
		playerProgress[player] = {StageIndex = 1, SpawnCFrame = Stages.DefaultSpawn}
	end
	
	playerProgress[player].SpawnCFrame = spawnCFrame
end

function ProgressService.GetSpawnPoint(player: Player): CFrame
	local progress = playerProgress[player]
	return progress and progress.SpawnCFrame or Stages.DefaultSpawn
end

function ProgressService.TeleportToStage(player: Player)
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	local spawnCFrame = ProgressService.GetSpawnPoint(player)
	humanoidRootPart.CFrame = spawnCFrame
end

function ProgressService.LoadProgress(player: Player, data: PlayerData)
	playerProgress[player] = {
		StageIndex = data.StageIndex or 1,
		SpawnCFrame = Stages.DefaultSpawn  -- Will be set when finding checkpoint
	}
	
	-- Find the checkpoint part for the loaded stage
	local checkpointParts = game.Workspace:GetDescendants()
	for _, part in ipairs(checkpointParts) do
		if part:IsA("BasePart") and part:HasTag(Stages.CheckpointTag) then
			local stageAttr = part:GetAttribute("StageIndex")
			if stageAttr == data.StageIndex then
				local offset = Vector3.new(0, 3, 0)
				playerProgress[player].SpawnCFrame = part.CFrame + offset
				break
			end
		end
	end
end

function ProgressService.GetProgressData(player: Player): {StageIndex: number}
	return {
		StageIndex = ProgressService.GetStage(player)
	}
end

function ProgressService.CleanupPlayer(player: Player)
	playerProgress[player] = nil
end

return ProgressService
