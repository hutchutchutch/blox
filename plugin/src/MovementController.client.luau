local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local Types = require(ReplicatedStorage:WaitForChild("Types"))

local BASE_WALKSPEED = 16
local SPRINT_MULTIPLIER = 1.5
local isSprinting = false
local canSprint = true
local sprintStamina = 100
local maxStamina = 100
local staminaRegenRate = 20
local staminaDrainRate = 15

local playerData: Types.PlayerData? = nil
local upgrades = {}

local screenGui = player.PlayerGui:WaitForChild("HeatSeekerUI")
local staminaFrame = Instance.new("Frame")
staminaFrame.Name = "StaminaFrame"
staminaFrame.Size = UDim2.new(0, 200, 0, 20)
staminaFrame.Position = UDim2.new(0.5, -100, 0, 90)
staminaFrame.BackgroundColor3 = Color3.new(0, 0, 0)
staminaFrame.BackgroundTransparency = 0.3
staminaFrame.Parent = screenGui

local staminaBar = Instance.new("Frame")
staminaBar.Name = "StaminaBar"
staminaBar.Size = UDim2.new(1, -4, 1, -4)
staminaBar.Position = UDim2.new(0, 2, 0, 2)
staminaBar.BackgroundColor3 = Color3.new(0, 1, 0)
staminaBar.Parent = staminaFrame

local staminaLabel = Instance.new("TextLabel")
staminaLabel.Name = "StaminaLabel"
staminaLabel.Size = UDim2.new(1, 0, 1, 0)
staminaLabel.BackgroundTransparency = 1
staminaLabel.Font = Enum.Font.SourceSans
staminaLabel.TextScaled = true
staminaLabel.TextColor3 = Color3.new(1, 1, 1)
staminaLabel.Text = "Stamina"
staminaLabel.Parent = staminaFrame

local function updateMovementSpeed()
	local baseSpeed = BASE_WALKSPEED
	local rebirthBonus = playerData and (1 + playerData.rebirthLevel * 0.1) or 1
	local upgradeBonus = upgrades.SprintBoots and 1.5 or 1
	
	local finalSpeed = baseSpeed * rebirthBonus * upgradeBonus
	
	if isSprinting and sprintStamina > 0 then
		finalSpeed = finalSpeed * SPRINT_MULTIPLIER
	end
	
	humanoid.WalkSpeed = finalSpeed
end

local function handleSprint(actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		if canSprint and sprintStamina > 10 then
			isSprinting = true
			updateMovementSpeed()
		end
	elseif inputState == Enum.UserInputState.End then
		isSprinting = false
		updateMovementSpeed()
	end
end

local function createMovementEffects()
	if not character:FindFirstChild("HumanoidRootPart") then return end
	
	local attachment = Instance.new("Attachment")
	attachment.Name = "MovementAttachment"
	attachment.Parent = character.HumanoidRootPart
	
	if playerData and playerData.rebirthLevel >= 5 then
		local trail = Instance.new("Trail")
		trail.Name = "RainbowTrail"
		trail.Attachment0 = attachment
		trail.Attachment1 = attachment
		trail.Lifetime = 1
		trail.MinLength = 0
		trail.FaceCamera = true
		trail.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.new(1, 0.5, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.new(1, 1, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.new(0, 1, 0)),
			ColorSequenceKeypoint.new(0.67, Color3.new(0, 1, 1)),
			ColorSequenceKeypoint.new(0.83, Color3.new(0, 0, 1)),
			ColorSequenceKeypoint.new(1, Color3.new(0.5, 0, 1))
		}
		trail.Parent = character.HumanoidRootPart
	end
	
	if isSprinting then
		local speedEffect = Instance.new("ParticleEmitter")
		speedEffect.Name = "SpeedEffect"
		speedEffect.Texture = "rbxasset://textures/particles/smoke_main.dds"
		speedEffect.Rate = 20
		speedEffect.Lifetime = NumberRange.new(0.5, 1)
		speedEffect.Speed = NumberRange.new(5)
		speedEffect.SpreadAngle = Vector2.new(20, 20)
		speedEffect.Color = ColorSequence.new(Color3.new(1, 1, 1))
		speedEffect.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		}
		speedEffect.Parent = attachment
		
		game:GetService("Debris"):AddItem(speedEffect, 0.5)
	end
end

RunService.Heartbeat:Connect(function(deltaTime)
	if isSprinting and humanoid.MoveVector.Magnitude > 0 then
		sprintStamina = math.max(0, sprintStamina - staminaDrainRate * deltaTime)
		if sprintStamina <= 0 then
			isSprinting = false
			canSprint = false
			updateMovementSpeed()
			
			task.wait(2)
			canSprint = true
		end
	else
		sprintStamina = math.min(maxStamina, sprintStamina + staminaRegenRate * deltaTime)
	end
	
	local staminaPercent = sprintStamina / maxStamina
	staminaBar.Size = UDim2.new(staminaPercent, -4, 1, -4)
	staminaBar.BackgroundColor3 = Color3.new(1 - staminaPercent, staminaPercent, 0)
	
	if humanoid.MoveVector.Magnitude > 0 then
		createMovementEffects()
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.LeftShift then
		handleSprint("Sprint", Enum.UserInputState.Begin)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		handleSprint("Sprint", Enum.UserInputState.End)
	end
end)

local touchGui = Instance.new("ScreenGui")
touchGui.Name = "TouchControls"
touchGui.Parent = player.PlayerGui

if UserInputService.TouchEnabled then
	local sprintButton = Instance.new("TextButton")
	sprintButton.Name = "SprintButton"
	sprintButton.Size = UDim2.new(0, 80, 0, 80)
	sprintButton.Position = UDim2.new(1, -100, 1, -100)
	sprintButton.BackgroundColor3 = Color3.new(0, 0.5, 1)
	sprintButton.Text = "SPRINT"
	sprintButton.TextScaled = true
	sprintButton.Parent = touchGui
	
	sprintButton.TouchLongPress:Connect(function()
		handleSprint("Sprint", Enum.UserInputState.Begin)
	end)
	
	sprintButton.TouchEnded:Connect(function()
		handleSprint("Sprint", Enum.UserInputState.End)
	end)
end

local remotes = ReplicatedStorage:WaitForChild("HeatSeekerRemotes")
remotes.UpdatePlayerData.OnClientEvent:Connect(function(data: Types.PlayerData)
	playerData = data
	upgrades = data.upgrades or {}
	updateMovementSpeed()
end)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	updateMovementSpeed()
end)