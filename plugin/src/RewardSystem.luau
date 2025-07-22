local RewardSystem = {}

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Types = require(script.Parent.Types)

local TREASURE_RARITIES = {
	{name = "Common", chance = 0.7, minValue = 10, maxValue = 50, color = Color3.new(0.7, 0.7, 0.7)},
	{name = "Rare", chance = 0.25, minValue = 100, maxValue = 250, color = Color3.new(0, 0.5, 1)},
	{name = "Legendary", chance = 0.05, minValue = 500, maxValue = 1000, color = Color3.new(1, 0.84, 0)},
}

local EGG_DATA = {
	common = {
		color = Color3.new(1, 1, 1),
		moneyReward = {min = 100, max = 200},
		tokenReward = 1,
		spawnRate = 0.4,
		particleColor = Color3.new(0.8, 0.8, 1),
		effectScale = 1,
	},
	uncommon = {
		color = Color3.new(0, 1, 0),
		moneyReward = {min = 300, max = 500},
		tokenReward = 2,
		spawnRate = 0.3,
		particleColor = Color3.new(0.5, 1, 0.5),
		effectScale = 1.2,
	},
	rare = {
		color = Color3.new(0, 0.5, 1),
		moneyReward = {min = 750, max = 1000},
		tokenReward = 5,
		spawnRate = 0.2,
		particleColor = Color3.new(0.5, 0.8, 1),
		effectScale = 1.5,
	},
	epic = {
		color = Color3.new(0.5, 0, 1),
		moneyReward = {min = 2000, max = 3000},
		tokenReward = 10,
		spawnRate = 0.08,
		particleColor = Color3.new(0.8, 0.5, 1),
		effectScale = 2,
	},
	legendary = {
		color = Color3.fromHSV(tick() % 1, 1, 1),
		moneyReward = {min = 5000, max = 10000},
		tokenReward = 25,
		spawnRate = 0.02,
		particleColor = Color3.fromHSV(tick() % 1, 0.8, 1),
		effectScale = 3,
	},
}

function RewardSystem.createTreasureModel(position: Vector3, rarity: number): Model
	local rarityData = TREASURE_RARITIES[rarity]
	local model = Instance.new("Model")
	model.Name = "Treasure_" .. rarityData.name
	
	local chest = Instance.new("Part")
	chest.Name = "Chest"
	chest.Size = Vector3.new(3, 2, 2)
	chest.Position = position
	chest.BrickColor = BrickColor.new("Brown")
	chest.Material = Enum.Material.Wood
	chest.TopSurface = Enum.SurfaceType.Smooth
	chest.BottomSurface = Enum.SurfaceType.Smooth
	chest.Parent = model
	
	local lid = Instance.new("Part")
	lid.Name = "Lid"
	lid.Size = Vector3.new(3, 0.5, 2)
	lid.Position = position + Vector3.new(0, 1.25, 0)
	lid.BrickColor = BrickColor.new("Brown")
	lid.Material = Enum.Material.Wood
	lid.Parent = model
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = chest
	weld.Part1 = lid
	weld.Parent = chest
	
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Color = rarityData.color
	light.Range = 10 + (rarity * 5)
	light.Parent = chest
	
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Rate = 10 * rarity
	sparkles.Lifetime = NumberRange.new(1, 2)
	sparkles.Speed = NumberRange.new(2)
	sparkles.SpreadAngle = Vector2.new(30, 30)
	sparkles.Color = ColorSequence.new(rarityData.color)
	sparkles.Parent = chest
	
	model.Parent = workspace
	return model
end

function RewardSystem.createEggModel(position: Vector3, rarity: Types.EggRarity): Model
	local eggData = EGG_DATA[rarity]
	local model = Instance.new("Model")
	model.Name = "Egg_" .. rarity
	
	local egg = Instance.new("Part")
	egg.Name = "EggPart"
	egg.Shape = Enum.PartType.Ball
	egg.Size = Vector3.new(2, 2.5, 2) * eggData.effectScale
	egg.Position = position
	egg.Color = eggData.color
	egg.Material = Enum.Material.Neon
	egg.TopSurface = Enum.SurfaceType.Smooth
	egg.BottomSurface = Enum.SurfaceType.Smooth
	egg.Parent = model
	
	local floatForce = Instance.new("BodyPosition")
	floatForce.MaxForce = Vector3.new(0, 4000, 0)
	floatForce.Position = position + Vector3.new(0, math.sin(tick() * 2) * 0.5, 0)
	floatForce.Parent = egg
	
	local spin = Instance.new("BodyAngularVelocity")
	spin.AngularVelocity = Vector3.new(0, 2, 0)
	spin.MaxTorque = Vector3.new(0, 4000, 0)
	spin.Parent = egg
	
	local glow = Instance.new("PointLight")
	glow.Brightness = 3 * eggData.effectScale
	glow.Color = eggData.color
	glow.Range = 15 * eggData.effectScale
	glow.Parent = egg
	
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Rate = 20 * eggData.effectScale
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Speed = NumberRange.new(1, 3)
	particles.Color = ColorSequence.new(eggData.particleColor)
	particles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0)
	}
	particles.Parent = egg
	
	if rarity == "legendary" then
		RunService.Heartbeat:Connect(function()
			egg.Color = Color3.fromHSV(tick() % 1, 1, 1)
			glow.Color = egg.Color
		end)
	end
	
	model.Parent = workspace
	return model
end

function RewardSystem.spawnMoneyRain(position: Vector3, amount: number)
	local billCount = math.min(math.floor(amount / 10), 100)
	
	for i = 1, billCount do
		task.wait(0.05)
		
		local bill = Instance.new("Part")
		bill.Name = "MoneyBill"
		bill.Size = Vector3.new(2, 0.1, 1)
		bill.Position = position + Vector3.new(
			math.random(-10, 10),
			math.random(15, 25),
			math.random(-10, 10)
		)
		bill.BrickColor = BrickColor.new("Lime green")
		bill.Material = Enum.Material.Neon
		bill.TopSurface = Enum.SurfaceType.Smooth
		bill.BottomSurface = Enum.SurfaceType.Smooth
		bill.Parent = workspace
		
		local decal1 = Instance.new("Decal")
		decal1.Texture = "rbxasset://textures/ui/Vehicle/SpeedBarEmpty.png"
		decal1.Face = Enum.NormalId.Top
		decal1.Color3 = Color3.new(0, 1, 0)
		decal1.Parent = bill
		
		local decal2 = decal1:Clone()
		decal2.Face = Enum.NormalId.Bottom
		decal2.Parent = bill
		
		local bodyVel = Instance.new("BodyVelocity")
		bodyVel.Velocity = Vector3.new(
			math.random(-20, 20),
			math.random(-30, -20),
			math.random(-20, 20)
		)
		bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
		bodyVel.Parent = bill
		
		local spin = Instance.new("BodyAngularVelocity")
		spin.AngularVelocity = Vector3.new(
			math.random(-10, 10),
			math.random(-10, 10),
			math.random(-10, 10)
		)
		spin.MaxTorque = Vector3.new(4000, 4000, 4000)
		spin.Parent = bill
		
		Debris:AddItem(bill, 3)
	end
end

function RewardSystem.collectTreasureEffect(model: Model, value: number)
	if not model:FindFirstChild("Chest") then return end
	
	local chest = model.Chest
	local lid = model:FindFirstChild("Lid")
	
	if lid then
		local openTween = TweenService:Create(lid, TweenInfo.new(0.5), {
			CFrame = lid.CFrame * CFrame.Angles(math.rad(-90), 0, 0) * CFrame.new(0, 0, -1)
		})
		openTween:Play()
	end
	
	local burst = Instance.new("Part")
	burst.Name = "TreasureBurst"
	burst.Shape = Enum.PartType.Ball
	burst.Size = Vector3.new(1, 1, 1)
	burst.Position = chest.Position
	burst.Anchored = true
	burst.CanCollide = false
	burst.Material = Enum.Material.Neon
	burst.BrickColor = BrickColor.new("Bright yellow")
	burst.Parent = workspace
	
	local expandTween = TweenService:Create(burst, TweenInfo.new(1), {
		Size = Vector3.new(20, 20, 20),
		Transparency = 1
	})
	expandTween:Play()
	
	Debris:AddItem(burst, 1)
	
	task.wait(0.5)
	RewardSystem.spawnMoneyRain(chest.Position, value)
	
	task.wait(1)
	model:Destroy()
end

function RewardSystem.collectEggEffect(model: Model, eggData)
	if not model:FindFirstChild("EggPart") then return end
	
	local egg = model.EggPart
	local position = egg.Position
	
	local crackSound = Instance.new("Sound")
	crackSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	crackSound.Volume = 0.5
	crackSound.Parent = egg
	crackSound:Play()
	
	for i = 1, 3 do
		local crack = Instance.new("Part")
		crack.Name = "EggShell"
		crack.Size = Vector3.new(0.5, 0.5, 0.1)
		crack.Position = position + Vector3.new(math.random(-1, 1), 0, math.random(-1, 1))
		crack.Color = egg.Color
		crack.Material = Enum.Material.Neon
		crack.Parent = workspace
		
		local velocity = Instance.new("BodyVelocity")
		velocity.Velocity = Vector3.new(math.random(-10, 10), math.random(10, 20), math.random(-10, 10))
		velocity.MaxForce = Vector3.new(4000, 4000, 4000)
		velocity.Parent = crack
		
		Debris:AddItem(crack, 2)
	end
	
	local flash = Instance.new("Part")
	flash.Name = "EggFlash"
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(0.1, 0.1, 0.1)
	flash.Position = position
	flash.Anchored = true
	flash.CanCollide = false
	flash.Material = Enum.Material.Neon
	flash.Color = egg.Color
	flash.Parent = workspace
	
	local flashTween = TweenService:Create(flash, TweenInfo.new(0.5), {
		Size = Vector3.new(15, 15, 15),
		Transparency = 1
	})
	flashTween:Play()
	
	Debris:AddItem(flash, 0.5)
	model:Destroy()
end

function RewardSystem.createCollectionBeam(startPos: Vector3, endPos: Vector3, color: Color3)
	local beam = Instance.new("Part")
	beam.Name = "CollectionBeam"
	beam.Anchored = true
	beam.CanCollide = false
	beam.Material = Enum.Material.Neon
	beam.Color = color
	beam.Size = Vector3.new(0.5, 0.5, (startPos - endPos).Magnitude)
	beam.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -beam.Size.Z/2)
	beam.Parent = workspace
	
	local beamTween = TweenService:Create(beam, TweenInfo.new(0.5), {
		Size = Vector3.new(2, 2, beam.Size.Z),
		Transparency = 1
	})
	beamTween:Play()
	
	Debris:AddItem(beam, 0.5)
end

function RewardSystem.getRandomEggRarity(): Types.EggRarity
	local rand = math.random()
	local cumulative = 0
	
	for rarity, data in pairs(EGG_DATA) do
		cumulative = cumulative + data.spawnRate
		if rand <= cumulative then
			return rarity
		end
	end
	
	return "common"
end

function RewardSystem.getRandomTreasureRarity(): number
	local rand = math.random()
	local cumulative = 0
	
	for i, rarity in ipairs(TREASURE_RARITIES) do
		cumulative = cumulative + rarity.chance
		if rand <= cumulative then
			return i
		end
	end
	
	return 1
end

RewardSystem.TREASURE_RARITIES = TREASURE_RARITIES
RewardSystem.EGG_DATA = EGG_DATA

return RewardSystem