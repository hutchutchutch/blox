# Heat Seeker - Full Game Setup

## 🚀 Quickest Setup Method

### Step 1: Create Game Structure
1. Open Roblox Studio
2. Create new Baseplate game
3. In Explorer, create this exact structure:

```
ServerScriptService/
├── Main (Script)
├── GrasslandSetup (Script)
├── Types (ModuleScript)
├── RewardSystem (ModuleScript)
└── RebirthSystem (ModuleScript)

StarterPlayer/
└── StarterPlayerScripts/
    ├── ClientMain (LocalScript)
    ├── MovementController (LocalScript)
    └── MusicSystem (LocalScript)

ReplicatedStorage/
└── Types (ModuleScript)
```

### Step 2: Copy Scripts

Copy each script below into the corresponding script in Studio:

---

## 📄 SERVER SCRIPTS

### Main (Script in ServerScriptService)
```lua
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

local heatSources: {Types.HeatSource} = {}
local predators: {Types.Predator} = {}
local activePlayers: {[Player]: Types.PlayerData} = {}

local function createRemotes()
	local remotes = Instance.new("Folder")
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
		local remote = Instance.new("RemoteEvent")
		remote.Name = eventName
		remote.Parent = remotes
	end
	
	return remotes
end

local function createLeaderstats(player: Player)
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

local function loadPlayerData(player: Player): Types.PlayerData
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

local function savePlayerData(player: Player)
	local data = activePlayers[player]
	if data then
		pcall(function()
			playerDataStore:SetAsync(tostring(player.UserId), data)
		end)
	end
end

local function createHeatSource(position: Vector3, heatType: Types.HeatType, value: number): Types.HeatSource
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
		
		local source: Types.HeatSource = {
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

local function getGroundHeight(x: number, z: number): number
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

local function calculateTemperature(playerPosition: Vector3): Types.Temperature
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

local function updatePlayerStats(player: Player, data: Types.PlayerData)
	if player:FindFirstChild("leaderstats") then
		player.leaderstats.Money.Value = data.money
		player.leaderstats.Rebirth.Value = data.rebirthLevel
		player.leaderstats.Eggs.Value = data.eggsFound
	end
end

local function handlePlayerJoin(player: Player)
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

local function handlePlayerLeave(player: Player)
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

remotes.CollectTreasure:Connect(function(player: Player, sourceId: string)
	local data = activePlayers[player]
	if not data then return end
	
	for i, source in heatSources do
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

remotes.CollectEgg:Connect(function(player: Player, sourceId: string)
	local data = activePlayers[player]
	if not data then return end
	
	for i, source in heatSources do
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

remotes.Rebirth.OnServerEvent:Connect(function(player: Player)
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
```

### GrasslandSetup (Script in ServerScriptService)
```lua
local Lighting = game:GetService("Lighting")
local Terrain = workspace:WaitForChild("Terrain")
local RunService = game:GetService("RunService")

local GRASSLAND_SIZE = Vector3.new(500, 1, 500)
local HILL_COUNT = 8
local TREE_COUNT = 50
local ROCK_COUNT = 30
local FLOWER_COUNT = 100

local function setupLighting()
	Lighting.Ambient = Color3.fromRGB(140, 140, 140)
	Lighting.Brightness = 1.2
	Lighting.ColorShift_Bottom = Color3.fromRGB(70, 100, 150)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 240, 200)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.GlobalShadows = true
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 170, 190)
	Lighting.ShadowSoftness = 0.2
	Lighting.ClockTime = 14
	Lighting.GeographicLatitude = 45
	
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(199, 199, 199)
	atmosphere.Decay = Color3.fromRGB(106, 112, 125)
	atmosphere.Glare = 0
	atmosphere.Haze = 0
	atmosphere.Parent = Lighting
	
	local skybox = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
	skybox.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
	skybox.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
	skybox.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
	skybox.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
	skybox.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
	skybox.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
	skybox.Parent = Lighting
end

local function createTerrain()
	local region = Region3.new(
		Vector3.new(-GRASSLAND_SIZE.X/2, -20, -GRASSLAND_SIZE.Z/2),
		Vector3.new(GRASSLAND_SIZE.X/2, 0, GRASSLAND_SIZE.Z/2)
	)
	region = region:ExpandToGrid(4)
	
	Terrain:FillBlock(
		CFrame.new(0, -10, 0),
		Vector3.new(GRASSLAND_SIZE.X, 20, GRASSLAND_SIZE.Z),
		Enum.Material.Grass
	)
	
	for i = 1, HILL_COUNT do
		local hillPos = Vector3.new(
			math.random(-GRASSLAND_SIZE.X/2, GRASSLAND_SIZE.X/2),
			math.random(5, 15),
			math.random(-GRASSLAND_SIZE.Z/2, GRASSLAND_SIZE.Z/2)
		)
		local hillSize = math.random(30, 60)
		
		Terrain:FillBall(hillPos, hillSize, Enum.Material.Grass)
		
		if math.random() > 0.7 then
			Terrain:FillBall(
				hillPos + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20)),
				hillSize * 0.7,
				Enum.Material.LeafyGrass
			)
		end
	end
end

local function createTree(position: Vector3)
	local tree = Instance.new("Model")
	tree.Name = "Tree"
	
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(3, 12, 3)
	trunk.Position = position + Vector3.new(0, 6, 0)
	trunk.BrickColor = BrickColor.new("Brown")
	trunk.Material = Enum.Material.Wood
	trunk.Anchored = true
	trunk.Parent = tree
	
	local leaves = Instance.new("Part")
	leaves.Name = "Leaves"
	leaves.Shape = Enum.PartType.Ball
	leaves.Size = Vector3.new(15, 15, 15)
	leaves.Position = position + Vector3.new(0, 15, 0)
	leaves.BrickColor = BrickColor.new("Bright green")
	leaves.Material = Enum.Material.Grass
	leaves.TopSurface = Enum.SurfaceType.Smooth
	leaves.BottomSurface = Enum.SurfaceType.Smooth
	leaves.Anchored = true
	leaves.Parent = tree
	
	tree.Parent = workspace
	return tree
end

local function createRock(position: Vector3)
	local rock = Instance.new("Part")
	rock.Name = "Rock"
	rock.Size = Vector3.new(
		math.random(2, 6),
		math.random(2, 4),
		math.random(2, 6)
	)
	rock.Position = position + Vector3.new(0, rock.Size.Y/2, 0)
	rock.BrickColor = BrickColor.new("Medium stone grey")
	rock.Material = Enum.Material.Slate
	rock.TopSurface = Enum.SurfaceType.Smooth
	rock.BottomSurface = Enum.SurfaceType.Smooth
	rock.Anchored = true
	rock.Parent = workspace
	
	rock.CFrame = rock.CFrame * CFrame.Angles(
		math.rad(math.random(-20, 20)),
		math.rad(math.random(0, 360)),
		math.rad(math.random(-20, 20))
	)
	
	return rock
end

local function createFlower(position: Vector3)
	local flower = Instance.new("Model")
	flower.Name = "Flower"
	
	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Size = Vector3.new(0.2, 1, 0.2)
	stem.Position = position + Vector3.new(0, 0.5, 0)
	stem.BrickColor = BrickColor.new("Bright green")
	stem.Material = Enum.Material.Grass
	stem.Anchored = true
	stem.Parent = flower
	
	local petals = Instance.new("Part")
	petals.Name = "Petals"
	petals.Shape = Enum.PartType.Cylinder
	petals.Size = Vector3.new(0.1, 1, 1)
	petals.Position = position + Vector3.new(0, 1, 0)
	petals.BrickColor = BrickColor.Random()
	petals.Material = Enum.Material.Neon
	petals.Anchored = true
	petals.Parent = flower
	
	petals.CFrame = petals.CFrame * CFrame.Angles(0, 0, math.rad(90))
	
	flower.Parent = workspace
	return flower
end

local function getGroundHeight(x: number, z: number): number
	local ray = workspace:Raycast(
		Vector3.new(x, 100, z),
		Vector3.new(0, -200, 0)
	)
	
	if ray then
		return ray.Position.Y
	end
	return 0
end

local function populateGrassland()
	local decorFolder = Instance.new("Folder")
	decorFolder.Name = "GrasslandDecoration"
	decorFolder.Parent = workspace
	
	for i = 1, TREE_COUNT do
		local x = math.random(-GRASSLAND_SIZE.X/3, GRASSLAND_SIZE.X/3)
		local z = math.random(-GRASSLAND_SIZE.Z/3, GRASSLAND_SIZE.Z/3)
		local y = getGroundHeight(x, z)
		
		createTree(Vector3.new(x, y, z))
	end
	
	for i = 1, ROCK_COUNT do
		local x = math.random(-GRASSLAND_SIZE.X/2, GRASSLAND_SIZE.X/2)
		local z = math.random(-GRASSLAND_SIZE.Z/2, GRASSLAND_SIZE.Z/2)
		local y = getGroundHeight(x, z)
		
		createRock(Vector3.new(x, y, z))
	end
	
	for i = 1, FLOWER_COUNT do
		local x = math.random(-GRASSLAND_SIZE.X/2, GRASSLAND_SIZE.X/2)
		local z = math.random(-GRASSLAND_SIZE.Z/2, GRASSLAND_SIZE.Z/2)
		local y = getGroundHeight(x, z)
		
		createFlower(Vector3.new(x, y, z))
	end
end

local function createSpawnArea()
	local spawn = workspace:FindFirstChild("SpawnLocation") or Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, getGroundHeight(0, 0) + 0.5, 0)
	spawn.BrickColor = BrickColor.new("Bright green")
	spawn.Material = Enum.Material.Grass
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Parent = workspace
	
	local spawnDecor = Instance.new("Part")
	spawnDecor.Name = "SpawnDecoration"
	spawnDecor.Shape = Enum.PartType.Cylinder
	spawnDecor.Size = Vector3.new(0.2, 12, 12)
	spawnDecor.Position = spawn.Position - Vector3.new(0, 0.4, 0)
	spawnDecor.BrickColor = BrickColor.new("Bright yellow")
	spawnDecor.Material = Enum.Material.Neon
	spawnDecor.Transparency = 0.5
	spawnDecor.Anchored = true
	spawnDecor.CanCollide = false
	spawnDecor.Parent = workspace
	
	spawnDecor.CFrame = spawnDecor.CFrame * CFrame.Angles(0, 0, math.rad(90))
end

local function createBoundaryFence()
	local fence = Instance.new("Model")
	fence.Name = "Boundary"
	fence.Parent = workspace
	
	local fenceHeight = 10
	local postSpacing = 20
	
	local function createFenceSection(startPos: Vector3, endPos: Vector3)
		local distance = (endPos - startPos).Magnitude
		local direction = (endPos - startPos).Unit
		local postCount = math.floor(distance / postSpacing)
		
		for i = 0, postCount do
			local postPos = startPos + direction * (i * postSpacing)
			local y = getGroundHeight(postPos.X, postPos.Z)
			
			local post = Instance.new("Part")
			post.Name = "FencePost"
			post.Size = Vector3.new(1, fenceHeight, 1)
			post.Position = Vector3.new(postPos.X, y + fenceHeight/2, postPos.Z)
			post.BrickColor = BrickColor.new("Brown")
			post.Material = Enum.Material.Wood
			post.Anchored = true
			post.Parent = fence
		end
	end
	
	local halfX = GRASSLAND_SIZE.X/2 - 10
	local halfZ = GRASSLAND_SIZE.Z/2 - 10
	
	createFenceSection(Vector3.new(-halfX, 0, -halfZ), Vector3.new(halfX, 0, -halfZ))
	createFenceSection(Vector3.new(halfX, 0, -halfZ), Vector3.new(halfX, 0, halfZ))
	createFenceSection(Vector3.new(halfX, 0, halfZ), Vector3.new(-halfX, 0, halfZ))
	createFenceSection(Vector3.new(-halfX, 0, halfZ), Vector3.new(-halfX, 0, -halfZ))
end

local function clearOldTerrain()
	for _, obj in workspace:GetChildren() do
		if obj:IsA("Part") and obj.Name == "Baseplate" then
			obj:Destroy()
		end
	end
end

clearOldTerrain()
createTerrain()
setupLighting()
wait(1)
populateGrassland()
createSpawnArea()
createBoundaryFence()

print("Grassland scene setup complete!")
```

### Types (ModuleScript in ServerScriptService AND ReplicatedStorage)
```lua
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
```

### RewardSystem (ModuleScript in ServerScriptService)
[Character limit reached - see separate file for this script]

### RebirthSystem (ModuleScript in ServerScriptService)
[Character limit reached - see separate file for this script]

---

## 📄 CLIENT SCRIPTS

### ClientMain (LocalScript in StarterPlayerScripts)
[Character limit reached - see separate file for this script]

### MovementController (LocalScript in StarterPlayerScripts)
[Character limit reached - see separate file for this script]

### MusicSystem (LocalScript in StarterPlayerScripts)
[Character limit reached - see separate file for this script]

---

## 🎮 Final Steps

1. After copying all scripts, press F5 to play
2. The grassland will generate automatically
3. Heat sources will spawn after 2-3 seconds
4. Start exploring!

## 🔧 Quick Fixes

If something doesn't work:
- Check Output window for errors (View → Output)
- Make sure all scripts are in correct locations
- Ensure script types match (Script vs LocalScript vs ModuleScript)
- Try stopping and restarting the game

Enjoy playing Heat Seeker! 🔥❄️
```

*Note: Due to character limits, I've indicated where the full scripts would go. The actual scripts are in the individual files in the plugin/src folder.*