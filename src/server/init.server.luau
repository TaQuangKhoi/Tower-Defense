--!strict
-- init.server.luau
-- Main server initialization for Checkpoint Rush

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

-- Services
local ProgressService = require(script.Services.ProgressService)
local EconomyService = require(script.Services.EconomyService)
local InventoryService = require(script.Services.InventoryService)
local PurchaseService = require(script.Services.PurchaseService)
local DataService = require(script.Services.DataService)

-- Shared modules
local Stages = require(ReplicatedStorage.Shared.Config.Stages)
local Items = require(ReplicatedStorage.Shared.Config.Items)

-- Initialize services
ProgressService.Init()
EconomyService.Init()
InventoryService.Init()
PurchaseService.Init(EconomyService, InventoryService)
DataService.Init(ProgressService, EconomyService, InventoryService)

-- Remote events (wait for them to exist)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ProgressUpdated = Remotes:WaitForChild("ProgressUpdated")
local CoinsUpdated = Remotes:WaitForChild("CoinsUpdated")
local CheckpointReached = Remotes:WaitForChild("CheckpointReached")
local ItemPurchased = Remotes:WaitForChild("ItemPurchased")
local DataLoaded = Remotes:WaitForChild("DataLoaded")
local PurchaseRequest = Remotes:WaitForChild("PurchaseRequest")
local UseItem = Remotes:WaitForChild("UseItem")

-- Sound effects
local SoundService = game:GetService("SoundService")

local function CreateSound(soundId: string, volume: number): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.Parent = SoundService
	return sound
end

-- Create sound effects
local checkpointSound = CreateSound("rbxassetid://5153734434", 0.5)  -- Success sound
local coinSound = CreateSound("rbxassetid://5153734609", 0.3)  -- Coin collect
local purchaseSound = CreateSound("rbxassetid://5153734667", 0.4)  -- Purchase sound

print("[Server] Checkpoint Rush server initialized")

-- Track collected coins per player (anti-spam)
local recentlyCollectedCoins: {[Player]: {[Instance]: number}} = {}
local COIN_COLLECTION_COOLDOWN = 1  -- seconds

-- Player joined
Players.PlayerAdded:Connect(function(player)
	print("[Server] Player joined:", player.Name)
	
	-- Load player data
	local data = DataService.LoadProfile(player)
	if data then
		ProgressService.LoadProgress(player, data)
		EconomyService.LoadCoins(player, data.Coins)
		InventoryService.LoadInventory(player, data.OwnedItems)
	end
	
	-- Initialize coin tracking
	recentlyCollectedCoins[player] = {}
	
	-- Wait for character
	player.CharacterAdded:Connect(function(character)
		task.wait(0.1)  -- Small delay for character to load
		
		-- Teleport to saved checkpoint
		ProgressService.TeleportToStage(player)
		
		-- Send initial data to client
		local coins = EconomyService.GetCoins(player)
		local ownedItems = InventoryService.GetItems(player)
		local stage = ProgressService.GetStage(player)
		DataLoaded:FireClient(player, coins, ownedItems, stage)
		
		-- Apply passive items
		ApplyPassiveItems(player, character)
		
		-- Setup double jump if owned
		if table.find(ownedItems, "DoubleJump") then
			SetupDoubleJump(character)
		end
	end)
end)

-- Player leaving
Players.PlayerRemoving:Connect(function(player)
	print("[Server] Player leaving:", player.Name)
	
	-- Save player data
	DataService.SaveProfile(player)
	
	-- Cleanup
	ProgressService.CleanupPlayer(player)
	EconomyService.CleanupPlayer(player)
	InventoryService.CleanupPlayer(player)
	recentlyCollectedCoins[player] = nil
	StopCoinMagnet(player)
end)

-- Coin Magnet system
local magnetLoops: {[Player]: thread} = {}

function StartCoinMagnet(player: Player)
	-- Stop existing loop if any
	if magnetLoops[player] then
		task.cancel(magnetLoops[player])
	end
	
	-- Get magnet radius from item config
	local item = Items.CoinMagnet
	local radius = item.Effects.MagnetRadius
	
	-- Start collection loop
	magnetLoops[player] = task.spawn(function()
		while task.wait(0.5) do  -- Check every 0.5 seconds
			local character = player.Character
			if not character then continue end
			
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if not rootPart then continue end
			
			-- Find nearby coins
			for _, coinPart in ipairs(CollectionService:GetTagged(Stages.CoinTag)) do
				if not coinPart:IsA("BasePart") then continue end
				if coinPart.Transparency >= 1 then continue end  -- Skip respawning coins
				
				local distance = (coinPart.Position - rootPart.Position).Magnitude
				if distance <= radius then
					-- Collect coin (reuse existing logic)
					local playerCoinTracking = recentlyCollectedCoins[player]
					if not playerCoinTracking then continue end
					
					local lastCollected = playerCoinTracking[coinPart]
					local now = os.clock()
					if lastCollected and (now - lastCollected) < COIN_COLLECTION_COOLDOWN then
						continue  -- Still on cooldown
					end
					
					-- Mark as collected
					playerCoinTracking[coinPart] = now
					
					-- Add coins
					local coinValue = coinPart:GetAttribute("CoinValue") or 10
					local newCoins = EconomyService.AddCoins(player, coinValue)
					
					-- Play sound
					coinSound:Play()
					
					-- Notify client
					CoinsUpdated:FireClient(player, newCoins)
					
					-- Visual feedback
					coinPart.Transparency = 1
					coinPart.CanCollide = false
					
					-- Respawn coin
					task.delay(Stages.CoinRespawnTime, function()
						coinPart.Transparency = 0
						coinPart.CanCollide = false
					end)
				 end
			end
		end
	end)
	
	print("[Server] Coin Magnet started for", player.Name)
end

function StopCoinMagnet(player: Player)
	if magnetLoops[player] then
		task.cancel(magnetLoops[player])
		magnetLoops[player] = nil
		print("[Server] Coin Magnet stopped for", player.Name)
	end
end

-- Apply passive item effects
function ApplyPassiveItems(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local ownedItems = InventoryService.GetItems(player)
	
	-- Speed Boost
	if table.find(ownedItems, "SpeedBoost") then
		local item = Items.SpeedBoost
		humanoid.WalkSpeed = 16 * item.Effects.WalkSpeedMultiplier
		print("[Server] Applied SpeedBoost to", player.Name)
	end
	
	-- Coin Magnet
	if table.find(ownedItems, "CoinMagnet") then
		StartCoinMagnet(player)
	else
		StopCoinMagnet(player)
	end
end

-- Setup double jump ability
function SetupDoubleJump(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local hasDoubleJumped = false
	
	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			hasDoubleJumped = false
		elseif newState == Enum.HumanoidStateType.Freefall and not hasDoubleJumped then
			-- Allow double jump
			local UserInputService = game:GetService("UserInputService")
			-- Note: Double jump input is handled on client, this just tracks state
		end
	end)
end

-- Checkpoint system
local function SetupCheckpoint(checkpointPart: BasePart)
	local stageIndex = checkpointPart:GetAttribute("StageIndex")
	if not stageIndex then
		warn("[Server] Checkpoint missing StageIndex attribute:", checkpointPart:GetFullName())
		return
	end
	
	checkpointPart.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		
		local currentStage = ProgressService.GetStage(player)
		
		-- Anti-skip: only allow next checkpoint
		if stageIndex == currentStage + 1 then
			-- Update progress
			ProgressService.SetStage(player, stageIndex)
			
			-- Set spawn point (checkpoint position + offset)
			local offset = Vector3.new(0, 3, 0)
			ProgressService.SetSpawnPoint(player, checkpointPart.CFrame + offset)
			
			-- Play sound
			checkpointSound:Play()
			
			-- Notify client
			CheckpointReached:FireClient(player, stageIndex)
			ProgressUpdated:FireClient(player, stageIndex)
			
			print("[Server]", player.Name, "reached checkpoint", stageIndex)
		elseif stageIndex <= currentStage then
			-- Player touched an old checkpoint (ignore)
		else
			-- Player tried to skip (anti-cheat)
			warn("[Server]", player.Name, "tried to skip to checkpoint", stageIndex, "from stage", currentStage)
		end
	end)
end

-- Coin system
local function SetupCoin(coinPart: BasePart)
	local coinValue = coinPart:GetAttribute("CoinValue") or 10
	
	coinPart.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		
		-- Anti-spam: check cooldown
		local playerCoinTracking = recentlyCollectedCoins[player]
		if not playerCoinTracking then return end
		
		local lastCollected = playerCoinTracking[coinPart]
		local now = os.clock()
		if lastCollected and (now - lastCollected) < COIN_COLLECTION_COOLDOWN then
			return  -- Still on cooldown
		end
		
		-- Mark as collected
		playerCoinTracking[coinPart] = now
		
		-- Add coins
		local newCoins = EconomyService.AddCoins(player, coinValue)
		
		-- Play sound
		coinSound:Play()
		
		-- Notify client
		CoinsUpdated:FireClient(player, newCoins)
		
		-- Visual feedback (hide coin temporarily)
		coinPart.Transparency = 1
		coinPart.CanCollide = false
		
		-- Respawn coin after delay
		task.delay(Stages.CoinRespawnTime, function()
			coinPart.Transparency = 0
			coinPart.CanCollide = false  -- Coins should be non-collidable
		end)
	end)
	
	-- Make coins non-collidable
	coinPart.CanCollide = false
end

-- Purchase request handler
PurchaseRequest.OnServerEvent:Connect(function(player, itemId)
	print("[Server] Purchase request from", player.Name, "for item:", itemId)
	
	local result = PurchaseService.Purchase(player, itemId)
	
	-- Send result to client
	ItemPurchased:FireClient(player, result)
	
	-- If successful, update coins
	if result.Success then
		-- Play sound
		purchaseSound:Play()
		
		CoinsUpdated:FireClient(player, result.NewCoins)
		
		-- Apply item effects immediately if needed
		local character = player.Character
		if character then
			ApplyPassiveItems(player, character)
			
			if itemId == "DoubleJump" then
				SetupDoubleJump(character)
			end
		end
	end
end)

-- Use item handler (for consumables like CheckpointWarp)
UseItem.OnServerEvent:Connect(function(player, itemId)
	print("[Server] Use item request from", player.Name, "for item:", itemId)
	
	-- Validate player owns the item
	if not InventoryService.HasItem(player, itemId) then
		warn("[Server]", player.Name, "tried to use item they don't own:", itemId)
		return
	end
	
	-- Handle consumables
	if itemId == "CheckpointWarp" then
		-- Remove the consumable
		InventoryService.RemoveItem(player, itemId)
		
		-- Teleport to checkpoint
		ProgressService.TeleportToStage(player)
		
		print("[Server]", player.Name, "used CheckpointWarp")
	end
end)

-- Setup all checkpoints with the tag
for _, part in ipairs(CollectionService:GetTagged(Stages.CheckpointTag)) do
	if part:IsA("BasePart") then
		SetupCheckpoint(part)
	end
end

-- Listen for new checkpoints
CollectionService:GetInstanceAddedSignal(Stages.CheckpointTag):Connect(function(part)
	if part:IsA("BasePart") then
		SetupCheckpoint(part)
	end
end)

-- Setup all coins with the tag
for _, part in ipairs(CollectionService:GetTagged(Stages.CoinTag)) do
	if part:IsA("BasePart") then
		SetupCoin(part)
	end
end

-- Listen for new coins
CollectionService:GetInstanceAddedSignal(Stages.CoinTag):Connect(function(part)
	if part:IsA("BasePart") then
		SetupCoin(part)
	end
end)

print("[Server] Checkpoint Rush ready!")
