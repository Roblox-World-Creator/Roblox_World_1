local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EvolutionService = {}

local function updateReady(player, config)
	local nextEvolution = (player:GetAttribute("Evolution") or 0) + 1
	local requirement = config[nextEvolution]
	local ready = requirement
		and (player:GetAttribute("Level") or 0) >= requirement.Level
		and (workspace:GetAttribute("HighestWave") or workspace:GetAttribute("Wave") or 0) >= requirement.Wave
		and (player:GetAttribute("Coins") or 0) >= requirement.Coins
	player:SetAttribute("CanEvolve", ready == true)
end

local function addEvolutionGlow(character)
	local highlight = character:FindFirstChild("EvolutionGlow") or Instance.new("Highlight")
	highlight.Name = "EvolutionGlow"
	highlight.FillColor = Color3.fromRGB(255, 210, 70)
	highlight.OutlineColor = Color3.fromRGB(120, 240, 255)
	highlight.FillTransparency = 0.35
	highlight.OutlineTransparency = 0
	highlight.Parent = character
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and not root:FindFirstChild("EvolutionAura") then
		local aura = Instance.new("ParticleEmitter")
		aura.Name = "EvolutionAura"
		aura.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(100, 220, 255))
		aura.LightEmission = 1
		aura.Rate = 22
		aura.Lifetime = NumberRange.new(0.5, 1.2)
		aura.Speed = NumberRange.new(1, 3)
		aura.SpreadAngle = Vector2.new(360, 360)
		aura.Parent = root
	end
end

function EvolutionService.Start(config)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
	local remote = remotes:FindFirstChild("EvolutionRemote") or Instance.new("RemoteEvent")
	remote.Name = "EvolutionRemote"
	remote.Parent = remotes
	local busy = {}
	local function refresh(player)
		updateReady(player, config)
	end

	remote.OnServerEvent:Connect(function(player)
		if busy[player] then
			return
		end
		local current = player:GetAttribute("Evolution") or 0
		local nextEvolution = current + 1
		local requirement = config[nextEvolution]
		if not requirement or (player:GetAttribute("Level") or 0) < requirement.Level or (workspace:GetAttribute("HighestWave") or workspace:GetAttribute("Wave") or 0) < requirement.Wave or (player:GetAttribute("Coins") or 0) < requirement.Coins then
			return
		end

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end
		busy[player] = true
		player:SetAttribute("Coins", (player:GetAttribute("Coins") or 0) - requirement.Coins)
		player:SetAttribute("Evolution", nextEvolution)
		player:SetAttribute("AttackMultiplier", requirement.AttackMultiplier)
		player:SetAttribute("HealthMultiplier", requirement.HealthMultiplier)
		player:SetAttribute("EnergyMultiplier", requirement.EnergyMultiplier)
		player:SetAttribute("SpeedMultiplier", requirement.SpeedMultiplier)
		local maxHealth = player:GetAttribute("MaxHealth") or 100
		player:SetAttribute("MaxHealth", maxHealth * requirement.HealthMultiplier)
		player:SetAttribute("AttackPower", (player:GetAttribute("AttackPower") or 25) * requirement.AttackMultiplier)
		player:SetAttribute("MaxEnergy", (player:GetAttribute("MaxEnergy") or 100) * requirement.EnergyMultiplier)
		player:SetAttribute("EvolutionTransforming", true)
		addEvolutionGlow(character)
		for _, scaleName in ipairs({"BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale"}) do
			local scale = humanoid:FindFirstChild(scaleName)
			if not scale then
				scale = Instance.new("NumberValue")
				scale.Name = scaleName
				scale.Value = 1
			end
			scale.Value *= 1.1
			scale.Parent = humanoid
		end
		humanoid.WalkSpeed = 0
		task.wait(config.TransformationSeconds)
		if humanoid.Parent and humanoid.Health > 0 then
			humanoid.WalkSpeed = 16 * requirement.SpeedMultiplier
			humanoid.MaxHealth = player:GetAttribute("MaxHealth") or humanoid.MaxHealth
			humanoid.Health = humanoid.MaxHealth
		end
		player:SetAttribute("EvolutionTransforming", false)
		busy[player] = nil
		refresh(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		for _, attribute in ipairs({"Level", "Coins", "Evolution"}) do
			player:GetAttributeChangedSignal(attribute):Connect(function()
				refresh(player)
			end)
		end
		refresh(player)
	end
	Players.PlayerAdded:Connect(function(player)
		for _, attribute in ipairs({"Level", "Coins", "Evolution"}) do
			player:GetAttributeChangedSignal(attribute):Connect(function()
				refresh(player)
			end)
		end
		refresh(player)
	end)
	for _, attribute in ipairs({"HighestWave", "Wave"}) do
		workspace:GetAttributeChangedSignal(attribute):Connect(function()
			for _, player in ipairs(Players:GetPlayers()) do
				refresh(player)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
end

return EvolutionService