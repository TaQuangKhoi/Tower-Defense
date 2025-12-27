--!strict
-- Types.luau
-- Shared type definitions for Checkpoint Rush

export type PlayerData = {
	StageIndex: number,
	Coins: number,
	OwnedItems: {string}
}

export type ItemConfig = {
	Id: string,
	Name: string,
	Description: string,
	Price: number,
	Type: "Passive" | "Ability" | "Consumable",
	Effects: {[string]: any}
}

export type StageConfig = {
	StageIndex: number,
	SpawnCFrame: CFrame?
}

export type PurchaseResult = {
	Success: boolean,
	Message: string,
	NewCoins: number?,
	OwnedItems: {string}?
}

return {}
