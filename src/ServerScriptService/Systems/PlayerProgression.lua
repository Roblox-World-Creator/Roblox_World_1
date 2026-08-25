local Players = game:GetService("Players")

local PlayerProgression = {}

local function xpRequired(config, level)
	return math.floor(config.XPBase * (level ^ config.XPExponent))
end

local function setStats(player, config)
	local level = player:GetAttribute("Level") or config.StartingLevel
	local previousMaxHealth = player:GetAttribute("MaxHealth") or config.StartingMaxHealth
	player:SetAttribute("XPRequired", xpRequired(config, level))
	local evolution = player:GetAttribute("Evolution") or 0
	local attackMultiplier = player:GetAttribute("AttackMultiplier") or 1
	local healthMultiplier = player:GetAttribute("HealthMultiplier") or 1
	if evolution == 0 then
		attackMultiplier = 1
		healthMultiplier = 1
	end
	local maxHealth = math.floor((config.StartingMaxHealth + ((level - 1) * config.LevelHealthBonus)) * healthMultiplier
		+ (player:GetAttribute("EquipmentHealth") or 0))
	player:SetAttribute("MaxHealth", maxHealth)
	player:SetAttribute("AttackPower", math.floor((config.StartingAttack + ((level - 1) * config.LevelAttackBonus)) * attackMultiplier
		+ (player:GetAttribute("EquipmentAttack") or 0)))
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.MaxHealth = maxHealth
		humanoid.Health = math.min(maxHealth, humanoid.Health + math.max(0, maxHealth - previousMaxHealth))
	end
end

function PlayerProgression.AddXP(player, amount, config)
	if not player or not player.Parent then
		return
	end

	local xp = (player:GetAttribute("XP") or 0) + math.max(0, amount)
	local level = player:GetAttribute("Level") or config.StartingLevel
	local required = xpRequired(config, level)
	while xp >= required do
		xp -= required
		level += 1
		required = xpRequired(config, level)
	end
	player:SetAttribute("XP", xp)
	player:SetAttribute("Level", level)
	setStats(player, config)
end

function PlayerProgression.AddCoins(player, amount)
	if player and player.Parent then
		player:SetAttribute("Coins", (player:GetAttribute("Coins") or 0) + math.max(0, amount))
	end
end

function PlayerProgression.RefreshStats(player, config)
	setStats(player, config)
end

function PlayerProgression.Start(config, resourceConfig, evolutionConfig, saveService)
	local function setupPlayer(player)
		player:SetAttribute("DataLoaded", false)
		local data = saveService.Load(player, {
			Level = config.StartingLevel,
			XP = config.StartingXP,
			Coins = config.StartingCoins,
			Evolution = 0,
			Inventory = {
				IronBlade = {Count = 1, Favorite = false, Locked = true},
				HealthPotion = {Count = 3, Favorite = false, Locked = false},
				ManaPotion = {Count = 2, Favorite = false, Locked = false},
			},
			Equipment = {Weapon = "IronBlade"},
			Mastery = {},
			Quests = {},
			QuestClaims = {},
			Settings = {EffectQuality = "HIGH", CameraShakeEnabled = true, DamageNumbersEnabled = true},
		})
		if not player.Parent then
			return
		end
		player:SetAttribute("Level", math.max(config.StartingLevel, data.Level))
		player:SetAttribute("XP", math.max(0, data.XP))
		player:SetAttribute("Coins", math.max(0, data.Coins))
		player:SetAttribute("Evolution", math.max(0, data.Evolution))
		local evolutionDefinition = evolutionConfig[data.Evolution]
		local attackMultiplier = evolutionDefinition and evolutionDefinition.AttackMultiplier or 1
		local healthMultiplier = evolutionDefinition and evolutionDefinition.HealthMultiplier or 1
		local energyMultiplier = evolutionDefinition and evolutionDefinition.EnergyMultiplier or 1
		local speedMultiplier = evolutionDefinition and evolutionDefinition.SpeedMultiplier or 1
		player:SetAttribute("AttackMultiplier", attackMultiplier)
		player:SetAttribute("HealthMultiplier", healthMultiplier)
		player:SetAttribute("EnergyMultiplier", energyMultiplier)
		player:SetAttribute("SpeedMultiplier", speedMultiplier)
		local maxMP = math.floor(resourceConfig.MaxMP * energyMultiplier)
		player:SetAttribute("MP", maxMP)
		player:SetAttribute("MaxMP", maxMP)
		player:SetAttribute("Energy", maxMP)
		player:SetAttribute("MaxEnergy", maxMP)
		player:SetAttribute("Stamina", resourceConfig.MaxStamina)
		player:SetAttribute("MaxStamina", resourceConfig.MaxStamina)
		player:SetAttribute("LastStaminaUse", 0)
		player:SetAttribute("Blocking", false)
		player:SetAttribute("BlockStartedAt", 0)
		player:SetAttribute("LastBlockStartAt", 0)
		player:SetAttribute("InvulnerableUntil", 0)
		setStats(player, config)
		player:SetAttribute("DataLoaded", true)

		local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
		for _, name in ipairs({"Level", "Coins"}) do
			local value = leaderstats:FindFirstChild(name) or Instance.new("IntValue")
			value.Name = name
			value.Parent = leaderstats
			player:GetAttributeChangedSignal(name):Connect(function()
				value.Value = player:GetAttribute(name) or 0
			end)
			value.Value = player:GetAttribute(name) or 0
		end

		player.CharacterAdded:Connect(function(character)
			player:SetAttribute("Blocking", false)
			player:SetAttribute("InvulnerableUntil", 0)
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.MaxHealth = player:GetAttribute("MaxHealth") or config.StartingMaxHealth
			humanoid.Health = humanoid.MaxHealth
			humanoid.WalkSpeed = player:GetAttribute("AdminSpeedOverride")
				or resourceConfig.BaseWalkSpeed * (player:GetAttribute("SpeedMultiplier") or 1) + (player:GetAttribute("EquipmentSpeed") or 0)
		end)
		if player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.MaxHealth = player:GetAttribute("MaxHealth") or config.StartingMaxHealth
				humanoid.Health = humanoid.MaxHealth
				humanoid.WalkSpeed = player:GetAttribute("AdminSpeedOverride")
					or resourceConfig.BaseWalkSpeed * (player:GetAttribute("SpeedMultiplier") or 1) + (player:GetAttribute("EquipmentSpeed") or 0)
			end
		end

		task.spawn(function()
			while player.Parent do
				local maxMP = player:GetAttribute("MaxMP") or resourceConfig.MaxMP
				local mp = player:GetAttribute("MP") or 0
				local regeneratedMP = math.min(maxMP, mp + (resourceConfig.MPRegenPerSecond + (player:GetAttribute("BonusMPRegen") or 0)) * resourceConfig.MPRegenInterval)
				player:SetAttribute("MP", regeneratedMP)
				-- Keep the prototype Energy attributes synchronized for compatibility.
				player:SetAttribute("Energy", regeneratedMP)
				player:SetAttribute("MaxEnergy", maxMP)

				local lastUse = player:GetAttribute("LastStaminaUse") or 0
				if workspace:GetServerTimeNow() - lastUse >= resourceConfig.StaminaRegenDelay then
					local maxStamina = player:GetAttribute("MaxStamina") or resourceConfig.MaxStamina
					local stamina = player:GetAttribute("Stamina") or 0
					player:SetAttribute("Stamina", math.min(maxStamina, stamina + resourceConfig.StaminaRegenPerSecond * resourceConfig.MPRegenInterval))
				end
				task.wait(resourceConfig.MPRegenInterval)
			end
		end)
	end

	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
end

return PlayerProgression
