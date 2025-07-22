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
local ROUND_TIME = 120
local OBJECTS_TO_COLLECT = 5
local DOG_COUNT = 10
local DOG_SPEED = 20
local DROPOFF_RADIUS = 15
local FIREBALL_SPAWN_INTERVAL = 0.5
local FIREBALL_DAMAGE = 20
local EGG_SPAWN_COUNT = 50
local EGG_THROW_SPEED = 50
local EGG_THROW_DAMAGE = 30

local playerDataStore = DataStoreService:GetDataStore("HeatSeekerPlayerData")

local heatSources: {Types.HeatSource} = {}
local predators: {Types.Predator} = {}
local activePlayers: {[Player]: Types.PlayerData} = {}
local collectibleObjects: {Types.CollectibleObject} = {}
local dogs: {Types.Dog} = {}
local eggs: {[string]: Part} = {}
local playerHeldEggs: {[Player]: Part} = {}
local gameState: Types.GameState = {
	timeRemaining = ROUND_TIME,
	objectsCollected = 0,
	objectsRequired = OBJECTS_TO_COLLECT,
	dogsSpawned = false,
	roundActive = false
}
local dropOffZone: Part?

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
		"PredatorAlert",
		"PickupObject",
		"DropObject",
		"UpdateGameState",
		"StartRound",
		"PickupEgg",
		"ThrowEgg"
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
	
	local egg = playerHeldEggs[player]
	if egg and egg.Parent then
		for _, weld in egg:GetChildren() do
			if weld:IsA("WeldConstraint") then
				weld:Destroy()
			end
		end
		
		local float = Instance.new("BodyPosition")
		float.MaxForce = Vector3.new(0, 4000, 0)
		float.Position = egg.Position
		float.Parent = egg
		
		local spin = Instance.new("BodyAngularVelocity")
		spin.AngularVelocity = Vector3.new(0, 3, 0)
		spin.MaxTorque = Vector3.new(0, 4000, 0)
		spin.Parent = egg
	end
	
	playerHeldEggs[player] = nil
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

local function createDropOffZone()
	if dropOffZone then dropOffZone:Destroy() end
	
	dropOffZone = Instance.new("Part")
	dropOffZone.Name = "DropOffZone"
	dropOffZone.Anchored = true
	dropOffZone.CanCollide = false
	dropOffZone.Size = Vector3.new(DROPOFF_RADIUS * 2, 0.2, DROPOFF_RADIUS * 2)
	dropOffZone.Position = Vector3.new(0, getGroundHeight(0, 0), 0)
	dropOffZone.BrickColor = BrickColor.new("Lime green")
	dropOffZone.Material = Enum.Material.Neon
	dropOffZone.Transparency = 0.5
	dropOffZone.Parent = workspace
	
	local cylinder = Instance.new("CylinderMesh")
	cylinder.Parent = dropOffZone
	
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Color = Color3.new(0, 1, 0)
	light.Range = 20
	light.Parent = dropOffZone
	
	local beam = Instance.new("Part")
	beam.Name = "DropOffBeam"
	beam.Anchored = true
	beam.CanCollide = false
	beam.Size = Vector3.new(4, 100, 4)
	beam.Position = dropOffZone.Position + Vector3.new(0, 50, 0)
	beam.BrickColor = BrickColor.new("Lime green")
	beam.Material = Enum.Material.ForceField
	beam.Transparency = 0.8
	beam.Parent = workspace
end

local function createCollectibleObject(position: Vector3): Types.CollectibleObject
	local part = Instance.new("Part")
	part.Name = "CollectibleObject"
	part.Size = Vector3.new(2, 2, 2)
	part.Position = position
	part.BrickColor = BrickColor.new("Bright yellow")
	part.Material = Enum.Material.Neon
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = workspace
	
	local box = Instance.new("SelectionBox")
	box.Adornee = part
	box.Color3 = Color3.new(1, 1, 0)
	box.LineThickness = 0.1
	box.Parent = part
	
	local light = Instance.new("PointLight")
	light.Brightness = 1
	light.Color = Color3.new(1, 1, 0)
	light.Range = 10
	light.Parent = part
	
	local float = Instance.new("BodyPosition")
	float.MaxForce = Vector3.new(0, 4000, 0)
	float.Position = position + Vector3.new(0, 1, 0)
	float.Parent = part
	
	local spin = Instance.new("BodyAngularVelocity")
	spin.AngularVelocity = Vector3.new(0, 5, 0)
	spin.MaxTorque = Vector3.new(0, 4000, 0)
	spin.Parent = part
	
	CollectionService:AddTag(part, "CollectibleObject")
	
	local object: Types.CollectibleObject = {
		part = part,
		id = tostring(#collectibleObjects + 1),
		position = position,
		value = 100,
		isCarried = false,
		carriedBy = nil
	}
	
	part:SetAttribute("ObjectId", object.id)
	table.insert(collectibleObjects, object)
	
	return object
end

local function spawnCollectibleObjects()
	for i = 1, OBJECTS_TO_COLLECT do
		local x = math.random(-150, 150)
		local z = math.random(-150, 150)
		local y = getGroundHeight(x, z) + 2
		createCollectibleObject(Vector3.new(x, y, z))
	end
end

local function createDog(position: Vector3): Types.Dog
	local model = Instance.new("Model")
	model.Name = "Dog"
	
	local body = Instance.new("Part")
	body.Name = "HumanoidRootPart"
	body.Size = Vector3.new(4, 2, 6)
	body.Position = position
	body.BrickColor = BrickColor.new("Really black")
	body.Material = Enum.Material.Neon
	body.Parent = model
	
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(3, 2, 3)
	head.Position = position + Vector3.new(0, 1, -2)
	head.BrickColor = BrickColor.new("Really black")
	head.Material = Enum.Material.Neon
	head.Parent = model
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = head
	weld.Parent = body
	
	local eye1 = Instance.new("PointLight")
	eye1.Brightness = 3
	eye1.Color = Color3.new(1, 0, 0)
	eye1.Range = 15
	eye1.Parent = head
	
	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = DOG_SPEED
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.Parent = model
	
	model.PrimaryPart = body
	model.Parent = workspace
	
	local dog: Types.Dog = {
		model = model,
		humanoid = humanoid,
		target = nil,
		speed = DOG_SPEED
	}
	
	table.insert(dogs, dog)
	return dog
end

local function spawnDogSwarm(targetPlayer: Player?)
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		local distance = 30
		local x = math.cos(angle) * distance
		local z = math.sin(angle) * distance
		
		if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
			x = x + targetPlayer.Character.HumanoidRootPart.Position.X
			z = z + targetPlayer.Character.HumanoidRootPart.Position.Z
		end
		
		local y = getGroundHeight(x, z) + 2
		local dog = createDog(Vector3.new(x, y, z))
		if targetPlayer then
			dog.target = targetPlayer
		end
	end
	
	for _, player in Players:GetPlayers() do
		remotes.PredatorAlert:FireClient(player, "DOGS ARE SWARMING!")
	end
end

local function updateDogs()
	for _, dog in dogs do
		if dog.model and dog.model.Parent and dog.humanoid.Health > 0 then
			local closestPlayer = nil
			local closestDistance = math.huge
			
			for _, player in Players:GetPlayers() do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local distance = (dog.model.PrimaryPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
					if distance < closestDistance then
						closestDistance = distance
						closestPlayer = player
					end
				end
			end
			
			if closestPlayer and closestPlayer.Character then
				dog.humanoid:MoveTo(closestPlayer.Character.HumanoidRootPart.Position)
				
				if closestDistance < 5 then
					local humanoid = closestPlayer.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:TakeDamage(10)
					end
				end
			end
		end
	end
end

local function cleanupRound()
	for _, object in collectibleObjects do
		if object.part and object.part.Parent then
			object.part:Destroy()
		end
	end
	collectibleObjects = {}
	
	for _, dog in dogs do
		if dog.model and dog.model.Parent then
			dog.model:Destroy()
		end
	end
	dogs = {}
	
	gameState.dogsSpawned = false
	gameState.objectsCollected = 0
	gameState.timeRemaining = ROUND_TIME
end

local function startNewRound()
	cleanupRound()
	createDropOffZone()
	spawnCollectibleObjects()
	
	gameState.roundActive = true
	gameState.timeRemaining = ROUND_TIME
	
	for _, player in Players:GetPlayers() do
		remotes.UpdateGameState:FireClient(player, gameState)
	end
	
	spawn(function()
		while gameState.roundActive and gameState.timeRemaining > 0 do
			wait(1)
			gameState.timeRemaining = gameState.timeRemaining - 1
			
			for _, player in Players:GetPlayers() do
				remotes.UpdateGameState:FireClient(player, gameState)
			end
			
			if gameState.timeRemaining <= 0 and not gameState.dogsSpawned then
				gameState.dogsSpawned = true
				for _, player in Players:GetPlayers() do
					spawnDogSwarm(player)
				end
			end
		end
	end)
	
	spawn(function()
		while gameState.roundActive do
			wait(0.1)
			if gameState.dogsSpawned then
				updateDogs()
			end
		end
	end)
end

local function checkRoundComplete()
	if gameState.objectsCollected >= gameState.objectsRequired then
		gameState.roundActive = false
		
		for _, player in Players:GetPlayers() do
			local data = activePlayers[player]
			if data then
				data.money = data.money + 1000
				data.rebirthTokens = data.rebirthTokens + 5
				updatePlayerStats(player, data)
				remotes.UpdatePlayerData:FireClient(player, data)
			end
		end
		
		wait(5)
		startNewRound()
	end
end

remotes.PickupObject.OnServerEvent:Connect(function(player: Player, objectId: string)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	for _, object in collectibleObjects do
		if object.id == objectId and not object.isCarried then
			local distance = (object.part.Position - player.Character.HumanoidRootPart.Position).Magnitude
			
			if distance <= 10 then
				object.isCarried = true
				object.carriedBy = player
				
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = player.Character.HumanoidRootPart
				weld.Part1 = object.part
				weld.Parent = object.part
				
				object.part.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
				
				if object.part:FindFirstChild("BodyPosition") then
					object.part.BodyPosition:Destroy()
				end
				if object.part:FindFirstChild("BodyAngularVelocity") then
					object.part.BodyAngularVelocity:Destroy()
				end
				
				break
			end
		end
	end
end)

remotes.DropObject.OnServerEvent:Connect(function(player: Player)
	if not dropOffZone then return end
	
	for i, object in collectibleObjects do
		if object.isCarried and object.carriedBy == player then
			local distance = (player.Character.HumanoidRootPart.Position - dropOffZone.Position).Magnitude
			
			if distance <= DROPOFF_RADIUS then
				object.part:Destroy()
				table.remove(collectibleObjects, i)
				
				gameState.objectsCollected = gameState.objectsCollected + 1
				
				for _, p in Players:GetPlayers() do
					remotes.UpdateGameState:FireClient(p, gameState)
				end
				
				checkRoundComplete()
			else
				for _, weld in object.part:GetChildren() do
					if weld:IsA("WeldConstraint") then
						weld:Destroy()
					end
				end
				
				object.isCarried = false
				object.carriedBy = nil
				
				local float = Instance.new("BodyPosition")
				float.MaxForce = Vector3.new(0, 4000, 0)
				float.Position = object.part.Position
				float.Parent = object.part
				
				local spin = Instance.new("BodyAngularVelocity")
				spin.AngularVelocity = Vector3.new(0, 5, 0)
				spin.MaxTorque = Vector3.new(0, 4000, 0)
				spin.Parent = object.part
			end
			
			break
		end
	end
end)

remotes.StartRound.OnServerEvent:Connect(function(player: Player)
	if not gameState.roundActive then
		startNewRound()
	end
end)

local function createFireball()
	local x = math.random(-200, 200)
	local z = math.random(-200, 200)
	local startY = 150
	
	local fireball = Instance.new("Part")
	fireball.Name = "Fireball"
	fireball.Size = Vector3.new(3, 3, 3)
	fireball.Shape = Enum.PartType.Ball
	fireball.Position = Vector3.new(x, startY, z)
	fireball.BrickColor = BrickColor.new("Really red")
	fireball.Material = Enum.Material.Neon
	fireball.TopSurface = Enum.SurfaceType.Smooth
	fireball.BottomSurface = Enum.SurfaceType.Smooth
	fireball.CanCollide = false
	fireball.Parent = workspace
	
	local fire = Instance.new("Fire")
	fire.Size = 10
	fire.Heat = 20
	fire.Color = Color3.new(1, 0.5, 0)
	fire.SecondaryColor = Color3.new(1, 0, 0)
	fire.Parent = fireball
	
	local light = Instance.new("PointLight")
	light.Brightness = 3
	light.Color = Color3.new(1, 0.5, 0)
	light.Range = 15
	light.Parent = fireball
	
	local trail = Instance.new("Trail")
	local attachment0 = Instance.new("Attachment", fireball)
	local attachment1 = Instance.new("Attachment", fireball)
	attachment0.Position = Vector3.new(0, 1, 0)
	attachment1.Position = Vector3.new(0, -1, 0)
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Lifetime = 1
	trail.MinLength = 0
	trail.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 0.5, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.2, 0)),
		ColorSequenceKeypoint.new(1, Color3.new(0.5, 0, 0))
	}
	trail.Parent = fireball
	
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = Vector3.new(0, -50, 0)
	bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
	bodyVelocity.Parent = fireball
	
	local hitConnection
	hitConnection = fireball.Touched:Connect(function(hit)
		if hit.Parent:FindFirstChild("Humanoid") then
			local humanoid = hit.Parent:FindFirstChild("Humanoid")
			if humanoid and Players:GetPlayerFromCharacter(hit.Parent) then
				humanoid:TakeDamage(FIREBALL_DAMAGE)
			end
		end
		
		local explosion = Instance.new("Explosion")
		explosion.Position = fireball.Position
		explosion.BlastRadius = 10
		explosion.BlastPressure = 0
		explosion.Parent = workspace
		
		fireball:Destroy()
		hitConnection:Disconnect()
	end)
	
	game:GetService("Debris"):AddItem(fireball, 10)
end

spawn(function()
	while true do
		wait(FIREBALL_SPAWN_INTERVAL)
		createFireball()
	end
end)

local function createPickupEgg(position: Vector3)
	local egg = Instance.new("Part")
	egg.Name = "PickupEgg"
	egg.Shape = Enum.PartType.Ball
	egg.Size = Vector3.new(2, 2.5, 2)
	egg.Position = position
	egg.BrickColor = BrickColor.new("Pastel yellow")
	egg.Material = Enum.Material.Neon
	egg.TopSurface = Enum.SurfaceType.Smooth
	egg.BottomSurface = Enum.SurfaceType.Smooth
	egg.Parent = workspace
	
	local eggId = "egg_" .. tostring(tick()) .. "_" .. tostring(math.random(1000, 9999))
	egg:SetAttribute("EggId", eggId)
	eggs[eggId] = egg
	
	local light = Instance.new("PointLight")
	light.Brightness = 1
	light.Color = Color3.new(1, 1, 0.8)
	light.Range = 10
	light.Parent = egg
	
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Color3.new(1, 1, 0.8)
	sparkles.Parent = egg
	
	local float = Instance.new("BodyPosition")
	float.MaxForce = Vector3.new(0, 4000, 0)
	float.Position = position + Vector3.new(0, math.sin(tick()) * 0.5, 0)
	float.Parent = egg
	
	local spin = Instance.new("BodyAngularVelocity")
	spin.AngularVelocity = Vector3.new(0, 3, 0)
	spin.MaxTorque = Vector3.new(0, 4000, 0)
	spin.Parent = egg
	
	spawn(function()
		while egg.Parent do
			wait(0.1)
			if float then
				float.Position = position + Vector3.new(0, math.sin(tick() * 2) * 0.5 + 1, 0)
			end
		end
	end)
	
	CollectionService:AddTag(egg, "PickupEgg")
end

local function spawnEggsAcrossMap()
	for i = 1, EGG_SPAWN_COUNT do
		local x = math.random(-200, 200)
		local z = math.random(-200, 200)
		local y = getGroundHeight(x, z) + 2
		createPickupEgg(Vector3.new(x, y, z))
	end
end

remotes.PickupEgg.OnServerEvent:Connect(function(player: Player, eggId: string)
	if playerHeldEggs[player] then
		return
	end
	
	local egg = eggs[eggId]
	if not egg or not egg.Parent then
		return
	end
	
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local distance = (egg.Position - player.Character.HumanoidRootPart.Position).Magnitude
	if distance > 10 then
		return
	end
	
	playerHeldEggs[player] = egg
	
	if egg:FindFirstChild("BodyPosition") then
		egg.BodyPosition:Destroy()
	end
	if egg:FindFirstChild("BodyAngularVelocity") then
		egg.BodyAngularVelocity:Destroy()
	end
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = player.Character.HumanoidRootPart
	weld.Part1 = egg
	weld.Parent = egg
	
	egg.CFrame = player.Character.HumanoidRootPart.CFrame + player.Character.HumanoidRootPart.CFrame.LookVector * 2 + Vector3.new(0, 2, 0)
	
	spawnDogSwarm(player)
	
	for _, dog in dogs do
		if dog.model and dog.model.Parent and dog.humanoid.Health > 0 then
			dog.target = player
		end
	end
end)

remotes.ThrowEgg.OnServerEvent:Connect(function(player: Player, targetPosition: Vector3)
	local egg = playerHeldEggs[player]
	if not egg or not egg.Parent then
		return
	end
	
	playerHeldEggs[player] = nil
	
	for _, weld in egg:GetChildren() do
		if weld:IsA("WeldConstraint") then
			weld:Destroy()
		end
	end
	
	local direction = (targetPosition - egg.Position).Unit
	
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = direction * EGG_THROW_SPEED
	bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyVelocity.Parent = egg
	
	local hitConnection
	hitConnection = egg.Touched:Connect(function(hit)
		if hit.Parent ~= player.Character then
			local humanoid = hit.Parent:FindFirstChild("Humanoid")
			if humanoid then
				local isDog = false
				for _, dog in dogs do
					if dog.model == hit.Parent then
						isDog = true
						humanoid:TakeDamage(EGG_THROW_DAMAGE)
						
						local splat = Instance.new("Part")
						splat.Name = "EggSplat"
						splat.Size = Vector3.new(4, 0.2, 4)
						splat.Position = egg.Position
						splat.BrickColor = BrickColor.new("Bright yellow")
						splat.Material = Enum.Material.Neon
						splat.Anchored = true
						splat.CanCollide = false
						splat.Transparency = 0.5
						splat.Parent = workspace
						
						game:GetService("Debris"):AddItem(splat, 2)
						break
					end
				end
			end
			
			if egg.Parent then
				local eggId = egg:GetAttribute("EggId")
				if eggId then
					eggs[eggId] = nil
				end
				egg:Destroy()
			end
			hitConnection:Disconnect()
		end
	end)
	
	game:GetService("Debris"):AddItem(bodyVelocity, 0.5)
	game:GetService("Debris"):AddItem(egg, 5)
end)

spawn(function()
	wait(5)
	spawnEggsAcrossMap()
	
	while true do
		wait(30)
		local eggCount = 0
		for _, egg in eggs do
			if egg and egg.Parent then
				eggCount = eggCount + 1
			end
		end
		
		if eggCount < EGG_SPAWN_COUNT / 2 then
			for i = 1, 10 do
				local x = math.random(-200, 200)
				local z = math.random(-200, 200)
				local y = getGroundHeight(x, z) + 2
				createPickupEgg(Vector3.new(x, y, z))
			end
		end
	end
end)