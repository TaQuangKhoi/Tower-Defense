--!strict
-- PurchaseService.luau
-- Handle shop purchases with server validation

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Items = require(ReplicatedStorage.Shared.Config.Items)

type PurchaseResult = Types.PurchaseResult

local PurchaseService = {}
PurchaseService.__index = PurchaseService

-- Dependencies (injected)
local EconomyService
local InventoryService

-- Store player inventories
local playerInventories: {[Player]: {string}} = {}

function PurchaseService.Init(economyService, inventoryService)
	EconomyService = economyService
	InventoryService = inventoryService
	print("[PurchaseService] Initialized")
end

function PurchaseService.Purchase(player: Player, itemId: string): PurchaseResult
	-- Validate item exists
	local item = Items[itemId]
	if not item then
		return {
			Success = false,
			Message = "Item not found"
		}
	end
	
	-- Check if player already owns non-consumable item
	if item.Type ~= "Consumable" then
		if InventoryService.HasItem(player, itemId) then
			return {
				Success = false,
				Message = "You already own this item"
			}
		end
	end
	
	-- Check if player has enough coins
	local currentCoins = EconomyService.GetCoins(player)
	if currentCoins < item.Price then
		return {
			Success = false,
			Message = string.format("Not enough coins (Need %d, Have %d)", item.Price, currentCoins)
		}
	end
	
	-- Spend coins (atomic operation)
	local spendSuccess = EconomyService.SpendCoins(player, item.Price)
	if not spendSuccess then
		return {
			Success = false,
			Message = "Failed to process payment"
		}
	end
	
	-- Add item to inventory
	InventoryService.AddItem(player, itemId)
	
	local newCoins = EconomyService.GetCoins(player)
	local ownedItems = InventoryService.GetItems(player)
	
	print("[PurchaseService] Player", player.Name, "purchased", itemId, "for", item.Price, "coins")
	
	return {
		Success = true,
		Message = string.format("Purchased %s!", item.Name),
		NewCoins = newCoins,
		OwnedItems = ownedItems
	}
end

return PurchaseService
