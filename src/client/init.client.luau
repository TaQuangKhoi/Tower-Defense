--!strict
-- init.client.luau
-- Main client initialization for Checkpoint Rush

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Controllers
local UIController = require(script.Controllers.UIController)
local InputController = require(script.Controllers.InputController)

print("[Client] Checkpoint Rush client initializing...")

-- Initialize controllers
UIController.Init()
InputController.Init()

print("[Client] Checkpoint Rush client ready!")
