--!strict
-- DataStoreService.luau
-- Handle data persistence

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
type PlayerData = Types.PlayerData

local DataService = {}
DataService.__index = DataService

-- Dependencies (injected)
local ProgressService
local EconomyService
local InventoryService

-- Try to get DataStore (may fail in Studio without API enabled)
local playerDataStore
local USE_MOCK_DATA = false
local success, result = pcall(function()
	return DataStoreService:GetDataStore("PlayerData_v1")
end)

if success then
	playerDataStore = result
	print("[DataService] DataStore enabled")
else
	warn("[DataService] DataStore not available (running in mock mode):", result)
	USE_MOCK_DATA = true
end

local mockData: {[number]: PlayerData} = {}  -- Mock storage for testing
local AUTO_SAVE_INTERVAL = 120  -- Auto-save every 2 minutes

function DataService.Init(progressService, economyService, inventoryService)
	ProgressService = progressService
	EconomyService = economyService
	InventoryService = inventoryService
	
	-- Start auto-save loop
	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_INTERVAL)
			DataService.AutoSaveAll()
		end
	end)
	
	print("[DataService] Initialized with auto-save every", AUTO_SAVE_INTERVAL, "seconds")
end

function DataService.GetKey(player: Player): string
	return "Player_" .. player.UserId
end

function DataService.LoadProfile(player: Player): PlayerData?
	-- Use mock data if DataStore is not available
	if USE_MOCK_DATA then
		local data = mockData[player.UserId]
		if data then
			print("[DataService] [MOCK] Loaded data for", player.Name)
			return data
		else
			print("[DataService] [MOCK] No saved data for", player.Name, "- using defaults")
			return {
				StageIndex = 1,
				Coins = 0,
				OwnedItems = {}
			}
		end
	end
	
	local key = DataService.GetKey(player)
	local success, data = pcall(function()
		return playerDataStore:GetAsync(key)
	end)
	
	if not success then
		warn("[DataService] Failed to load data for", player.Name, ":", data)
		return nil
	end
	
	if data then
		print("[DataService] Loaded data for", player.Name)
		return data
	else
		print("[DataService] No saved data for", player.Name, "- using defaults")
		return {
			StageIndex = 1,
			Coins = 0,
			OwnedItems = {}
		}
	end
end

function DataService.SaveProfile(player: Player): boolean
	-- Gather all player data from services
	local data: PlayerData = {
		StageIndex = ProgressService.GetStage(player),
		Coins = EconomyService.GetCoins(player),
		OwnedItems = InventoryService.GetItems(player)
	}
	
	-- Use mock data if DataStore is not available
	if USE_MOCK_DATA then
		mockData[player.UserId] = data
		print("[DataService] [MOCK] Saved data for", player.Name, "- Stage:", data.StageIndex, "Coins:", data.Coins, "Items:", #data.OwnedItems)
		return true
	end
	
	local key = DataService.GetKey(player)
	local success, err = pcall(function()
		playerDataStore:SetAsync(key, data)
	end)
	
	if not success then
		warn("[DataService] Failed to save data for", player.Name, ":", err)
		return false
	end
	
	print("[DataService] Saved data for", player.Name, "- Stage:", data.StageIndex, "Coins:", data.Coins, "Items:", #data.OwnedItems)
	return true
end

function DataService.AutoSaveAll()
	local players = Players:GetPlayers()
	print("[DataService] Auto-saving data for", #players, "players...")
	
	for _, player in ipairs(players) do
		DataService.SaveProfile(player)
	end
end

return DataService
