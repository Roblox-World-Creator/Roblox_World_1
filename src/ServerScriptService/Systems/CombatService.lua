local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local CombatService = {}

local abilityColors = {
	EnergyBlast = Color3.fromRGB(80, 220, 255),
	FlameBurst = Color3.fromRGB(255, 100, 35),
	ThunderStrike = Color3.fromRGB(230, 245, 80),
	WindCutter = Color3.fromRGB(120, 255, 190),
	MeteorCrash = Color3.fromRGB(255, 70, 30),
	EnergyBeam = Color3.fromRGB(100, 160, 255),
	VoidExplosion = Color3.fromRGB(180, 80, 255),
	UltimateNova = Color3.fromRGB(255, 220, 100),
}

local function createOrb(position, color, size, lifetime)
	local effect = Instance.new("Part")
	effect.Name = "SpellProjectile"
	effect.Shape = Enum.PartType.Ball
	effect.Material = Enum.Material.Neon
	effect.Color = color
	effect.Transparency = 0.1
	effect.Anchored = true
	effect.CanCollide = false
	effect.Size = Vector3.new(size, size, size)
	effect.Position = position
	effect.Parent = workspace
	Debris:AddItem(effect, lifetime)
	return effect
end

local function createAbilityEffect(abilityName, startPosition, targetPosition, radius)
	local color = abilityColors[abilityName] or Color3.new(1, 1, 1)
	local projectile = createOrb(startPosition + Vector3.new(0, 2, 0), color, 1.4, 0.7)
	local distance = (targetPosition - projectile.Position).Magnitude
	local travel = math.clamp(distance / 120, 0.15, 0.6)
	TweenService:Create(projectile, TweenInfo.new(travel, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = targetPosition + Vector3.new(0, 1, 0),
		Size = Vector3.new(2.4, 2.4, 2.4),
	}):Play()
	task.delay(travel, function()
		if not projectile.Parent then
			return
		end
		projectile:Destroy()
		local burst = createOrb(targetPosition + Vector3.new(0, 1, 0), color, 1, 0.45)
		TweenService:Create(burst, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = Vector3.new(radius * 2, radius * 2, radius * 2),
			Transparency = 1,
		}):Play()
	end)

	if abilityName == "ThunderStrike" or abilityName == "UltimateNova" then
		local bolt = Instance.new("Beam")
		local start = Instance.new("Attachment")
		local finish = Instance.new("Attachment")
		start.WorldPosition = startPosition + Vector3.new(0, 10, 0)
		finish.WorldPosition = targetPosition + Vector3.new(0, 1, 0)
		start.Parent = workspace.Terrain
		finish.Parent = workspace.Terrain
		bolt.Attachment0 = start
		bolt.Attachment1 = finish
		bolt.Color = ColorSequence.new(color)
		bolt.Width0 = 0.35
		bolt.Width1 = 0.1
		bolt.LightEmission = 1
		bolt.Parent = start
		Debris:AddItem(start, 0.25)
		Debris:AddItem(finish, 0.25)
	elseif abilityName == "VoidExplosion" then
		local hole = createOrb(targetPosition + Vector3.new(0, 1, 0), color, radius * 1.5, 0.55)
		hole.Transparency = 0.45
		TweenService:Create(hole, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = Vector3.new(1, 1, 1),
			Transparency = 1,
		}):Play()
	elseif abilityName == "EnergyBeam" then
		local beam = Instance.new("Part")
		beam.Name = "EnergyBeamTrail"
		beam.Anchored = true
		beam.CanCollide = false
		beam.Material = Enum.Material.Neon
		beam.Color = color
		beam.Size = Vector3.new(0.8, 0.8, distance)
		beam.CFrame = CFrame.lookAt((startPosition + targetPosition) / 2, targetPosition)
		beam.Parent = workspace
		TweenService:Create(beam, TweenInfo.new(0.35), {Transparency = 1, Size = Vector3.new(0.1, 0.1, distance)}):Play()
		Debris:AddItem(beam, 0.4)
	elseif abilityName == "WindCutter" then
		for index = -1, 1 do
			local slash = createOrb(targetPosition + Vector3.new(index * radius * 0.45, 0, 0), color, 0.35, 0.35)
			TweenService:Create(slash, TweenInfo.new(0.3), {Position = slash.Position + Vector3.new(radius, 0, 0), Transparency = 1}):Play()
		end
	elseif abilityName == "MeteorCrash" then
		local meteor = createOrb(targetPosition + Vector3.new(0, 28, 0), color, 3, 0.5)
		TweenService:Create(meteor, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = targetPosition + Vector3.new(0, 1, 0), Rotation = Vector3.new(180, 90, 0)}):Play()
	elseif abilityName == "FlameBurst" then
		local fire = createOrb(targetPosition + Vector3.new(0, 1, 0), color, radius, 0.6)
		fire.Transparency = 0.55
		TweenService:Create(fire, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(1, radius * 2, 1), Transparency = 1}):Play()
	end
end

local function getOrCreateRemote(folder, name)
	local remote = folder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	return remote
end

local function getEnemyAtPosition(position, radius)
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then
		return {}
	end
	local results = {}
	for _, enemy in ipairs(enemies:GetChildren()) do
		local humanoid = enemy:FindFirstChildOfClass("Humanoid")
		local root = enemy:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 and (root.Position - position).Magnitude <= radius then
			table.insert(results, enemy)
		end
	end
	return results
end

local function createLightningArc(fromPosition, toPosition, color)
	local start = Instance.new("Attachment")
	local finish = Instance.new("Attachment")
	start.WorldPosition = fromPosition + Vector3.new(0, 2, 0)
	finish.WorldPosition = toPosition + Vector3.new(0, 2, 0)
	start.Parent = workspace.Terrain
	finish.Parent = workspace.Terrain
	local beam = Instance.new("Beam")
	beam.Attachment0 = start
	beam.Attachment1 = finish
	beam.Color = ColorSequence.new(color)
	beam.Width0 = 0.28
	beam.Width1 = 0.08
	beam.LightEmission = 1
	beam.Parent = start
	Debris:AddItem(start, 0.3)
	Debris:AddItem(finish, 0.3)
end

local function damageEnemy(player, enemy, amount, config, progression, feedbackRemote)
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	enemy:SetAttribute("LastDamagerUserId", player.UserId)
	enemy:SetAttribute("AggroUserId", player.UserId)
	enemy:SetAttribute("Damage_" .. player.UserId, (enemy:GetAttribute("Damage_" .. player.UserId) or 0) + amount)
	humanoid:TakeDamage(amount)
	local root = enemy:FindFirstChild("HumanoidRootPart")
	if root then
		local damageGui = Instance.new("BillboardGui")
		damageGui.Name = "DamageNumber"
		damageGui.Adornee = root
		damageGui.Size = UDim2.fromOffset(110, 34)
		damageGui.StudsOffset = Vector3.new(math.random(-12, 12) / 10, 3, 0)
		damageGui.AlwaysOnTop = true
		damageGui.Parent = enemy
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = string.format("-%d", math.floor(amount))
		label.TextColor3 = Color3.fromRGB(255, 70, 70)
		label.TextStrokeColor3 = Color3.fromRGB(60, 10, 15)
		label.TextStrokeTransparency = 0
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.Parent = damageGui
		TweenService:Create(damageGui, TweenInfo.new(0.7), {StudsOffset = damageGui.StudsOffset + Vector3.new(0, 2, 0)}):Play()
		TweenService:Create(label, TweenInfo.new(0.7), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		Debris:AddItem(damageGui, 0.75)
	end
	if humanoid.Health <= 0 then
		local xp = enemy:GetAttribute("RewardXP") or 0
		local coins = enemy:GetAttribute("RewardCoins") or 0
		progression.AddXP(player, xp, config)
		progression.AddCoins(player, coins)
		feedbackRemote:FireClient(player, "Reward", xp, coins)
	end
end

function CombatService.Start(config, progression)
	workspace:SetAttribute("CombatStatus", "Starting")
	local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
	local combatRemote = getOrCreateRemote(remotes, "CombatRemote")
	local abilityRemote = getOrCreateRemote(remotes, "AbilityRemote")
	local feedbackRemote = getOrCreateRemote(remotes, "CombatFeedback")
	local cooldowns = {}

	local function validCharacter(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return character and humanoid and root and humanoid.Health > 0, root
	end

	combatRemote.OnServerEvent:Connect(function(player, action)
		if action ~= "Melee" then
			return
		end
		local valid, root = validCharacter(player)
		if not valid then
			return
		end
		feedbackRemote:FireClient(player, "CastAccepted", "Melee")
		createAbilityEffect("Melee", root.Position, root.Position + root.CFrame.LookVector * 5, 5)
		for _, enemy in ipairs(getEnemyAtPosition(root.Position + root.CFrame.LookVector * 5, config.MeleeRange)) do
			damageEnemy(player, enemy, player:GetAttribute("AttackPower") or config.MeleeDamage, config, progression, feedbackRemote)
		end
	end)

	abilityRemote.OnServerEvent:Connect(function(player, abilityName, targetPosition)
		local ability = config.Abilities[abilityName]
		if not ability or typeof(targetPosition) ~= "Vector3" then
			feedbackRemote:FireClient(player, "CastRejected", "Invalid target")
			return
		end
		local valid, root = validCharacter(player)
		if not valid or (targetPosition - root.Position).Magnitude > ability.Range then
			feedbackRemote:FireClient(player, "CastRejected", "Out of range")
			return
		end
		cooldowns[player] = cooldowns[player] or {}
		if (cooldowns[player][abilityName] or 0) > os.clock() then
			feedbackRemote:FireClient(player, "CastRejected", "Cooling down")
			return
		end
		local energy = player:GetAttribute("Energy") or 0
		if energy < ability.EnergyCost then
			feedbackRemote:FireClient(player, "CastRejected", "Need more energy")
			return
		end
		player:SetAttribute("Energy", energy - ability.EnergyCost)
		cooldowns[player][abilityName] = os.clock() + ability.Cooldown
		feedbackRemote:FireClient(player, "CastAccepted", abilityName)
		createAbilityEffect(abilityName, root.Position, targetPosition, ability.Radius)
		local hitEnemies = getEnemyAtPosition(targetPosition, ability.Radius)
		for _, enemy in ipairs(hitEnemies) do
			damageEnemy(player, enemy, ability.Damage + ((player:GetAttribute("AttackPower") or 0) * 0.5), config, progression, feedbackRemote)
		end
		if abilityName == "ThunderStrike" then
			local previousPosition = targetPosition
			local chainCount = 0
			for _, enemy in ipairs(getEnemyAtPosition(targetPosition, ability.Radius * 2.2)) do
				if not table.find(hitEnemies, enemy) and chainCount < 3 then
					local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
					if enemyRoot then
						createLightningArc(previousPosition, enemyRoot.Position, abilityColors.ThunderStrike)
						damageEnemy(player, enemy, ability.Damage * 0.45, config, progression, feedbackRemote)
						previousPosition = enemyRoot.Position
						chainCount += 1
					end
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			for _, enemy in ipairs((workspace:FindFirstChild("Enemies") and workspace.Enemies:GetChildren()) or {}) do
				local targetUserId = enemy:GetAttribute("AggroUserId")
				local target = targetUserId and Players:GetPlayerByUserId(targetUserId)
				local humanoid = enemy:FindFirstChildOfClass("Humanoid")
				local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
				local validTarget = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
				local targetHumanoid = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
				if humanoid and enemyRoot and validTarget and targetHumanoid and humanoid.Health > 0 and targetHumanoid.Health > 0 then
					local targetRoot = validTarget
					humanoid:MoveTo(targetRoot.Position)
					if (enemyRoot.Position - targetRoot.Position).Magnitude <= 7 then
						targetHumanoid:TakeDamage(enemy:GetAttribute("AttackDamage") or 5)
					end
				end
			end
			task.wait(0.5)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
	end)
	workspace:SetAttribute("CombatStatus", "Ready")
end

return CombatService