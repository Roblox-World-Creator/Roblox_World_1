local Players = game:GetService("Players")

local WaveDefense = {}

local function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local function createPart(parent, name, size, position, color, material)
	local part = parent:FindFirstChild(name)
	if not part then
		part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Position = position
		part.Anchored = true
		part.CanCollide = true
		part.Color = color
		part.Material = material
		part.Parent = parent
	end
	return part
end

local function addLabel(parent, text, offset)
	local label = parent:FindFirstChild("WorldLabel") or Instance.new("BillboardGui")
	label.Name = "WorldLabel"
	label.Size = UDim2.fromOffset(150, 30)
	label.StudsOffset = offset
	label.AlwaysOnTop = true
	label.Parent = parent
	local textLabel = label:FindFirstChild("Text") or Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.25
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextScaled = true
	textLabel.Parent = label
end

local function createPickup(parent, name, position, color, attribute, amount)
	local pickup = parent:FindFirstChild(name) or Instance.new("Part")
	pickup.Name = name
	pickup.Shape = Enum.PartType.Ball
	pickup.Size = Vector3.new(2, 2, 2)
	pickup.Position = position
	pickup.Anchored = true
	pickup.CanCollide = false
	pickup.Material = Enum.Material.Neon
	pickup.Color = color
	pickup:SetAttribute("PickupAttribute", attribute)
	pickup:SetAttribute("PickupAmount", amount)
	pickup.Parent = parent
	addLabel(pickup, name, Vector3.new(0, 2.5, 0))
	if not pickup:GetAttribute("PickupConnected") then
		pickup:SetAttribute("PickupConnected", true)
		pickup.Touched:Connect(function(hit)
			local character = hit.Parent
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local player = humanoid and Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			if attribute == "Health" then
				humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + amount)
			else
				local current = player:GetAttribute(attribute) or 0
				local maximum = player:GetAttribute("MaxEnergy") or 100
				player:SetAttribute(attribute, math.min(maximum, current + amount))
			end
			pickup:SetAttribute("CollectedAt", os.clock())
			pickup.Transparency = 1
			task.delay(8, function()
				if pickup.Parent then
					pickup.Transparency = 0
				end
			end)
		end)
	end
end

local function createWorldDecor(config, arena, core)
	local structures = getOrCreateFolder(arena, "Structures")
	local items = getOrCreateFolder(arena, "DefaultItems")
	local stone = Color3.fromRGB(75, 82, 105)
	local trim = Color3.fromRGB(70, 220, 255)
	for index, position in ipairs({
		Vector3.new(-32, 6, -32), Vector3.new(32, 6, -32),
		Vector3.new(-32, 6, 32), Vector3.new(32, 6, 32),
	}) do
		local tower = getOrCreateFolder(structures, "Watchtower" .. index)
		createPart(tower, "Base", Vector3.new(8, 2, 8), position - Vector3.new(0, 5, 0), stone, Enum.Material.Slate)
		createPart(tower, "Tower", Vector3.new(5, 10, 5), position, stone, Enum.Material.Brick)
		local beacon = createPart(tower, "Beacon", Vector3.new(2, 2, 2), position + Vector3.new(0, 6, 0), trim, Enum.Material.Neon)
		local light = beacon:FindFirstChildOfClass("PointLight") or Instance.new("PointLight")
		light.Color = trim
		light.Range = 18
		light.Brightness = 2
		light.Parent = beacon
	end
	createPart(structures, "NorthWall", Vector3.new(70, 5, 2), Vector3.new(0, 2.5, -70), stone, Enum.Material.Brick)
	createPart(structures, "SouthWall", Vector3.new(70, 5, 2), Vector3.new(0, 2.5, 70), stone, Enum.Material.Brick)
	createPart(structures, "EastWall", Vector3.new(2, 5, 70), Vector3.new(70, 2.5, 0), stone, Enum.Material.Brick)
	createPart(structures, "WestWall", Vector3.new(2, 5, 70), Vector3.new(-70, 2.5, 0), stone, Enum.Material.Brick)
	createPickup(items, "HealthCrystal", Vector3.new(-12, 2, 12), Color3.fromRGB(255, 75, 105), "Health", 35)
	createPickup(items, "EnergyCrystal", Vector3.new(12, 2, 12), Color3.fromRGB(80, 180, 255), "Energy", 35)
	createPickup(items, "HealthCrystal2", Vector3.new(-12, 2, -12), Color3.fromRGB(255, 75, 105), "Health", 35)
	createPickup(items, "EnergyCrystal2", Vector3.new(12, 2, -12), Color3.fromRGB(80, 180, 255), "Energy", 35)
	addLabel(core, "DEFENSE CORE", Vector3.new(0, 7, 0))
end

local function createArena(config)
	local arena = getOrCreateFolder(workspace, "Arena")
	local spawns = getOrCreateFolder(workspace, "EnemySpawns")
	local waypoints = getOrCreateFolder(workspace, "EnemyWaypoints")

	createPart(arena, "ArenaFloor", Vector3.new(config.ArenaRadius * 2, 1, config.ArenaRadius * 2), Vector3.new(0, 0, 0), Color3.fromRGB(35, 42, 58), Enum.Material.Slate)

	local core = createPart(workspace, "DefenseCore", Vector3.new(8, 10, 8), config.CorePosition, Color3.fromRGB(70, 220, 255), Enum.Material.Neon)
	core:SetAttribute("MaxHealth", config.BaseCoreHealth)
	core:SetAttribute("Health", config.BaseCoreHealth)
	createWorldDecor(config, arena, core)
	
	local coreLight = core:FindFirstChildOfClass("PointLight")
	if not coreLight then
		coreLight = Instance.new("PointLight")
		coreLight.Color = core.Color
		coreLight.Range = 24
		coreLight.Brightness = 3
		coreLight.Parent = core
	end

	for index = 1, config.WaypointCount do
		local angle = (index / config.WaypointCount) * math.pi * 2
		local position = Vector3.new(math.cos(angle) * config.WaypointRadius, config.EnemyHeight, math.sin(angle) * config.WaypointRadius)
		local waypoint = createPart(waypoints, string.format("Waypoint%02d", index), Vector3.new(3, 0.35, 3), position, Color3.fromRGB(100, 190, 255), Enum.Material.Neon)
		waypoint.Transparency = 0.35
		local spawnPosition = Vector3.new(math.cos(angle) * config.EnemySpawnRadius, config.EnemyHeight, math.sin(angle) * config.EnemySpawnRadius)
		local spawn = createPart(spawns, string.format("Spawn%02d", index), Vector3.new(6, 0.4, 6), spawnPosition, Color3.fromRGB(255, 75, 100), Enum.Material.Neon)
		spawn.Transparency = 0.2
		addLabel(spawn, "ENEMY SPAWN", Vector3.new(0, 2.5, 0))
		local spawnLight = spawn:FindFirstChildOfClass("PointLight") or Instance.new("PointLight")
		spawnLight.Color = spawn.Color
		spawnLight.Range = 12
		spawnLight.Brightness = 1.5
		spawnLight.Parent = spawn
	end

	return arena, spawns, waypoints, core
end

local function sortedChildren(folder)
	local children = folder:GetChildren()
	table.sort(children, function(left, right)
		return left.Name < right.Name
	end)
	return children
end

local function createEnemy(enemyType, definition, healthScale, damageScale, speedBonus, position, parent)
	local model = Instance.new("Model")
	model.Name = definition.DisplayName
	model:SetAttribute("EnemyType", enemyType)
	model:SetAttribute("RewardXP", definition.RewardXP)
	model:SetAttribute("RewardCoins", definition.RewardCoins)
	model:SetAttribute("AttackDamage", definition.Damage * damageScale)

	local body = Instance.new("Part")
	body.Name = "HumanoidRootPart"
	body.Size = Vector3.new(2, 2, 1)
	body.Position = position
	body.Transparency = 1
	body.Anchored = false
	body.CanCollide = false
	body.Parent = model

	local scale = enemyType == "Boss" and 1.7 or 1
	local function addLimb(name, size, offset, color, shape)
		local limb = Instance.new("Part")
		limb.Name = name
		limb.Size = size * scale
		limb.Position = position + offset * scale
		limb.Color = color
		limb.Material = Enum.Material.SmoothPlastic
		limb.Shape = shape or Enum.PartType.Block
		limb.CanCollide = false
		limb.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = limb
		weld.Parent = limb
		return limb
	end

	addLimb("Torso", Vector3.new(2.2, 2.4, 1.2), Vector3.new(0, 2.6, 0), definition.Color)
	addLimb("Head", Vector3.new(1.5, 1.5, 1.5), Vector3.new(0, 4.5, 0), Color3.fromRGB(255, 205, 170), Enum.PartType.Ball)
	addLimb("LeftArm", Vector3.new(0.65, 2.3, 0.65), Vector3.new(-1.55, 2.55, 0), definition.Color)
	addLimb("RightArm", Vector3.new(0.65, 2.3, 0.65), Vector3.new(1.55, 2.55, 0), definition.Color)
	addLimb("LeftLeg", Vector3.new(0.8, 2.4, 0.8), Vector3.new(-0.65, 0.2, 0), Color3.fromRGB(35, 45, 75))
	addLimb("RightLeg", Vector3.new(0.8, 2.4, 0.8), Vector3.new(0.65, 0.2, 0), Color3.fromRGB(35, 45, 75))

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = definition.Health * healthScale
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = definition.Speed + speedBonus
	humanoid.DisplayName = definition.DisplayName
	humanoid.Parent = model

	local healthGui = Instance.new("BillboardGui")
	healthGui.Name = "HealthBar"
	healthGui.Adornee = body
	healthGui.Size = UDim2.fromOffset(enemyType == "Boss" and 220 or 110, enemyType == "Boss" and 32 or 22)
	healthGui.StudsOffset = Vector3.new(0, enemyType == "Boss" and 8 or 4.5, 0)
	healthGui.AlwaysOnTop = true
	healthGui.Parent = model
	local background = Instance.new("Frame")
	background.Size = UDim2.fromScale(1, 0.38)
	background.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	background.BorderSizePixel = 0
	background.Parent = healthGui
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = enemyType == "Boss" and Color3.fromRGB(255, 70, 100) or Color3.fromRGB(80, 235, 130)
	fill.BorderSizePixel = 0
	fill.Parent = background
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0.62)
	nameLabel.Position = UDim2.fromScale(0, 0.4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = definition.DisplayName
	nameLabel.Parent = healthGui
	humanoid.HealthChanged:Connect(function(health)
		fill.Size = UDim2.fromScale(math.clamp(health / humanoid.MaxHealth, 0, 1), 1)
	end)

	model.PrimaryPart = body
	model.Parent = parent
	body:SetNetworkOwner(nil)
	return model, humanoid, definition.Damage * damageScale
end

local function getActivePlayerScale(config)
	local playerCount = math.clamp(#Players:GetPlayers(), 1, config.MaxPlayers)
	return 1 + ((playerCount - 1) * config.PlayersPerHealthScale)
end

local function chooseEnemyType(wave, index)
	if wave % 5 == 0 and index == 1 then
		return "Tank"
	end
	if wave >= 4 and index % 4 == 0 then
		return "Fast"
	end
	if wave >= 3 and index % 6 == 0 then
		return "Tank"
	end
	return "Basic"
end

function WaveDefense.Start(gameConfig, enemyConfig)
	local _, spawns, waypoints, core = createArena(gameConfig)
	local enemyFolder = getOrCreateFolder(workspace, "Enemies")
	local running = true
	local currentWave = 0
	workspace:SetAttribute("HighestWave", 0)
	workspace:SetAttribute("WorldStatus", "Ready")

	local function setWaveAttributes(wave, remaining, state)
		workspace:SetAttribute("Wave", wave)
		workspace:SetAttribute("EnemiesRemaining", remaining)
		workspace:SetAttribute("WaveState", state)
	end

	local function clearEnemies()
		for _, enemy in ipairs(enemyFolder:GetChildren()) do
			enemy:Destroy()
		end
	end

	local function runEnemy(enemy, humanoid, damage, spawnPosition)
		task.spawn(function()
			local direction = Vector3.new(spawnPosition.X, 0, spawnPosition.Z).Unit
			local innerPoint = Vector3.new(direction.X * gameConfig.WaypointRadius, gameConfig.EnemyHeight, direction.Z * gameConfig.WaypointRadius)
			if enemy.Parent and humanoid.Health > 0 then
				humanoid:MoveTo(innerPoint)
				humanoid.MoveToFinished:Wait()
			end
			if enemy.Parent and humanoid.Health > 0 then
				humanoid:MoveTo(Vector3.new(gameConfig.CorePosition.X, gameConfig.EnemyHeight, gameConfig.CorePosition.Z))
				humanoid.MoveToFinished:Wait()
			end

			if enemy.Parent and humanoid.Health > 0 then
				local health = math.max(0, (core:GetAttribute("Health") or 0) - damage)
				core:SetAttribute("Health", health)
				enemy:Destroy()
			end
		end)
	end

	local practicePositions = {
		Vector3.new(-18, gameConfig.EnemyHeight, 0),
		Vector3.new(18, gameConfig.EnemyHeight, 0),
		Vector3.new(0, gameConfig.EnemyHeight, -18),
	}
	for index, position in ipairs(practicePositions) do
		local definition = enemyConfig.Basic
		local practiceEnemy, practiceHumanoid, practiceDamage = createEnemy("Basic", definition, 1, 1, 0, position, enemyFolder)
		practiceEnemy.Name = "PracticeTarget" .. index
		practiceHumanoid.Died:Connect(function()
			task.delay(0.2, function()
				if practiceEnemy.Parent then
					practiceEnemy:Destroy()
				end
			end)
		end)
	end
	setWaveAttributes(0, #enemyFolder:GetChildren(), "Practice")

	task.spawn(function()
		while running do
			currentWave += 1
			if currentWave > gameConfig.MaximumPrototypeWave then
				currentWave = 1
			end
			setWaveAttributes(currentWave, #enemyFolder:GetChildren(), "Intermission")
			workspace:SetAttribute("HighestWave", math.max(workspace:GetAttribute("HighestWave") or 0, currentWave))
			for seconds = gameConfig.IntermissionSeconds, 1, -1 do
				workspace:SetAttribute("WaveCountdown", seconds)
				task.wait(1)
			end
			workspace:SetAttribute("WaveCountdown", 0)

			local playerScale = getActivePlayerScale(gameConfig)
			local healthScale = playerScale * (1 + currentWave * gameConfig.WaveHealthGrowth)
			local damageScale = 1 + currentWave * gameConfig.WaveDamageGrowth
			local speedBonus = math.min(currentWave * gameConfig.WaveSpeedGrowth, gameConfig.MaximumSpeedBonus)
			local enemyCount = 8 + currentWave * 2
			local spawnList = sortedChildren(spawns)
			setWaveAttributes(currentWave, enemyCount, "Active")

			for index = 1, enemyCount do
				local enemyType = chooseEnemyType(currentWave, index)
				local definition = enemyConfig[enemyType]
				local spawn = spawnList[((index - 1) % #spawnList) + 1]
				local enemy, humanoid, damage = createEnemy(enemyType, definition, healthScale, damageScale, speedBonus, spawn.Position, enemyFolder)
				humanoid.Died:Connect(function()
					task.delay(0.2, function()
						if enemy.Parent then
							enemy:Destroy()
						end
					end)
				end)
				runEnemy(enemy, humanoid, damage, spawn.Position)
				task.wait(0.35)
			end

			if currentWave % 10 == 0 then
				local definition = enemyConfig.Boss
				local boss, humanoid, damage = createEnemy("Boss", definition, healthScale * (1 + currentWave * 0.3), damageScale, speedBonus, spawnList[1].Position, enemyFolder)
				boss:SetAttribute("BossWave", currentWave)
				humanoid.Died:Connect(function()
					task.delay(0.2, function()
						if boss.Parent then
							boss:Destroy()
						end
					end)
				end)
				runEnemy(boss, humanoid, damage, spawnList[1].Position)
			end

			repeat
				task.wait(1)
				setWaveAttributes(currentWave, #enemyFolder:GetChildren(), "Active")
			until #enemyFolder:GetChildren() == 0 or (core:GetAttribute("Health") or 0) <= 0

			if (core:GetAttribute("Health") or 0) <= 0 then
				setWaveAttributes(currentWave, #enemyFolder:GetChildren(), "GameOver")
				clearEnemies()
				core:SetAttribute("Health", core:GetAttribute("MaxHealth"))
				task.wait(gameConfig.IntermissionSeconds)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function()
		if #Players:GetPlayers() == 0 then
			clearEnemies()
		end
	end)
end

return WaveDefense