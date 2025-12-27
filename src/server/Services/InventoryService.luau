--!strict
-- InventoryService.luau
-- Manage player owned items

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Items = require(ReplicatedStorage.Shared.Config.Items)

local InventoryService = {}
InventoryService.__index = InventoryService

-- Store player inventories
local playerInventories: {[Player]: {string}} = {}

function InventoryService.Init()
	print("[InventoryService] Initialized")
end

function InventoryService.HasItem(player: Player, itemId: string): boolean
	local inventory = playerInventories[player]
	if not inventory then return false end
	
	return table.find(inventory, itemId) ~= nil
end

function InventoryService.AddItem(player: Player, itemId: string)
	if not playerInventories[player] then
		playerInventories[player] = {}
	end
	
	-- Don't add duplicates for non-consumables
	local item = Items[itemId]
	if item and item.Type ~= "Consumable" then
		if InventoryService.HasItem(player, itemId) then
			return
		end
	end
	
	table.insert(playerInventories[player], itemId)
	print("[InventoryService] Added", itemId, "to", player.Name, "'s inventory")
end

function InventoryService.RemoveItem(player: Player, itemId: string): boolean
	local inventory = playerInventories[player]
	if not inventory then return false end
	
	local index = table.find(inventory, itemId)
	if index then
		table.remove(inventory, index)
		print("[InventoryService] Removed", itemId, "from", player.Name, "'s inventory")
		return true
	end
	
	return false
end

function InventoryService.GetItems(player: Player): {string}
	return playerInventories[player] or {}
end

function InventoryService.LoadInventory(player: Player, items: {string})
	playerInventories[player] = items or {}
	print("[InventoryService] Loaded", #playerInventories[player], "items for", player.Name)
end

function InventoryService.GetInventoryData(player: Player): {string}
	return InventoryService.GetItems(player)
end

function InventoryService.CleanupPlayer(player: Player)
	playerInventories[player] = nil
end

return InventoryService
