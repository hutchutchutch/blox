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