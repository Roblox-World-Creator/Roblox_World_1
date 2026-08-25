local Players = game:GetService("Players")

local FlameBooster = {}

local flameTexture = "rbxassetid://243660364"

local function createPlatform(spawnLocation, config)
	local booster = workspace:FindFirstChild(config.Name)
	if not booster then
		booster = Instance.new("Part")
		booster.Name = config.Name
		booster.Anchored = true
		booster.CanCollide = true
		booster.Size = config.Size
		booster.Material = Enum.Material.Neon
		booster.Color = config.PlatformColor

		if spawnLocation and spawnLocation:IsA("BasePart") then
			booster.CFrame = spawnLocation.CFrame + spawnLocation.CFrame.LookVector * config.SpawnOffset + Vector3.new(0, 1, 0)
		else
			booster.Position = config.FallbackPosition
		end

		booster.Parent = workspace
	end

	local fire = booster:FindFirstChild("BoosterFire")
	if not fire then
		fire = Instance.new("Fire")
		fire.Name = "BoosterFire"
		fire.Color = config.FireColor
		fire.SecondaryColor = config.FireSecondaryColor
		fire.Heat = 8
		fire.Size = 10
		fire.Parent = booster
	end

	local light = booster:FindFirstChild("BoosterLight")
	if not light then
		light = Instance.new("PointLight")
		light.Name = "BoosterLight"
		light.Color = config.LightColor
		light.Brightness = 2
		light.Range = 18
		light.Parent = booster
	end

	return booster
end

local function createFlameTrail(rootPart, config)
	local attachment = Instance.new("Attachment")
	attachment.Name = "FlameTrailAttachment"
	attachment.Position = Vector3.new(0, 0, 1.5)
	attachment.Parent = rootPart

	local flames = Instance.new("ParticleEmitter")
	flames.Name = "FlameTrail"
	flames.Texture = flameTexture
	flames.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 235, 80)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 100, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 25, 10)),
	})
	flames.LightEmission = 0.8
	flames.Lifetime = NumberRange.new(0.25, 0.55)
	flames.Rate = config.ParticleRate
	flames.Rotation = NumberRange.new(0, 360)
	flames.RotSpeed = NumberRange.new(-120, 120)
	flames.Speed = NumberRange.new(1, 3)
	flames.SpreadAngle = Vector2.new(25, 25)
	flames.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(1, 0),
	})
	flames.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.75, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	flames.Parent = attachment

	return attachment
end

local function applyBoost(player, character, humanoid, config, activeBoosts)
	if activeBoosts[player] then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	activeBoosts[player] = true
	local originalWalkSpeed = humanoid.WalkSpeed
	local flameTrail = createFlameTrail(rootPart, config)
	local flame = Instance.new("Fire")
	flame.Name = "BoosterFlames"
	flame.Color = config.FireColor
	flame.SecondaryColor = config.FireSecondaryColor
	flame.Heat = 6
	flame.Size = 5
	flame.Parent = rootPart

	local light = Instance.new("PointLight")
	light.Name = "BoosterGlow"
	light.Color = config.LightColor
	light.Brightness = 1.5
	light.Range = 12
	light.Parent = rootPart

	humanoid.WalkSpeed = config.BoostedWalkSpeed
	task.delay(config.Duration, function()
		if humanoid.Parent and humanoid.WalkSpeed == config.BoostedWalkSpeed then
			humanoid.WalkSpeed = originalWalkSpeed
		end
		if flameTrail.Parent then
			flameTrail:Destroy()
		end
		if flame.Parent then
			flame:Destroy()
		end
		if light.Parent then
			light:Destroy()
		end
		activeBoosts[player] = nil
	end)
end

function FlameBooster.Start(config)
	local activeBoosts = {}
	local booster = createPlatform(workspace:FindFirstChild("SpawnLocation"), config)

	booster.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if player and humanoid then
			applyBoost(player, character, humanoid, config, activeBoosts)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		activeBoosts[player] = nil
	end)
end

return FlameBooster