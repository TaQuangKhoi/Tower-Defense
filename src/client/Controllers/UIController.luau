--!strict
-- UIController.luau
-- Client-side UI management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Items = require(ReplicatedStorage.Shared.Config.Items)
local Types = require(ReplicatedStorage.Shared.Types)

local UIController = {}
UIController.__index = UIController

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- State
local currentCoins = 0
local ownedItems = {}
local currentStage = 1

-- UI References (will be created)
local screenGui: ScreenGui
local coinLabel: TextLabel
local shopButton: TextButton
local shopFrame: Frame
local itemsList: ScrollingFrame

-- Remote events
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ProgressUpdated = Remotes:WaitForChild("ProgressUpdated")
local CoinsUpdated = Remotes:WaitForChild("CoinsUpdated")
local CheckpointReached = Remotes:WaitForChild("CheckpointReached")
local ItemPurchased = Remotes:WaitForChild("ItemPurchased")
local DataLoaded = Remotes:WaitForChild("DataLoaded")
local PurchaseRequest = Remotes:WaitForChild("PurchaseRequest")
local UseItem = Remotes:WaitForChild("UseItem")

function UIController.Init()
	UIController.CreateUI()
	UIController.CreateConsumableButtons()
	UIController.SetupRemoteListeners()
	print("[UIController] Initialized")
end

function UIController.CreateUI()
	-- Main ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CheckpointRushUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	
	-- Coin counter (top-left)
	local coinFrame = Instance.new("Frame")
	coinFrame.Name = "CoinFrame"
	coinFrame.Size = UDim2.new(0, 200, 0, 50)
	coinFrame.Position = UDim2.new(0, 10, 0, 10)
	coinFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	coinFrame.BorderSizePixel = 2
	coinFrame.BorderColor3 = Color3.fromRGB(255, 200, 0)
	coinFrame.Parent = screenGui
	
	local coinIcon = Instance.new("TextLabel")
	coinIcon.Name = "CoinIcon"
	coinIcon.Size = UDim2.new(0, 40, 1, 0)
	coinIcon.Position = UDim2.new(0, 5, 0, 0)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text = "🪙"
	coinIcon.TextSize = 28
	coinIcon.Font = Enum.Font.GothamBold
	coinIcon.Parent = coinFrame
	
	coinLabel = Instance.new("TextLabel")
	coinLabel.Name = "CoinLabel"
	coinLabel.Size = UDim2.new(1, -50, 1, 0)
	coinLabel.Position = UDim2.new(0, 50, 0, 0)
	coinLabel.BackgroundTransparency = 1
	coinLabel.Text = "0"
	coinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	coinLabel.TextSize = 24
	coinLabel.Font = Enum.Font.GothamBold
	coinLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinLabel.Parent = coinFrame
	
	-- Shop button (top-right)
	shopButton = Instance.new("TextButton")
	shopButton.Name = "ShopButton"
	shopButton.Size = UDim2.new(0, 150, 0, 50)
	shopButton.Position = UDim2.new(1, -160, 0, 10)
	shopButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	shopButton.BorderSizePixel = 2
	shopButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
	shopButton.Text = "🛒 SHOP"
	shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopButton.TextSize = 20
	shopButton.Font = Enum.Font.GothamBold
	shopButton.Parent = screenGui
	
	-- Shop frame (hidden by default)
	shopFrame = Instance.new("Frame")
	shopFrame.Name = "ShopFrame"
	shopFrame.Size = UDim2.new(0, 500, 0, 600)
	shopFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
	shopFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	shopFrame.BorderSizePixel = 3
	shopFrame.BorderColor3 = Color3.fromRGB(255, 200, 0)
	shopFrame.Visible = false
	shopFrame.Parent = screenGui
	
	-- Shop title
	local shopTitle = Instance.new("TextLabel")
	shopTitle.Name = "Title"
	shopTitle.Size = UDim2.new(1, 0, 0, 50)
	shopTitle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	shopTitle.Text = "SHOP"
	shopTitle.TextColor3 = Color3.fromRGB(255, 200, 0)
	shopTitle.TextSize = 28
	shopTitle.Font = Enum.Font.GothamBold
	shopTitle.Parent = shopFrame
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 24
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = shopFrame
	
	-- Items list
	itemsList = Instance.new("ScrollingFrame")
	itemsList.Name = "ItemsList"
	itemsList.Size = UDim2.new(1, -20, 1, -70)
	itemsList.Position = UDim2.new(0, 10, 0, 60)
	itemsList.BackgroundTransparency = 1
	itemsList.BorderSizePixel = 0
	itemsList.ScrollBarThickness = 8
	itemsList.Parent = shopFrame
	
	-- List layout
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = itemsList
	
	-- Button events
	shopButton.MouseButton1Click:Connect(function()
		shopFrame.Visible = not shopFrame.Visible
		if shopFrame.Visible then
			UIController.RefreshShop()
		end
	end)
	
	closeButton.MouseButton1Click:Connect(function()
		shopFrame.Visible = false
	end)
	
	-- Stage indicator (top-center)
	local stageLabel = Instance.new("TextLabel")
	stageLabel.Name = "StageLabel"
	stageLabel.Size = UDim2.new(0, 200, 0, 40)
	stageLabel.Position = UDim2.new(0.5, -100, 0, 10)
	stageLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	stageLabel.BorderSizePixel = 2
	stageLabel.BorderColor3 = Color3.fromRGB(100, 200, 255)
	stageLabel.Text = "Stage 1"
	stageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	stageLabel.TextSize = 20
	stageLabel.Font = Enum.Font.GothamBold
	stageLabel.Parent = screenGui
	
	-- Store reference
	UIController.stageLabel = stageLabel
end

function UIController.CreateConsumableButtons()
	-- Create consumable items bar (bottom-right)
	local consumablesFrame = Instance.new("Frame")
	consumablesFrame.Name = "ConsumablesFrame"
	consumablesFrame.Size = UDim2.new(0, 200, 0, 70)
	consumablesFrame.Position = UDim2.new(1, -210, 1, -80)
	consumablesFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	consumablesFrame.BorderSizePixel = 2
	consumablesFrame.BorderColor3 = Color3.fromRGB(150, 150, 150)
	consumablesFrame.Parent = screenGui
	
	local consumablesLayout = Instance.new("UIListLayout")
	consumablesLayout.Padding = UDim.new(0, 5)
	consumablesLayout.FillDirection = Enum.FillDirection.Horizontal
	consumablesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	consumablesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	consumablesLayout.Parent = consumablesFrame
	
	local consumablesPadding = Instance.new("UIPadding")
	consumablesPadding.PaddingLeft = UDim.new(0, 10)
	consumablesPadding.PaddingRight = UDim.new(0, 10)
	consumablesPadding.PaddingTop = UDim.new(0, 10)
	consumablesPadding.PaddingBottom = UDim.new(0, 10)
	consumablesPadding.Parent = consumablesFrame
	
	-- Store reference
	UIController.consumablesFrame = consumablesFrame
end

function UIController.RefreshConsumables()
	if not UIController.consumablesFrame then return end
	
	-- Clear existing buttons
	for _, child in ipairs(UIController.consumablesFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	-- Add button for CheckpointWarp if owned
	if table.find(ownedItems, "CheckpointWarp") then
		local warpButton = Instance.new("TextButton")
		warpButton.Name = "CheckpointWarpButton"
		warpButton.Size = UDim2.new(0, 180, 0, 50)
		warpButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
		warpButton.BorderSizePixel = 0
		warpButton.Text = "🚀 Warp to Checkpoint"
		warpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		warpButton.TextSize = 16
		warpButton.Font = Enum.Font.GothamBold
		warpButton.Parent = UIController.consumablesFrame
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = warpButton
		
		warpButton.MouseButton1Click:Connect(function()
			-- Send use item request to server
			UseItem:FireServer("CheckpointWarp")
			warpButton.Text = "Using..."
			warpButton.Active = false
			
			-- Remove button after use (will be recreated if another is purchased)
			task.delay(0.5, function()
				warpButton:Destroy()
			end)
		end)
	end
	
	-- Hide frame if no consumables
	UIController.consumablesFrame.Visible = #UIController.consumablesFrame:GetChildren() > 2  -- >2 because layout+padding
end

function UIController.RefreshShop()
	-- Clear existing items
	for _, child in ipairs(itemsList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Create item cards
	local yOffset = 0
	for _, item in pairs(Items) do
		UIController.CreateItemCard(item, yOffset)
		yOffset = yOffset + 1
	end
	
	-- Update canvas size
	itemsList.CanvasSize = UDim2.new(0, 0, 0, yOffset * 120 + (yOffset - 1) * 10)
end

function UIController.CreateItemCard(item: any, layoutOrder: number)
	local isOwned = table.find(ownedItems, item.Id) ~= nil
	local canAfford = currentCoins >= item.Price
	
	-- Item frame
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = item.Id
	itemFrame.Size = UDim2.new(1, -10, 0, 110)
	itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	itemFrame.BorderSizePixel = 2
	itemFrame.BorderColor3 = isOwned and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(150, 150, 150)
	itemFrame.LayoutOrder = layoutOrder
	itemFrame.Parent = itemsList
	
	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 30)
	nameLabel.Position = UDim2.new(0, 5, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = itemFrame
	
	-- Item description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -10, 0, 40)
	descLabel.Position = UDim2.new(0, 5, 0, 35)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = item.Description
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextSize = 14
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.Parent = itemFrame
	
	-- Price/Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0, 120, 0, 30)
	buyButton.Position = UDim2.new(1, -125, 1, -35)
	buyButton.BackgroundColor3 = isOwned and Color3.fromRGB(100, 100, 100) or (canAfford and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50))
	buyButton.BorderSizePixel = 0
	buyButton.Text = isOwned and "OWNED" or ("🪙 " .. item.Price)
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.TextSize = 16
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Active = not isOwned and canAfford
	buyButton.Parent = itemFrame
	
	if not isOwned and canAfford then
		buyButton.MouseButton1Click:Connect(function()
			-- Send purchase request to server
			PurchaseRequest:FireServer(item.Id)
			buyButton.Text = "..."
			buyButton.Active = false
		end)
	end
end

function UIController.SetupRemoteListeners()
	-- Data loaded from server
	DataLoaded.OnClientEvent:Connect(function(coins, items, stage)
		print("[UIController] Data loaded - Coins:", coins, "Items:", #items, "Stage:", stage)
		currentCoins = coins
		ownedItems = items
		currentStage = stage
		UIController.UpdateCoinDisplay()
		UIController.UpdateStageDisplay()
		UIController.RefreshConsumables()
		
		-- Enable double jump if owned
		if table.find(items, "DoubleJump") then
			local InputController = require(script.Parent.InputController)
			InputController.EnableDoubleJump()
		end
	end)
	
	-- Coins updated
	CoinsUpdated.OnClientEvent:Connect(function(coins)
		print("[UIController] Coins updated:", coins)
		currentCoins = coins
		UIController.UpdateCoinDisplay()
		
		-- Refresh shop if open
		if shopFrame.Visible then
			UIController.RefreshShop()
		end
	end)
	
	-- Progress updated
	ProgressUpdated.OnClientEvent:Connect(function(stage)
		print("[UIController] Progress updated - Stage:", stage)
		currentStage = stage
		UIController.UpdateStageDisplay()
	end)
	
	-- Checkpoint reached (visual feedback)
	CheckpointReached.OnClientEvent:Connect(function(stage)
		print("[UIController] Checkpoint reached:", stage)
		UIController.ShowCheckpointToast(stage)
	end)
	
	-- Item purchased
	ItemPurchased.OnClientEvent:Connect(function(result)
		print("[UIController] Purchase result:", result.Success, result.Message)
		
		if result.Success then
			currentCoins = result.NewCoins
			ownedItems = result.OwnedItems
			UIController.UpdateCoinDisplay()
			UIController.RefreshConsumables()
			UIController.ShowNotification(result.Message, Color3.fromRGB(100, 255, 100))
			
			-- Enable double jump if it was just purchased
			if table.find(result.OwnedItems, "DoubleJump") then
				local InputController = require(script.Parent.InputController)
				InputController.EnableDoubleJump()
			end
		else
			UIController.ShowNotification(result.Message, Color3.fromRGB(255, 100, 100))
		end
		
		-- Refresh shop
		if shopFrame.Visible then
			UIController.RefreshShop()
		end
	end)
end

function UIController.UpdateCoinDisplay()
	coinLabel.Text = tostring(currentCoins)
end

function UIController.UpdateStageDisplay()
	if UIController.stageLabel then
		UIController.stageLabel.Text = "Stage " .. tostring(currentStage)
	end
end

function UIController.ShowCheckpointToast(stage: number)
	-- Create toast notification
	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(0, 300, 0, 60)
	toast.Position = UDim2.new(0.5, -150, 0.8, 0)
	toast.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	toast.BorderSizePixel = 0
	toast.Parent = screenGui
	
	local toastLabel = Instance.new("TextLabel")
	toastLabel.Size = UDim2.new(1, 0, 1, 0)
	toastLabel.BackgroundTransparency = 1
	toastLabel.Text = "✓ Checkpoint " .. stage .. " Reached!"
	toastLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	toastLabel.TextSize = 20
	toastLabel.Font = Enum.Font.GothamBold
	toastLabel.Parent = toast
	
	-- Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast
	
	-- Fade out and destroy
	task.delay(2, function()
		for i = 1, 10 do
			toast.BackgroundTransparency = i / 10
			toastLabel.TextTransparency = i / 10
			task.wait(0.05)
		end
		toast:Destroy()
	end)
end

function UIController.ShowNotification(message: string, color: Color3)
	-- Create notification
	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(0, 350, 0, 70)
	notif.Position = UDim2.new(0.5, -175, 0.5, -35)
	notif.BackgroundColor3 = color
	notif.BorderSizePixel = 0
	notif.ZIndex = 10
	notif.Parent = screenGui
	
	local notifLabel = Instance.new("TextLabel")
	notifLabel.Size = UDim2.new(1, -20, 1, -20)
	notifLabel.Position = UDim2.new(0, 10, 0, 10)
	notifLabel.BackgroundTransparency = 1
	notifLabel.Text = message
	notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	notifLabel.TextSize = 18
	notifLabel.Font = Enum.Font.GothamBold
	notifLabel.TextWrapped = true
	notifLabel.ZIndex = 10
	notifLabel.Parent = notif
	
	-- Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notif
	
	-- Fade out and destroy
	task.delay(2, function()
		for i = 1, 10 do
			notif.BackgroundTransparency = i / 10
			notifLabel.TextTransparency = i / 10
			task.wait(0.05)
		end
		notif:Destroy()
	end)
end

return UIController
