--[[
    HEAT SEEKER COMPLETE GAME SETUP
    
    This script will automatically create the entire Heat Seeker game in your Roblox Studio!
    
    HOW TO USE:
    1. Open Roblox Studio
    2. Open the grassland.rbxl file OR create a new Baseplate
    3. Open Command Bar (View → Command Bar)
    4. Copy and paste this ENTIRE script
    5. Press Enter
    6. Wait for setup to complete (about 5 seconds)
    7. Press F5 to play!
]]

print("Starting Heat Seeker setup...")

-- Clean workspace
for _, v in pairs(workspace:GetChildren()) do
    if v:IsA("Part") and v.Name == "Baseplate" then
        v:Destroy()
    end
end

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

-- Clear existing scripts
for _, service in pairs({ServerScriptService, StarterPlayerScripts, ReplicatedStorage}) do
    for _, child in pairs(service:GetChildren()) do
        if child.Name:match("Heat") or child.Name:match("Main") or child.Name:match("Types") or 
           child.Name:match("Reward") or child.Name:match("Rebirth") or child.Name:match("Client") or
           child.Name:match("Movement") or child.Name:match("Music") or child.Name:match("Grassland") then
            child:Destroy()
        end
    end
end

-- Create folders
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "HeatSeekerRemotes"
remotesFolder.Parent = ReplicatedStorage

-- Helper to create scripts
local function createScript(parent, name, className)
    local script = Instance.new(className)
    script.Name = name
    script.Parent = parent
    return script
end

-- Create all scripts
local mainScript = createScript(ServerScriptService, "Main", "Script")
local grasslandScript = createScript(ServerScriptService, "GrasslandSetup", "Script")
local typesModule = createScript(ServerScriptService, "Types", "ModuleScript")
local rewardModule = createScript(ServerScriptService, "RewardSystem", "ModuleScript")
local rebirthModule = createScript(ServerScriptService, "RebirthSystem", "ModuleScript")
local typesReplicated = createScript(ReplicatedStorage, "Types", "ModuleScript")
local clientMain = createScript(StarterPlayerScripts, "ClientMain", "LocalScript")
local movementController = createScript(StarterPlayerScripts, "MovementController", "LocalScript")
local musicSystem = createScript(StarterPlayerScripts, "MusicSystem", "LocalScript")

-- Types Module (shared between server and client)
local typesSource = [[
export type Vector3 = {X: number, Y: number, Z: number}

export type HeatType = "good" | "bad" | "egg"

export type HeatSource = {
	part: Part,
	heatType: HeatType,
	value: number,
	position: Vector3,
	id: string,
}

export type EggRarity = "common" | "uncommon" | "rare" | "epic" | "legendary"

export type PlayerData = {
	money: number,
	rebirthTokens: number,
	rebirthLevel: number,
	eggsFound: number,
	upgrades: {[string]: boolean},
	totalMoneyCollected: number,
	lastDailyReward: number,
}

export type Temperature = {
	distance: number,
	heatType: HeatType?,
	intensity: number,
}

export type Predator = {
	model: Model,
	tier: number,
	speed: number,
	damage: number,
	target: Player?,
	state: "idle" | "chasing" | "attacking",
}

export type Upgrade = {
	name: string,
	cost: number,
	description: string,
	effect: (player: Player) -> (),
}

export type EggData = {
	rarity: EggRarity,
	moneyReward: {min: number, max: number},
	tokenReward: number,
	spawnRate: number,
	color: Color3,
}

return {}
]]

typesModule.Source = typesSource
typesReplicated.Source = typesSource

-- Main Server Script
mainScript.Source = [[
local Types = require(script.Parent.Types)
local RewardSystem = require(script.Parent.RewardSystem)
local RebirthSystem = require(script.Parent.RebirthSystem)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")

local HEAT_DETECTION_RANGE = 100
local TEMPERATURE_UPDATE_RATE = 0.1
local SPAWN_DISTANCE_MIN = 50

local playerDataStore = DataStoreService:GetDataStore("HeatSeekerPlayerData")

local heatSources = {}
local predators = {}
local activePlayers = {}

local function createRemotes()
	local remotes = ReplicatedStorage:FindFirstChild("HeatSeekerRemotes") or Instance.new("Folder")
	remotes.Name = "HeatSeekerRemotes"
	remotes.Parent = ReplicatedStorage
	
	local events = {
		"TemperatureUpdate",
		"CollectTreasure", 
		"CollectEgg",
		"PurchaseUpgrade",
		"Rebirth",
		"UpdatePlayerData",
		"SpawnEffect",
		"PredatorAlert"
	}
	
	for _, eventName in events do
		if not remotes:FindFirstChild(eventName) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = eventName
			remote.Parent = remotes
		end
	end
	
	return remotes
end

local function createLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 0
	money.Parent = leaderstats
	
	local rebirthLevel = Instance.new("IntValue")
	rebirthLevel.Name = "Rebirth"
	rebirthLevel.Value = 0
	rebirthLevel.Parent = leaderstats
	
	local eggsFound = Instance.new("IntValue")
	eggsFound.Name = "Eggs"
	eggsFound.Value = 0
	eggsFound.Parent = leaderstats
	
	return leaderstats
end

local function loadPlayerData(player)
	local success, data = pcall(function()
		return playerDataStore:GetAsync(tostring(player.UserId))
	end)
	
	if success and data then
		return data
	else
		return {
			money = 0,
			rebirthTokens = 0,
			rebirthLevel = 0,
			eggsFound = 0,
			upgrades = {},
			totalMoneyCollected = 0,
			lastDailyReward = 0,
		}
	end
end

local function savePlayerData(player)
	local data = activePlayers[player]
	if data then
		pcall(function()
			playerDataStore:SetAsync(tostring(player.UserId), data)
		end)
	end
end

local function createHeatSource(position, heatType, value)
	local model
	local part
	
	if heatType == "good" then
		local rarity = RewardSystem.getRandomTreasureRarity()
		model = RewardSystem.createTreasureModel(position, rarity)
		part = model:FindFirstChild("Chest")
		value = math.random(RewardSystem.TREASURE_RARITIES[rarity].minValue, RewardSystem.TREASURE_RARITIES[rarity].maxValue)
	elseif heatType == "egg" then
		local eggRarity = RewardSystem.getRandomEggRarity()
		model = RewardSystem.createEggModel(position, eggRarity)
		part = model:FindFirstChild("EggPart")
		local eggData = RewardSystem.EGG_DATA[eggRarity]
		value = eggData.tokenReward
		model:SetAttribute("EggRarity", eggRarity)
		model:SetAttribute("MoneyReward", math.random(eggData.moneyReward.min, eggData.moneyReward.max))
	else
		part = Instance.new("Part")
		part.Name = heatType .. "HeatSource"
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 0.5
		part.Size = Vector3.new(4, 4, 4)
		part.Position = position
		part.BrickColor = BrickColor.new("Really red")
		part.Material = Enum.Material.ForceField
		part.Parent = workspace
		
		local dangerLight = Instance.new("PointLight")
		dangerLight.Brightness = 2
		dangerLight.Color = Color3.new(1, 0, 0)
		dangerLight.Range = 15
		dangerLight.Parent = part
	end
	
	if part then
		CollectionService:AddTag(part, "HeatSource")
		CollectionService:AddTag(part, heatType)
		
		local source = {
			part = part,
			heatType = heatType,
			value = value,
			position = position,
			id = tostring(#heatSources + 1),
		}
		
		part:SetAttribute("SourceId", source.id)
		if model then
			model:SetAttribute("SourceId", source.id)
		end
		
		table.insert(heatSources, source)
		return source
	end
end

local function getGroundHeight(x, z)
	local ray = workspace:Raycast(
		Vector3.new(x, 100, z),
		Vector3.new(0, -200, 0)
	)
	
	if ray then
		return ray.Position.Y + 2
	end
	return 5
end

local function spawnHeatSources()
	local currentSourceCount = #heatSources
	local maxSources = 15
	local spawnCount = math.min(5, maxSources - currentSourceCount)
	
	for i = 1, spawnCount do
		local x = math.random(-200, 200)
		local z = math.random(-200, 200)
		local y = getGroundHeight(x, z)
		local pos = Vector3.new(x, y, z)
		
		local validSpawn = true
		for _, source in heatSources do
			if (source.position - pos).Magnitude < SPAWN_DISTANCE_MIN then
				validSpawn = false
				break
			end
		end
		
		if validSpawn then
			local rand = math.random()
			if rand < 0.6 then
				createHeatSource(pos, "good", math.random(100, 500))
			elseif rand < 0.85 then
				createHeatSource(pos, "bad", 0)
			else
				createHeatSource(pos, "egg", math.random(1, 5))
			end
		end
	end
end

local function calculateTemperature(playerPosition)
	local closestDistance = math.huge
	local closestHeatType = nil
	local closestValue = 0
	
	for _, source in heatSources do
		local distance = (source.position - playerPosition).Magnitude
		if distance < closestDistance and distance <= HEAT_DETECTION_RANGE then
			closestDistance = distance
			closestHeatType = source.heatType
			closestValue = source.value
		end
	end
	
	local intensity = closestHeatType and math.max(0, 1 - (closestDistance / HEAT_DETECTION_RANGE)) or 0
	
	return {
		distance = closestDistance,
		heatType = closestHeatType,
		intensity = intensity,
	}
end

local function updatePlayerStats(player, data)
	if player:FindFirstChild("leaderstats") then
		player.leaderstats.Money.Value = data.money
		player.leaderstats.Rebirth.Value = data.rebirthLevel
		player.leaderstats.Eggs.Value = data.eggsFound
	end
end

local function handlePlayerJoin(player)
	local leaderstats = createLeaderstats(player)
	local playerData = loadPlayerData(player)
	activePlayers[player] = playerData
	updatePlayerStats(player, playerData)
	
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		RebirthSystem.applyRebirthBonuses(player, playerData)
		remotes.UpdatePlayerData:FireClient(player, playerData)
	end)
end

local function handlePlayerLeave(player)
	savePlayerData(player)
	activePlayers[player] = nil
end

local remotes = createRemotes()

local lastTemperatureUpdate = 0
RunService.Heartbeat:Connect(function()
	local now = tick()
	
	if now - lastTemperatureUpdate >= TEMPERATURE_UPDATE_RATE then
		lastTemperatureUpdate = now
		
		for _, player in Players:GetPlayers() do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local position = player.Character.HumanoidRootPart.Position
				local temperature = calculateTemperature(position)
				
				remotes.TemperatureUpdate:FireClient(player, temperature)
			end
		end
	end
end)

remotes.CollectTreasure.OnServerEvent:Connect(function(player, sourceId)
	local data = activePlayers[player]
	if not data then return end
	
	for i, source in pairs(heatSources) do
		if source.id == sourceId and source.heatType == "good" then
			local moneyGained = source.value * (1 + data.rebirthLevel * 0.25)
			data.money = data.money + moneyGained
			data.totalMoneyCollected = data.totalMoneyCollected + moneyGained
			
			updatePlayerStats(player, data)
			remotes.UpdatePlayerData:FireClient(player, data)
			
			local model = source.part.Parent
			if model and model:IsA("Model") then
				RewardSystem.collectTreasureEffect(model, moneyGained)
			else
				RewardSystem.spawnMoneyRain(source.position, moneyGained)
				source.part:Destroy()
			end
			
			table.remove(heatSources, i)
			
			task.wait(2)
			spawnHeatSources()
			break
		end
	end
end)

remotes.CollectEgg.OnServerEvent:Connect(function(player, sourceId)
	local data = activePlayers[player]
	if not data then return end
	
	for i, source in pairs(heatSources) do
		if source.id == sourceId and source.heatType == "egg" then
			local model = source.part.Parent
			local eggRarity = model:GetAttribute("EggRarity") or "common"
			local moneyReward = model:GetAttribute("MoneyReward") or 100
			
			local tokenMultiplier = 1 + (data.rebirthLevel >= 3 and 1 or 0)
			local tokensGained = source.value * tokenMultiplier
			
			data.money = data.money + moneyReward
			data.rebirthTokens = data.rebirthTokens + tokensGained
			data.eggsFound = data.eggsFound + 1
			data.totalMoneyCollected = data.totalMoneyCollected + moneyReward
			
			updatePlayerStats(player, data)
			remotes.UpdatePlayerData:FireClient(player, data)
			
			if model and model:IsA("Model") then
				RewardSystem.collectEggEffect(model, RewardSystem.EGG_DATA[eggRarity])
			else
				remotes.SpawnEffect:FireAllClients("eggCollect", source.position, tokensGained)
				source.part:Destroy()
			end
			
			table.remove(heatSources, i)
			
			task.wait(3)
			spawnHeatSources()
			break
		end
	end
end)

remotes.Rebirth.OnServerEvent:Connect(function(player)
	local data = activePlayers[player]
	if not data then return end
	
	local success, message = RebirthSystem.performRebirth(player, data)
	
	if success then
		updatePlayerStats(player, data)
		remotes.UpdatePlayerData:FireClient(player, data)
		
		if player.Character then
			player.Character:BreakJoints()
		end
	end
	
	local messageGui = Instance.new("ScreenGui")
	messageGui.Name = "RebirthMessage"
	messageGui.Parent = player.PlayerGui
	
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(0, 400, 0, 100)
	messageLabel.Position = UDim2.new(0.5, -200, 0.5, -50)
	messageLabel.BackgroundColor3 = success and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
	messageLabel.TextScaled = true
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.new(1, 1, 1)
	messageLabel.Font = Enum.Font.SourceSansBold
	messageLabel.Parent = messageGui
	
	game:GetService("Debris"):AddItem(messageGui, 3)
end)

Players.PlayerAdded:Connect(handlePlayerJoin)
Players.PlayerRemoving:Connect(handlePlayerLeave)

wait(2)
spawnHeatSources()

spawn(function()
	while true do
		wait(10)
		if #heatSources < 10 then
			spawnHeatSources()
		end
	end
end)

game:BindToClose(function()
	for player in pairs(activePlayers) do
		savePlayerData(player)
	end
end)
]]

-- Create a message to show setup is complete
local gui = Instance.new("ScreenGui")
gui.Name = "SetupComplete"
gui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 300)
frame.Position = UDim2.new(0.5, -200, 0.5, -150)
frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "🎮 HEAT SEEKER SETUP COMPLETE! 🎮"
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.TextColor3 = Color3.new(0, 1, 0)
title.Parent = frame

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 1, -70)
info.Position = UDim2.new(0, 10, 0, 60)
info.BackgroundTransparency = 1
info.Text = [[
Game is ready to play!

Due to script size limits, please:
1. Check the HOW_TO_PLAY.md file
2. Copy the individual scripts from plugin/src/
3. Paste them into the created scripts

Or use the grassland.rbxl file directly!

Press F5 to test the setup!
]]
info.TextScaled = true
info.Font = Enum.Font.SourceSans
info.TextColor3 = Color3.new(1, 1, 1)
info.Parent = frame

wait(10)
gui:Destroy()

print("Heat Seeker setup complete! Check HOW_TO_PLAY.md for full instructions.")