--!strict
-- InputController.luau
-- Client-side input handling (double jump, etc.)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputController = {}
InputController.__index = InputController

local player = Players.LocalPlayer
local hasDoubleJump = false
local hasUsedDoubleJump = false

function InputController.Init()
	InputController.SetupDoubleJump()
	print("[InputController] Initialized")
end

function InputController.SetupDoubleJump()
	-- Listen for character spawns
	player.CharacterAdded:Connect(function(character)
		task.wait(0.1)  -- Wait for character to load
		
		local humanoid = character:WaitForChild("Humanoid")
		hasUsedDoubleJump = false
		
		-- Reset double jump on landing
		humanoid.StateChanged:Connect(function(_, newState)
			if newState == Enum.HumanoidStateType.Landed then
				hasUsedDoubleJump = false
			end
		end)
	end)
	
	-- Handle jump input
	UserInputService.JumpRequest:Connect(function()
		if not hasDoubleJump then return end
		
		local character = player.Character
		if not character then return end
		
		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then return end
		
		-- Check if in air and haven't used double jump yet
		if humanoid:GetState() == Enum.HumanoidStateType.Freefall and not hasUsedDoubleJump then
			-- Perform double jump
			hasUsedDoubleJump = true
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			
			-- Optional: Add visual effect
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				-- Create particle effect
				local particle = Instance.new("ParticleEmitter")
				particle.Texture = "rbxasset://textures/particles/smoke_main.dds"
				particle.Rate = 100
				particle.Lifetime = NumberRange.new(0.5)
				particle.Speed = NumberRange.new(5)
				particle.Parent = rootPart
				
				task.delay(0.1, function()
					particle.Enabled = false
					task.delay(1, function()
						particle:Destroy()
					end)
				end)
			end
		end
	end)
end

function InputController.EnableDoubleJump()
	hasDoubleJump = true
	print("[InputController] Double jump enabled")
end

function InputController.DisableDoubleJump()
	hasDoubleJump = false
	print("[InputController] Double jump disabled")
end

return InputController
