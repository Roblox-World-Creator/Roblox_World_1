local Players = game:GetService("Players")

local PlayerProgression = {}

local function xpRequired(config, level)
	return config.XPBase + ((level - 1) * config.XPPerLevel)
end

local function setStats(player, config)
	local level = player:GetAttribute("Level") or config.StartingLevel
	player:SetAttribute("XPRequired", xpRequired(config, level))
	player:SetAttribute("MaxHealth", config.StartingMaxHealth + ((level - 1) * config.LevelHealthBonus))
	player:SetAttribute("AttackPower", config.StartingAttack + ((level - 1) * config.LevelAttackBonus))
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

function PlayerProgression.Start(config)
	local function setupPlayer(player)
		player:SetAttribute("Level", config.StartingLevel)
		player:SetAttribute("XP", config.StartingXP)
		player:SetAttribute("Coins", config.StartingCoins)
		player:SetAttribute("Evolution", 0)
		player:SetAttribute("Energy", 100)
		player:SetAttribute("MaxEnergy", 100)
		setStats(player, config)

		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
		for _, name in ipairs({"Level", "Coins"}) do
			local value = Instance.new("IntValue")
			value.Name = name
			value.Parent = leaderstats
			player:GetAttributeChangedSignal(name):Connect(function()
				value.Value = player:GetAttribute(name) or 0
			end)
			value.Value = player:GetAttribute(name) or 0
		end

		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.MaxHealth = player:GetAttribute("MaxHealth") or config.StartingMaxHealth
			humanoid.Health = humanoid.MaxHealth
		end)

		task.spawn(function()
			while player.Parent do
				local maxEnergy = player:GetAttribute("MaxEnergy") or 100
				local energy = player:GetAttribute("Energy") or 0
				player:SetAttribute("Energy", math.min(maxEnergy, energy + 1))
				task.wait(0.25)
			end
		end)
	end

	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
end

return PlayerProgression