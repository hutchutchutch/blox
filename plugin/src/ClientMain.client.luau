local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("HeatSeekerRemotes")

local playerGui = player:WaitForChild("PlayerGui")
local Types = require(script.Parent.Parent.Types)

local currentPlayerData: Types.PlayerData? = nil

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HeatSeekerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local overlayFrame = Instance.new("Frame")
overlayFrame.Name = "TemperatureOverlay"
overlayFrame.Size = UDim2.new(1, 0, 1, 0)
overlayFrame.BackgroundTransparency = 1
overlayFrame.Parent = screenGui

local vignetteImage = Instance.new("ImageLabel")
vignetteImage.Name = "Vignette"
vignetteImage.Size = UDim2.new(1, 0, 1, 0)
vignetteImage.BackgroundTransparency = 1
vignetteImage.Image = "rbxasset://textures/ui/LightingVignette.png"
vignetteImage.ImageTransparency = 1
vignetteImage.Parent = overlayFrame

local temperatureMeter = Instance.new("Frame")
temperatureMeter.Name = "TemperatureMeter"
temperatureMeter.Size = UDim2.new(0, 300, 0, 60)
temperatureMeter.Position = UDim2.new(0.5, -150, 0, 20)
temperatureMeter.BackgroundColor3 = Color3.new(0, 0, 0)
temperatureMeter.BackgroundTransparency = 0.3
temperatureMeter.Parent = screenGui

local tempBar = Instance.new("Frame")
tempBar.Name = "TempBar"
tempBar.Size = UDim2.new(0, 0, 1, -4)
tempBar.Position = UDim2.new(0, 2, 0, 2)
tempBar.Parent = temperatureMeter

local tempLabel = Instance.new("TextLabel")
tempLabel.Name = "TempLabel"
tempLabel.Size = UDim2.new(1, 0, 1, 0)
tempLabel.BackgroundTransparency = 1
tempLabel.Font = Enum.Font.SourceSansBold
tempLabel.TextScaled = true
tempLabel.TextColor3 = Color3.new(1, 1, 1)
tempLabel.Text = "COLD"
tempLabel.Parent = temperatureMeter

local statsFrame = Instance.new("Frame")
statsFrame.Name = "StatsFrame"
statsFrame.Size = UDim2.new(0, 200, 0, 150)
statsFrame.Position = UDim2.new(0, 10, 0, 100)
statsFrame.BackgroundColor3 = Color3.new(0, 0, 0)
statsFrame.BackgroundTransparency = 0.3
statsFrame.Parent = screenGui

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "MoneyLabel"
moneyLabel.Size = UDim2.new(1, -10, 0, 40)
moneyLabel.Position = UDim2.new(0, 5, 0, 5)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Font = Enum.Font.SourceSansBold
moneyLabel.TextScaled = true
moneyLabel.TextColor3 = Color3.new(1, 0.8, 0)
moneyLabel.Text = "💰 Money: 0"
moneyLabel.Parent = statsFrame

local tokensLabel = Instance.new("TextLabel")
tokensLabel.Name = "TokensLabel"
tokensLabel.Size = UDim2.new(1, -10, 0, 40)
tokensLabel.Position = UDim2.new(0, 5, 0, 50)
tokensLabel.BackgroundTransparency = 1
tokensLabel.Font = Enum.Font.SourceSansBold
tokensLabel.TextScaled = true
tokensLabel.TextColor3 = Color3.new(0.8, 0.4, 1)
tokensLabel.Text = "🥚 Tokens: 0"
tokensLabel.Parent = statsFrame

local eggsLabel = Instance.new("TextLabel")
eggsLabel.Name = "EggsLabel"
eggsLabel.Size = UDim2.new(1, -10, 0, 40)
eggsLabel.Position = UDim2.new(0, 5, 0, 95)
eggsLabel.BackgroundTransparency = 1
eggsLabel.Font = Enum.Font.SourceSansBold
eggsLabel.TextScaled = true
eggsLabel.TextColor3 = Color3.new(0.4, 1, 0.4)
eggsLabel.Text = "🐣 Eggs: 0"
eggsLabel.Parent = statsFrame

local particleContainer = Instance.new("Frame")
particleContainer.Name = "ParticleContainer"
particleContainer.Size = UDim2.new(1, 0, 1, 0)
particleContainer.BackgroundTransparency = 1
particleContainer.Parent = screenGui

local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.Size = UDim2.new(0, 150, 0, 50)
rebirthButton.Position = UDim2.new(1, -160, 0, 100)
rebirthButton.BackgroundColor3 = Color3.new(0.5, 0, 1)
rebirthButton.Text = "REBIRTH"
rebirthButton.TextScaled = true
rebirthButton.TextColor3 = Color3.new(1, 1, 1)
rebirthButton.Font = Enum.Font.SourceSansBold
rebirthButton.Parent = screenGui

local rebirthInfo = Instance.new("TextLabel")
rebirthInfo.Name = "RebirthInfo"
rebirthInfo.Size = UDim2.new(0, 150, 0, 30)
rebirthInfo.Position = UDim2.new(1, -160, 0, 155)
rebirthInfo.BackgroundTransparency = 1
rebirthInfo.Text = "Need: 0 tokens"
rebirthInfo.TextScaled = true
rebirthInfo.TextColor3 = Color3.new(1, 1, 1)
rebirthInfo.Font = Enum.Font.SourceSans
rebirthInfo.Parent = screenGui

local function updateTemperatureVisuals(temperature: Types.Temperature)
	local intensity = temperature.intensity or 0
	local heatType = temperature.heatType
	local distance = temperature.distance
	
	if not heatType then
		tempLabel.Text = "COLD"
		tempLabel.TextColor3 = Color3.new(0.5, 0.8, 1)
		tempBar.BackgroundColor3 = Color3.new(0.5, 0.8, 1)
		vignetteImage.ImageTransparency = 1
		overlayFrame.BackgroundTransparency = 1
		TweenService:Create(tempBar, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 1, -4)}):Play()
		return
	end
	
	local barWidth = intensity * 296
	TweenService:Create(tempBar, TweenInfo.new(0.3), {Size = UDim2.new(0, barWidth, 1, -4)}):Play()
	
	if distance > 75 then
		tempLabel.Text = "COOL"
		tempLabel.TextColor3 = Color3.new(0.5, 0.8, 1)
	elseif distance > 50 then
		tempLabel.Text = "WARM"
		tempLabel.TextColor3 = Color3.new(1, 1, 0.5)
	elseif distance > 25 then
		tempLabel.Text = "HOT"
		tempLabel.TextColor3 = Color3.new(1, 0.5, 0)
	elseif distance > 10 then
		tempLabel.Text = "VERY HOT!"
		tempLabel.TextColor3 = Color3.new(1, 0.3, 0)
	else
		tempLabel.Text = "BURNING!"
		tempLabel.TextColor3 = Color3.new(1, 0, 0)
	end
	
	if heatType == "good" then
		vignetteImage.ImageColor3 = Color3.new(1, 0.84, 0)
		overlayFrame.BackgroundColor3 = Color3.new(1, 0.84, 0)
		tempBar.BackgroundColor3 = Color3.new(1, 0.84, 0)
		
		if intensity > 0.3 then
			for i = 1, math.floor(intensity * 10) do
				local sparkle = Instance.new("Frame")
				sparkle.Size = UDim2.new(0, math.random(3, 6), 0, math.random(3, 6))
				sparkle.Position = UDim2.new(math.random(), 0, math.random(), 0)
				sparkle.BackgroundColor3 = Color3.fromHSV(0.15, 1 - (math.random() * 0.3), 1)
				sparkle.Rotation = math.random(0, 360)
				sparkle.Parent = particleContainer
				
				local glowEffect = Instance.new("UIGradient")
				glowEffect.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 0.8)),
					ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.9, 0.6)),
					ColorSequenceKeypoint.new(1, Color3.new(1, 0.8, 0.4))
				}
				glowEffect.Parent = sparkle
				
				TweenService:Create(sparkle, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {
					Position = UDim2.new(sparkle.Position.X.Scale, 0, sparkle.Position.Y.Scale - 0.15, 0),
					BackgroundTransparency = 1,
					Rotation = sparkle.Rotation + 180
				}):Play()
				
				game:GetService("Debris"):AddItem(sparkle, 1.5)
			end
		end
	elseif heatType == "bad" then
		vignetteImage.ImageColor3 = Color3.new(0.5, 0, 0)
		overlayFrame.BackgroundColor3 = Color3.new(0.5, 0, 0)
		tempBar.BackgroundColor3 = Color3.new(0.8, 0, 0)
		tempLabel.Text = "DANGER! " .. tempLabel.Text
		
		if intensity > 0.5 then
			local shake = Instance.new("BodyPosition")
			shake.MaxForce = Vector3.new(4000, 0, 4000)
			shake.Position = player.Character.HumanoidRootPart.Position
			shake.Parent = player.Character.HumanoidRootPart
			game:GetService("Debris"):AddItem(shake, 0.1)
		end
	elseif heatType == "egg" then
		vignetteImage.ImageColor3 = Color3.new(1, 0.71, 0.76)
		overlayFrame.BackgroundColor3 = Color3.new(1, 0.71, 0.76)
		tempBar.BackgroundColor3 = Color3.new(1, 0.71, 0.76)
		tempLabel.Text = "EGG! " .. tempLabel.Text
		
		for i = 1, 5 do
			local butterfly = Instance.new("ImageLabel")
			butterfly.Size = UDim2.new(0, 40, 0, 40)
			butterfly.Position = UDim2.new(math.random(), 0, math.random(), 0)
			butterfly.BackgroundTransparency = 1
			butterfly.Image = "rbxasset://textures/particles/sparkles_main.dds"
			butterfly.ImageColor3 = Color3.fromHSV(math.random(), 0.7, 1)
			butterfly.Rotation = math.random(-30, 30)
			butterfly.Parent = particleContainer
			
			local flutter = TweenService:Create(butterfly, 
				TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				Rotation = butterfly.Rotation + 20
			})
			flutter:Play()
			
			TweenService:Create(butterfly, TweenInfo.new(3, Enum.EasingStyle.Linear), {
				Position = UDim2.new(
					butterfly.Position.X.Scale + math.random(-0.3, 0.3), 0, 
					butterfly.Position.Y.Scale + math.random(-0.3, -0.1), 0
				),
				ImageTransparency = 1
			}):Play()
			
			game:GetService("Debris"):AddItem(butterfly, 3)
		end
		
		for i = 1, 3 do
			local petal = Instance.new("Frame")
			petal.Size = UDim2.new(0, 15, 0, 15)
			petal.Position = UDim2.new(0.5, 0, 0.5, 0)
			petal.BackgroundColor3 = Color3.fromHSV(math.random() * 0.3 + 0.8, 0.8, 1)
			petal.BorderSizePixel = 0
			petal.Parent = particleContainer
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = petal
			
			TweenService:Create(petal, TweenInfo.new(2), {
				Position = UDim2.new(math.random(), 0, 1, 0),
				Rotation = math.random(0, 720),
				BackgroundTransparency = 1
			}):Play()
			
			game:GetService("Debris"):AddItem(petal, 2)
		end
	end
	
	vignetteImage.ImageTransparency = 1 - (intensity * 0.5)
	overlayFrame.BackgroundTransparency = 1 - (intensity * 0.2)
end

local function handleCollectInput()
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local position = player.Character.HumanoidRootPart.Position
	
	for _, part in workspace:GetDescendants() do
		if part:IsA("BasePart") and CollectionService:HasTag(part, "HeatSource") then
			local distance = (part.Position - position).Magnitude
			if distance <= 10 then
				local sourceId = part:GetAttribute("SourceId")
				if sourceId then
					if CollectionService:HasTag(part, "good") then
						remotes.CollectTreasure:FireServer(sourceId)
					elseif CollectionService:HasTag(part, "egg") then
						remotes.CollectEgg:FireServer(sourceId)
					end
					break
				end
			end
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.E then
		handleCollectInput()
	end
end)

remotes.TemperatureUpdate.OnClientEvent:Connect(updateTemperatureVisuals)

remotes.UpdatePlayerData.OnClientEvent:Connect(function(playerData: Types.PlayerData)
	currentPlayerData = playerData
	moneyLabel.Text = "💰 Money: " .. tostring(playerData.money)
	tokensLabel.Text = "🥚 Tokens: " .. tostring(playerData.rebirthTokens)
	eggsLabel.Text = "🐣 Eggs: " .. tostring(playerData.eggsFound)
	
	local requiredTokens = 10
	if playerData.rebirthLevel == 1 then
		requiredTokens = 25
	elseif playerData.rebirthLevel == 2 then
		requiredTokens = 50
	elseif playerData.rebirthLevel == 3 then
		requiredTokens = 100
	elseif playerData.rebirthLevel >= 4 then
		requiredTokens = math.floor(100 * math.pow(1.5, playerData.rebirthLevel - 3))
	end
	
	rebirthInfo.Text = "Need: " .. requiredTokens .. " tokens"
	
	if playerData.rebirthTokens >= requiredTokens then
		rebirthButton.BackgroundColor3 = Color3.new(0, 1, 0)
		rebirthInfo.TextColor3 = Color3.new(0, 1, 0)
	else
		rebirthButton.BackgroundColor3 = Color3.new(0.5, 0, 1)
		rebirthInfo.TextColor3 = Color3.new(1, 1, 1)
	end
end)

rebirthButton.MouseButton1Click:Connect(function()
	remotes.Rebirth:FireServer()
end)

remotes.SpawnEffect.OnClientEvent:Connect(function(effectType: string, position: Vector3, value: number)
	if effectType == "moneyRain" then
		for i = 1, math.min(value / 10, 50) do
			wait(0.05)
			local bill = Instance.new("Part")
			bill.Name = "MoneyBill"
			bill.Size = Vector3.new(2, 0.1, 1)
			bill.Color = Color3.new(0, 1, 0)
			bill.Material = Enum.Material.Neon
			bill.TopSurface = Enum.SurfaceType.Smooth
			bill.BottomSurface = Enum.SurfaceType.Smooth
			bill.Position = position + Vector3.new(math.random(-5, 5), 10, math.random(-5, 5))
			bill.Parent = workspace
			
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = Vector3.new(math.random(-10, 10), -10, math.random(-10, 10))
			bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
			bodyVelocity.Parent = bill
			
			game:GetService("Debris"):AddItem(bill, 3)
		end
	elseif effectType == "eggCollect" then
		local eggModel = Instance.new("Part")
		eggModel.Name = "EggEffect"
		eggModel.Shape = Enum.PartType.Ball
		eggModel.Size = Vector3.new(2, 2, 2)
		eggModel.Color = Color3.new(1, 0.71, 0.76)
		eggModel.Material = Enum.Material.Neon
		eggModel.Position = position
		eggModel.Anchored = true
		eggModel.CanCollide = false
		eggModel.Parent = workspace
		
		TweenService:Create(eggModel, TweenInfo.new(1), {
			Size = Vector3.new(6, 6, 6),
			Transparency = 1
		}):Play()
		
		game:GetService("Debris"):AddItem(eggModel, 1)
	end
end)