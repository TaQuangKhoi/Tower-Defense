--!strict
-- EconomyService.luau
-- Server-authoritative economy/coin management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
type PlayerData = Types.PlayerData

local EconomyService = {}
EconomyService.__index = EconomyService

-- Store player coins in memory
local playerCoins: {[Player]: number} = {}

function EconomyService.Init()
	print("[EconomyService] Initialized")
end

function EconomyService.GetCoins(player: Player): number
	return playerCoins[player] or 0
end

function EconomyService.AddCoins(player: Player, amount: number): number
	if amount < 0 then
		warn("[EconomyService] Cannot add negative coins")
		return EconomyService.GetCoins(player)
	end
	
	local currentCoins = EconomyService.GetCoins(player)
	local newCoins = currentCoins + amount
	playerCoins[player] = newCoins
	
	print("[EconomyService] Player", player.Name, "gained", amount, "coins (Total:", newCoins, ")")
	return newCoins
end

function EconomyService.SpendCoins(player: Player, amount: number): boolean
	if amount < 0 then
		warn("[EconomyService] Cannot spend negative coins")
		return false
	end
	
	local currentCoins = EconomyService.GetCoins(player)
	if currentCoins < amount then
		warn("[EconomyService] Player", player.Name, "doesn't have enough coins (Has:", currentCoins, "Needs:", amount, ")")
		return false
	end
	
	local newCoins = currentCoins - amount
	playerCoins[player] = newCoins
	
	print("[EconomyService] Player", player.Name, "spent", amount, "coins (Remaining:", newCoins, ")")
	return true
end

function EconomyService.SetCoins(player: Player, amount: number)
	if amount < 0 then
		warn("[EconomyService] Cannot set negative coins")
		return
	end
	
	playerCoins[player] = amount
end

function EconomyService.LoadCoins(player: Player, amount: number)
	playerCoins[player] = amount or 0
	print("[EconomyService] Loaded", amount, "coins for", player.Name)
end

function EconomyService.GetCoinsData(player: Player): number
	return EconomyService.GetCoins(player)
end

function EconomyService.CleanupPlayer(player: Player)
	playerCoins[player] = nil
end

return EconomyService
