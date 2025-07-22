local RebirthSystem = {}

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

local Types = require(script.Parent.Types)

local REBIRTH_REQUIREMENTS = {
	10,    -- Rebirth 1
	25,    -- Rebirth 2  
	50,    -- Rebirth 3
	100,   -- Rebirth 4
}

local REBIRTH_BONUSES = {
	{
		level = 1,
		speedBonus = 0.1,
		moneyMultiplier = 0.25,
		eggDetectionBonus = 10,
		description = "+10% Speed, +25% Money, +10 Egg Detection"
	},
	{
		level = 2,
		speedBonus = 0.2,
		moneyMultiplier = 0.5,
		starterItem = "HeatDetectorV2",
		badge = "EggFinder",
		description = "+20% Speed, +50% Money, Heat Detector V2"
	},
	{
		level = 3,
		speedBonus = 0.3,
		moneyMultiplier = 1.0,
		tokenMultiplier = 2,
		auraEffect = "GoldenAura",
		description = "+30% Speed, +100% Money, 2x Tokens"
	},
	{
		level = 4,
		speedBonus = 0.4,
		moneyMultiplier = 2.0,
		legendaryMagnet = true,
		pet = "Phoenix",
		description = "+40% Speed, +200% Money, Legendary Magnet"
	},
	{
		level = 5,
		speedBonus = 0.5,
		moneyMultiplier = 3.0,
		rainbowTrail = true,
		prestigeAccess = true,
		description = "+50% Speed, +300% Money, Prestige Island"
	},
}

function RebirthSystem.getRequiredTokens(rebirthLevel: number): number
	if rebirthLevel < 1 then
		return REBIRTH_REQUIREMENTS[1]
	elseif rebirthLevel <= #REBIRTH_REQUIREMENTS then
		return REBIRTH_REQUIREMENTS[rebirthLevel]
	else
		return math.floor(REBIRTH_REQUIREMENTS[#REBIRTH_REQUIREMENTS] * math.pow(1.5, rebirthLevel - #REBIRTH_REQUIREMENTS))
	end
end

function RebirthSystem.canRebirth(playerData: Types.PlayerData): boolean
	local required = RebirthSystem.getRequiredTokens(playerData.rebirthLevel + 1)
	return playerData.rebirthTokens >= required
end

function RebirthSystem.performRebirth(player: Player, playerData: Types.PlayerData)
	if not RebirthSystem.canRebirth(playerData) then
		return false, "Not enough rebirth tokens"
	end
	
	local requiredTokens = RebirthSystem.getRequiredTokens(playerData.rebirthLevel + 1)
	
	playerData.rebirthTokens = playerData.rebirthTokens - requiredTokens
	playerData.rebirthLevel = playerData.rebirthLevel + 1
	playerData.money = 0
	
	RebirthSystem.createRebirthEffect(player)
	RebirthSystem.applyRebirthBonuses(player, playerData)
	
	return true, "Rebirth successful! You are now Rebirth " .. playerData.rebirthLevel
end

function RebirthSystem.createRebirthEffect(player: Player)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local character = player.Character
	local rootPart = character.HumanoidRootPart
	
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Brightness = 2
	colorCorrection.Contrast = 2
	colorCorrection.Parent = Lighting
	
	TweenService:Create(colorCorrection, TweenInfo.new(1), {
		Brightness = 0,
		Contrast = 0
	}):Play()
	
	Debris:AddItem(colorCorrection, 1)
	
	local explosionPart = Instance.new("Part")
	explosionPart.Name = "RebirthExplosion"
	explosionPart.Shape = Enum.PartType.Ball
	explosionPart.Size = Vector3.new(1, 1, 1)
	explosionPart.Position = rootPart.Position
	explosionPart.Anchored = true
	explosionPart.CanCollide = false
	explosionPart.Material = Enum.Material.Neon
	explosionPart.BrickColor = BrickColor.new("Bright yellow")
	explosionPart.Parent = workspace
	
	local expandTween = TweenService:Create(explosionPart, TweenInfo.new(2), {
		Size = Vector3.new(50, 50, 50),
		Transparency = 1
	})
	expandTween:Play()
	
	Debris:AddItem(explosionPart, 2)
	
	for i = 1, 20 do
		local beam = Instance.new("Part")
		beam.Name = "RebirthBeam"
		beam.Size = Vector3.new(1, 50, 1)
		beam.Position = rootPart.Position + Vector3.new(
			math.random(-20, 20),
			25,
			math.random(-20, 20)
		)
		beam.Anchored = true
		beam.CanCollide = false
		beam.Material = Enum.Material.Neon
		beam.BrickColor = BrickColor.new("Bright yellow")
		beam.Parent = workspace
		
		local beamTween = TweenService:Create(beam, TweenInfo.new(1), {
			Size = Vector3.new(0.1, 100, 0.1),
			Transparency = 1
		})
		beamTween:Play()
		
		Debris:AddItem(beam, 1)
	end
	
	local attachment = Instance.new("Attachment")
	attachment.Parent = rootPart
	
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/star.png"
	emitter.Rate = 500
	emitter.Lifetime = NumberRange.new(2)
	emitter.Speed = NumberRange.new(20)
	emitter.VelocityInheritance = 0
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 0.5, 0)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
	}
	emitter.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 0)
	}
	emitter.Parent = attachment
	
	wait(0.5)
	emitter.Enabled = false
	Debris:AddItem(attachment, 3)
end

function RebirthSystem.applyRebirthBonuses(player: Player, playerData: Types.PlayerData)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:WaitForChild("Humanoid")
	
	for i = 1, math.min(playerData.rebirthLevel, #REBIRTH_BONUSES) do
		local bonus = REBIRTH_BONUSES[i]
		
		if bonus.speedBonus then
			humanoid.WalkSpeed = humanoid.WalkSpeed * (1 + bonus.speedBonus)
		end
		
		if bonus.starterItem then
			playerData.upgrades[bonus.starterItem] = true
		end
		
		if bonus.auraEffect == "GoldenAura" then
			RebirthSystem.createGoldenAura(character)
		end
		
		if bonus.pet and character:FindFirstChild("HumanoidRootPart") then
			RebirthSystem.spawnPet(player, bonus.pet)
		end
		
		if bonus.rainbowTrail then
			RebirthSystem.createRainbowTrail(character)
		end
	end
end

function RebirthSystem.createGoldenAura(character: Model)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local aura = Instance.new("ParticleEmitter")
	aura.Name = "GoldenAura"
	aura.Texture = "rbxasset://textures/particles/smoke_main.dds"
	aura.Rate = 50
	aura.Lifetime = NumberRange.new(1, 2)
	aura.Speed = NumberRange.new(2)
	aura.VelocityInheritance = 0.5
	aura.SpreadAngle = Vector2.new(30, 30)
	aura.Color = ColorSequence.new(Color3.new(1, 0.84, 0))
	aura.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	}
	aura.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 3)
	}
	aura.Parent = rootPart
end

function RebirthSystem.createRainbowTrail(character: Model)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "TrailAttachment0"
	attachment0.Position = Vector3.new(0, -2.5, 0)
	attachment0.Parent = rootPart
	
	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "TrailAttachment1"
	attachment1.Position = Vector3.new(0, -2.5, 0)
	attachment1.Parent = rootPart
	
	local trail = Instance.new("Trail")
	trail.Name = "RainbowTrail"
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Lifetime = 2
	trail.MinLength = 0.1
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
	trail.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	}
	trail.Parent = rootPart
end

function RebirthSystem.spawnPet(player: Player, petType: string)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	
	local existingPet = character:FindFirstChild(petType .. "Pet")
	if existingPet then
		existingPet:Destroy()
	end
	
	local pet = Instance.new("Part")
	pet.Name = petType .. "Pet"
	pet.Size = Vector3.new(2, 2, 2)
	pet.Shape = Enum.PartType.Ball
	pet.Material = Enum.Material.Neon
	pet.BrickColor = BrickColor.new("Bright orange")
	pet.TopSurface = Enum.SurfaceType.Smooth
	pet.BottomSurface = Enum.SurfaceType.Smooth
	pet.CanCollide = false
	pet.Parent = character
	
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyPosition.Parent = pet
	
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
	bodyGyro.Parent = pet
	
	local fire = Instance.new("Fire")
	fire.Size = 5
	fire.Heat = 10
	fire.Color = Color3.new(1, 0.5, 0)
	fire.SecondaryColor = Color3.new(1, 0, 0)
	fire.Parent = pet
	
	game:GetService("RunService").Heartbeat:Connect(function()
		if character.Parent and character:FindFirstChild("HumanoidRootPart") then
			local targetPos = character.HumanoidRootPart.Position + 
				character.HumanoidRootPart.CFrame.RightVector * 3 +
				Vector3.new(0, 3 + math.sin(tick() * 2) * 0.5, 0)
			bodyPosition.Position = targetPos
			bodyGyro.CFrame = character.HumanoidRootPart.CFrame
		else
			pet:Destroy()
		end
	end)
end

function RebirthSystem.getRebirthBonus(rebirthLevel: number, bonusType: string)
	local totalBonus = 0
	
	for i = 1, math.min(rebirthLevel, #REBIRTH_BONUSES) do
		local bonus = REBIRTH_BONUSES[i]
		if bonus[bonusType] then
			totalBonus = totalBonus + bonus[bonusType]
		end
	end
	
	if rebirthLevel > 5 then
		local extraLevels = rebirthLevel - 5
		if bonusType == "moneyMultiplier" or bonusType == "speedBonus" then
			totalBonus = totalBonus + (extraLevels * 0.05)
		end
	end
	
	return totalBonus
end

return RebirthSystem