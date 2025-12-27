--!strict
-- Remotes folder structure
-- This file serves as documentation for the RemoteEvents structure

--[[
	The following RemoteEvents should be created in ReplicatedStorage.Remotes:
	
	Server -> Client:
	- ProgressUpdated: RemoteEvent (stageIndex: number)
	- CoinsUpdated: RemoteEvent (coins: number)
	- CheckpointReached: RemoteEvent (stageIndex: number)
	- ItemPurchased: RemoteEvent (result: PurchaseResult)
	- DataLoaded: RemoteEvent (coins: number, ownedItems: {string}, stageIndex: number)
	
	Client -> Server:
	- PurchaseRequest: RemoteEvent (itemId: string)
	- UseItem: RemoteEvent (itemId: string)
	
	You need to manually create these RemoteEvent instances in Roblox Studio:
	1. Create a Folder named "Remotes" in ReplicatedStorage
	2. Create RemoteEvent instances with the exact names listed above
--]]

return {}
