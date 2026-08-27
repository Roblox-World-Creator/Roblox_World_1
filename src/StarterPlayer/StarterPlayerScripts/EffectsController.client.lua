local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local effectsRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AbilityEffects")
local localPlayer = Players.LocalPlayer
local effectsFolder = workspace:FindFirstChild("ClientEffects") or Instance.new("Folder")
effectsFolder.Name = "ClientEffects"
effectsFolder.Parent = workspace

local ENERGY_COLOR = Color3.fromRGB(80, 220, 255)

local POWER_COLORS = {
	EnergyBolt = Color3.fromRGB(80, 220, 255),
	EnergyBurst = Color3.fromRGB(120, 245, 255),
	EnergyBeam = Color3.fromRGB(95, 245, 255),
	GravityPulse = Color3.fromRGB(185, 95, 255),
	ChainLightning = Color3.fromRGB(255, 235, 90),
	Tornado = Color3.fromRGB(170, 210, 255),
	FireBolt = Color3.fromRGB(255, 85, 35), FlameWave = Color3.fromRGB(255, 115, 40), Meteor = Color3.fromRGB(255, 175, 55),
	IceShard = Color3.fromRGB(95, 220, 255), FrostNova = Color3.fromRGB(185, 245, 255), Blizzard = Color3.fromRGB(115, 180, 255),
	LightningBolt = Color3.fromRGB(255, 240, 80), Thunderstorm = Color3.fromRGB(175, 215, 255),
	RockShot = Color3.fromRGB(170, 120, 65), GroundSlam = Color3.fromRGB(120, 210, 100), Boulder = Color3.fromRGB(140, 95, 55),
	GravityPull = Color3.fromRGB(190, 95, 255), GravityWell = Color3.fromRGB(145, 65, 230), BlackHole = Color3.fromRGB(85, 25, 135),
}

local announcementGui = Instance.new("ScreenGui")
announcementGui.Name = "CombatAnnouncements"
announcementGui.ResetOnSpawn = false
announcementGui.DisplayOrder = 115
announcementGui.Parent = localPlayer:WaitForChild("PlayerGui")

if localPlayer:GetAttribute("EffectQuality") == nil then
	localPlayer:SetAttribute("EffectQuality", "HIGH")
end
if localPlayer:GetAttribute("CameraShakeEnabled") == nil then
	localPlayer:SetAttribute("CameraShakeEnabled", true)
end
if localPlayer:GetAttribute("DamageNumbersEnabled") == nil then
	localPlayer:SetAttribute("DamageNumbersEnabled", true)
end

local function highQualityEffects()
	return localPlayer:GetAttribute("EffectQuality") ~= "LOW"
end

local function shakeCamera(origin, radius, intensity)
	if not localPlayer:GetAttribute("CameraShakeEnabled") or not highQualityEffects() then
		return
	end
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or (root.Position - origin).Magnitude > radius then
		return
	end
	task.spawn(function()
		local originalOffset = humanoid.CameraOffset
		for step = 1, 5 do
			if not humanoid.Parent then
				return
			end
			local strength = intensity * (1 - step / 6)
			humanoid.CameraOffset = originalOffset + Vector3.new(
				(math.random() - 0.5) * strength,
				(math.random() - 0.5) * strength,
				0
			)
			task.wait(0.025)
		end
		if humanoid.Parent then
			humanoid.CameraOffset = originalOffset
		end
	end)
end

local function createEffectPart(name, shape, color, size, cframe)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = effectsFolder
	return part
end

local function renderRing(name, position, radius, color, duration)
	local ring = createEffectPart(
		name,
		Enum.PartType.Cylinder,
		color,
		Vector3.new(0.18, 1, 1),
		CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	)
	ring.Transparency = 0.08
	TweenService:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.05, radius * 2, radius * 2),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, duration + 0.05)
	return ring
end

local function renderImpact(position, radius)
	local sphere = createEffectPart(
		"EnergyImpact",
		Enum.PartType.Ball,
		ENERGY_COLOR,
		Vector3.one,
		CFrame.new(position)
	)
	sphere.Transparency = 0.15
	TweenService:Create(sphere, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * radius * 2,
		Transparency = 1,
	}):Play()
	renderRing("EnergyImpactRing", position - Vector3.new(0, 1.2, 0), radius * 1.35, Color3.fromRGB(190, 250, 255), 0.38)
	shakeCamera(position, radius * 4, 0.35)
	Debris:AddItem(sphere, 0.35)
end

local function renderEnergyBolt(data)
	if typeof(data.Origin) ~= "Vector3" or typeof(data.Target) ~= "Vector3" then
		return
	end
	local projectileColor = POWER_COLORS[data.Ability] or ENERGY_COLOR
	local projectile = createEffectPart(
		"EnergyBolt",
		Enum.PartType.Ball,
		projectileColor,
		Vector3.new(1.4, 1.4, 1.4),
		CFrame.new(data.Origin)
	)
	local light = Instance.new("PointLight")
	light.Color = projectileColor
	light.Brightness = 2
	light.Range = 10
	light.Parent = projectile
	if highQualityEffects() then
		local back = Instance.new("Attachment")
		back.Position = Vector3.new(0, 0, 0.6)
		back.Parent = projectile
		local front = Instance.new("Attachment")
		front.Position = Vector3.new(0, 0, -0.6)
		front.Parent = projectile
		local trail = Instance.new("Trail")
		trail.Attachment0 = back
		trail.Attachment1 = front
		trail.Color = ColorSequence.new(Color3.fromRGB(230, 255, 255), projectileColor)
		trail.Transparency = NumberSequence.new(0.05, 1)
		trail.WidthScale = NumberSequence.new(1, 0)
		trail.LightEmission = 1
		trail.Lifetime = 0.22
		trail.Parent = projectile
	end
	local duration = tonumber(data.Duration) or 0.25
	if tonumber(data.ImpactTime) then
		duration = data.ImpactTime - workspace:GetServerTimeNow()
	end
	duration = math.clamp(duration, 0.03, 2)
	local tween = TweenService:Create(projectile, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Position = data.Target,
		Size = Vector3.new(2.1, 2.1, 2.1),
	})
	tween:Play()
	tween.Completed:Connect(function()
		if projectile.Parent then
			projectile:Destroy()
			renderImpact(data.Target, tonumber(data.Radius) or 4)
			renderRing("EnergyImpactOuter", data.Target, (tonumber(data.Radius) or 4) * 1.8, Color3.fromRGB(80, 220, 255), 0.55)
			if highQualityEffects() then
				for index = 1, 4 do
					task.delay(index * 0.035, function()
						renderRing("EnergyImpactPulse", data.Target + Vector3.new(0, index * 0.35, 0), (tonumber(data.Radius) or 4) * (0.65 + index * 0.2), Color3.fromRGB(230, 255, 255), 0.28)
					end)
				end
			end
		end
	end)
	Debris:AddItem(projectile, duration + 0.2)
end

local function renderTornadoTravel(data)
	if typeof(data.Origin) ~= "Vector3" or typeof(data.Target) ~= "Vector3" then return end
	local vortex = createEffectPart("TornadoTravel", Enum.PartType.Ball, Color3.fromRGB(150, 220, 255), Vector3.new(3, 3, 3), CFrame.new(data.Origin))
	vortex.Transparency = 0.2
	local duration = math.clamp((tonumber(data.ImpactTime) or 0) - workspace:GetServerTimeNow(), 0.05, 2)
	TweenService:Create(vortex, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Position = data.Target, Size = Vector3.new(7, 7, 7), Transparency = 0.85}):Play()
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = Color3.fromRGB(120, 210, 255), 18, 3
	light.Parent = vortex
	Debris:AddItem(vortex, duration + 0.1)
end

local function renderTornado(data)
	if typeof(data.Origin) ~= "Vector3" then return end
	local radius = math.clamp(tonumber(data.Radius) or 16, 4, 60)
	local duration = math.clamp(tonumber(data.Duration) or 4, 0.5, 8)
	if data.Ability == "BlackHole" then
		local core = createEffectPart("BlackHoleCore", Enum.PartType.Ball, Color3.fromRGB(25, 5, 45), Vector3.one * 2, CFrame.new(data.Origin + Vector3.new(0, 3, 0)))
		core.Transparency = 0.05
		local light = Instance.new("PointLight")
		light.Color, light.Brightness, light.Range, light.Parent = Color3.fromRGB(185, 75, 255), 4, radius * 2, core
		TweenService:Create(core, TweenInfo.new(0.45, Enum.EasingStyle.Back), {Size = Vector3.one * radius * 0.65}):Play()
		for index = 1, highQualityEffects() and 8 or 4 do
			local ring = renderRing("SingularityOrbit", data.Origin + Vector3.new(0, 1 + index * 0.35, 0), radius * (0.35 + index * 0.07), index % 2 == 0 and Color3.fromRGB(195, 85, 255) or Color3.fromRGB(65, 20, 105), math.min(duration, 1.2))
			ring.CFrame *= CFrame.Angles(math.rad(index * 13), 0, math.rad(index * 9))
		end
		Debris:AddItem(core, duration)
		shakeCamera(data.Origin, radius * 3, 0.9)
		return
	end
	local core = createEffectPart("RiftTornado", Enum.PartType.Cylinder, Color3.fromRGB(135, 205, 255), Vector3.new(2, 8, 8), CFrame.new(data.Origin + Vector3.new(0, 4, 0)))
	core.Transparency = 0.4
	local rings = {}
	for index = 1, 5 do
		local ring = createEffectPart("TornadoVortex", Enum.PartType.Cylinder, Color3.fromRGB(190, 240, 255), Vector3.new(0.28, radius * (1 - index * 0.1), radius * (1 - index * 0.1)), CFrame.new(data.Origin + Vector3.new(0, index * 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)))
		ring.Transparency = 0.22
		table.insert(rings, ring)
	end
	renderRing("TornadoGround", data.Origin - Vector3.new(0, 2.5, 0), radius, Color3.fromRGB(100, 180, 255), 0.5)
	task.spawn(function()
		local endAt = os.clock() + duration
		while os.clock() < endAt and core.Parent do
			for index, ring in ipairs(rings) do
				ring.CFrame = CFrame.new(data.Origin + Vector3.new(0, index * 1.5, 0)) * CFrame.Angles(0, os.clock() * (index % 2 == 0 and 5 or -5), 0)
			end
			task.wait(0.05)
		end
	end)
	Debris:AddItem(core, duration + 0.1)
	for _, ring in ipairs(rings) do Debris:AddItem(ring, duration + 0.1) end
	shakeCamera(data.Origin, radius * 3, 0.5)
end

local function renderEnergyBurst(data)
	if typeof(data.Origin) ~= "Vector3" then
		return
	end
	local radius = math.clamp(tonumber(data.Radius) or 12, 1, 60)
	local sphere = createEffectPart(
		"EnergyBurst",
		Enum.PartType.Ball,
		ENERGY_COLOR,
		Vector3.new(2, 2, 2),
		CFrame.new(data.Origin)
	)
	sphere.Transparency = 0.35
	TweenService:Create(sphere, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.one * radius * 2,
		Transparency = 1,
	}):Play()

	renderRing("EnergyBurstRing", data.Origin - Vector3.new(0, 2.5, 0), radius * 1.2, Color3.fromRGB(170, 245, 255), 0.45)
	if highQualityEffects() then
		task.delay(0.08, function()
			renderRing("EnergyBurstEcho", data.Origin - Vector3.new(0, 2.45, 0), radius * 0.9, Color3.fromRGB(90, 150, 255), 0.38)
		end)
	end
	shakeCamera(data.Origin, radius * 3, 0.65)
	Debris:AddItem(sphere, 0.5)
end

local function renderPowerCast(data)
	if typeof(data.Origin) ~= "Vector3" or typeof(data.Target) ~= "Vector3" then return end
	local color = POWER_COLORS[data.Ability] or ENERGY_COLOR
	local radius = data.Mode == "Close" and 5 or 2.5
	renderRing("PowerCastRing", data.Origin - Vector3.new(0, 1.5, 0), radius, color, 0.22)
	local distance = (data.Target - data.Origin).Magnitude
	if data.Mode == "Ranged" and distance > 2 then
		local tracer = createEffectPart("PowerCastTravel", Enum.PartType.Block, color, Vector3.new(0.3, 0.3, distance), CFrame.lookAt(data.Origin:Lerp(data.Target, 0.5), data.Target))
		tracer.Transparency = 0.25
		TweenService:Create(tracer, TweenInfo.new(tonumber(data.Duration) or 0.24, Enum.EasingStyle.Linear), {Transparency = 1, Size = Vector3.new(0.08, 0.08, distance)}):Play()
		Debris:AddItem(tracer, (tonumber(data.Duration) or 0.24) + 0.05)
	end
	renderRing("PowerCastImpact", data.Target - Vector3.new(0, 1.2, 0), radius * 1.4, color, 0.3)
end

local function renderLocalPower(data)
	if typeof(data.Origin) ~= "Vector3" then return end
	local ability = tostring(data.Ability or "EnergyBolt")
	local color = POWER_COLORS[ability] or ENERGY_COLOR
	local radius = math.clamp(tonumber(data.Radius) or 12, 4, 40)

	-- Every LT form has its own readable silhouette while keeping the common color language.
	if ability == "GravityPulse" then
		for index = 1, highQualityEffects() and 4 or 2 do
			task.delay((index - 1) * 0.055, function()
				local shell = createEffectPart("LocalGravityShell", Enum.PartType.Ball, color, Vector3.one * radius * 2, CFrame.new(data.Origin + Vector3.new(0, 2, 0)))
				shell.Transparency = 0.76
				TweenService:Create(shell, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = Vector3.one * 0.5, Transparency = 1}):Play()
				Debris:AddItem(shell, 0.48)
			end)
		end
	elseif ability == "Tornado" then
		for index = 1, highQualityEffects() and 6 or 3 do
			local height = index * 1.1
			local ring = createEffectPart("LocalTornadoCoil", Enum.PartType.Cylinder, color, Vector3.new(0.18, radius * (1 - index * 0.045), radius * (1 - index * 0.045)), CFrame.new(data.Origin + Vector3.new(0, height, 0)) * CFrame.Angles(0, 0, math.rad(90)))
			ring.Transparency = 0.3
			TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {CFrame = ring.CFrame * CFrame.Angles(math.rad(180), 0, 0), Transparency = 1}):Play()
			Debris:AddItem(ring, 0.55)
		end
	elseif ability == "EnergyBeam" then
		for index = 0, 3 do
			local slash = createEffectPart("LocalBeamBlade", Enum.PartType.Block, color, Vector3.new(0.22, 0.75, radius * 2), CFrame.new(data.Origin + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.rad(index * 45), math.rad(18)))
			slash.Transparency = 0.18
			TweenService:Create(slash, TweenInfo.new(0.3), {Size = Vector3.new(0.04, 0.12, radius * 2.5), Transparency = 1}):Play()
			Debris:AddItem(slash, 0.35)
		end
	elseif ability == "ChainLightning" then
		for index = 1, highQualityEffects() and 10 or 6 do
			local angle = (index / (highQualityEffects() and 10 or 6)) * math.pi * 2
			local direction = Vector3.new(math.cos(angle), math.sin(angle * 2) * 0.18, math.sin(angle))
			local start = data.Origin + Vector3.new(0, 2, 0)
			local finish = start + direction * radius
			local arc = createEffectPart("LocalLightningArc", Enum.PartType.Block, color, Vector3.new(0.22, 0.22, radius), CFrame.lookAt(start:Lerp(finish, 0.5), finish))
			arc.Transparency = 0.12
			TweenService:Create(arc, TweenInfo.new(0.24), {Transparency = 1}):Play()
			Debris:AddItem(arc, 0.28)
		end
	elseif ability == "EnergyBolt" then
		for index = 1, highQualityEffects() and 8 or 4 do
			local angle = index / (highQualityEffects() and 8 or 4) * math.pi * 2
			local orb = createEffectPart("LocalEnergyOrb", Enum.PartType.Ball, color, Vector3.one * 1.25, CFrame.new(data.Origin + Vector3.new(math.cos(angle) * 3, 2.2, math.sin(angle) * 3)))
			TweenService:Create(orb, TweenInfo.new(0.34, Enum.EasingStyle.Back), {Position = data.Origin + Vector3.new(math.cos(angle) * radius, 1.5, math.sin(angle) * radius), Size = Vector3.one * 0.2, Transparency = 1}):Play()
			Debris:AddItem(orb, 0.4)
		end
	else
		local sphere = createEffectPart("LocalEnergyBurst", Enum.PartType.Ball, color, Vector3.one * 2, CFrame.new(data.Origin + Vector3.new(0, 1.5, 0)))
		sphere.Transparency = 0.42
		TweenService:Create(sphere, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = Vector3.one * radius * 2, Transparency = 1}):Play()
		Debris:AddItem(sphere, 0.44)
	end

	renderRing("LocalPowerInner", data.Origin - Vector3.new(0, 2.4, 0), radius * 0.72, Color3.new(1, 1, 1), 0.3)
	renderRing("LocalPowerOuter", data.Origin - Vector3.new(0, 2.35, 0), radius, color, 0.48)
	shakeCamera(data.Origin, radius * 3, (ability == "GravityPulse" or ability == "Tornado") and 0.85 or 0.55)
end

local function renderMelee(data)
	if typeof(data.Origin) ~= "Vector3" or typeof(data.Direction) ~= "Vector3" then
		return
	end
	local center = data.Origin + data.Direction * 5 + Vector3.new(0, 1.5, 0)
	local combo = math.clamp(tonumber(data.Combo) or 1, 1, 4)
	local slash = createEffectPart(
		"SwordSlash",
		Enum.PartType.Block,
		Color3.fromRGB(205, 235, 255),
		Vector3.new(0.18, 5, 8),
		CFrame.lookAt(center, center + data.Direction) * CFrame.Angles(0, 0, math.rad(combo % 2 == 0 and -55 or 55))
	)
	slash.Transparency = 0.2
	TweenService:Create(slash, TweenInfo.new(0.18), {
		Transparency = 1,
		Size = Vector3.new(0.05, 7, 10),
	}):Play()
	if highQualityEffects() then
		local echo = slash:Clone()
		echo.Name = "SwordSlashEcho"
		echo.Color = Color3.fromRGB(90, 185, 255)
		echo.Transparency = 0.55
		echo.CFrame = echo.CFrame * CFrame.Angles(math.rad(12), 0, 0)
		echo.Parent = effectsFolder
		TweenService:Create(echo, TweenInfo.new(0.22), {
			Transparency = 1,
			Size = Vector3.new(0.04, 8, 11),
		}):Play()
		Debris:AddItem(echo, 0.26)
	end
	Debris:AddItem(slash, 0.22)

	local character = data.Character
	local grip = typeof(character) == "Instance" and character:FindFirstChild("SwordGrip", true)
	if grip and grip:IsA("Motor6D") then
		local startPoses = {
			CFrame.Angles(math.rad(-18), math.rad(-24), math.rad(72)),
			CFrame.Angles(math.rad(-8), math.rad(28), math.rad(-68)),
			CFrame.Angles(math.rad(-78), math.rad(-10), math.rad(26)),
			CFrame.new(0, 0, 0.45) * CFrame.Angles(math.rad(-82), 0, 0),
		}
		local endPoses = {
			CFrame.Angles(math.rad(18), math.rad(28), math.rad(-58)),
			CFrame.Angles(math.rad(12), math.rad(-26), math.rad(58)),
			CFrame.Angles(math.rad(42), math.rad(12), math.rad(-24)),
			CFrame.new(0, 0, -1.25) * CFrame.Angles(math.rad(-88), 0, 0),
		}
		grip.Transform = startPoses[combo]
		local duration = combo == 4 and 0.19 or 0.16
		local swing = TweenService:Create(grip, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transform = endPoses[combo],
		})
		local shoulder = character:FindFirstChild("RightShoulder", true) or character:FindFirstChild("Right Shoulder", true)
		if shoulder and shoulder:IsA("Motor6D") then
			shoulder.Transform = combo == 4 and CFrame.Angles(math.rad(-55), 0, math.rad(8)) or CFrame.Angles(math.rad(-28), math.rad(combo % 2 == 0 and -22 or 22), math.rad(combo % 2 == 0 and -18 or 18))
			TweenService:Create(shoulder, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transform = combo == 4 and CFrame.Angles(math.rad(-86), 0, 0) or CFrame.Angles(math.rad(-12), math.rad(combo % 2 == 0 and 28 or -28), math.rad(combo % 2 == 0 and 24 or -24)),
			}):Play()
		end
		swing:Play()
		swing.Completed:Connect(function()
			if grip.Parent then
				TweenService:Create(grip, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {Transform = CFrame.identity}):Play()
			end
			if shoulder and shoulder.Parent then TweenService:Create(shoulder, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {Transform = CFrame.identity}):Play() end
		end)
	end
end

local function renderDamageNumber(data)
	if not localPlayer:GetAttribute("DamageNumbersEnabled") then
		return
	end
	local target = data.Target
	local root = typeof(target) == "Instance" and target:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "LocalDamageNumber"
	gui.Adornee = root
	gui.Size = UDim2.fromOffset(110, 34)
	gui.StudsOffset = Vector3.new(math.random(-12, 12) / 10, 3, 0)
	gui.AlwaysOnTop = true
	gui.Parent = effectsFolder
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = string.format("-%d", math.floor(tonumber(data.Amount) or 0))
	local elementColors = {Fire = Color3.fromRGB(255, 105, 45), Ice = Color3.fromRGB(120, 225, 255), Lightning = Color3.fromRGB(255, 240, 90), Earth = Color3.fromRGB(145, 210, 105), Gravity = Color3.fromRGB(195, 100, 255)}
	label.TextColor3 = data.Critical and Color3.fromRGB(255, 105, 75) or elementColors[data.Element] or Color3.fromRGB(255, 225, 105)
	label.Text = data.Critical and ("CRIT " .. label.Text) or label.Text
	label.TextStrokeColor3 = Color3.fromRGB(55, 15, 15)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
	TweenService:Create(gui, TweenInfo.new(0.7), {StudsOffset = gui.StudsOffset + Vector3.new(0, 2, 0)}):Play()
	TweenService:Create(label, TweenInfo.new(0.7), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	Debris:AddItem(gui, 0.75)
end

local function renderEnemyDamaged(data)
	local target = data.Target
	if typeof(target) ~= "Instance" or not target:IsA("Model") then
		return
	end
	local highlight = Instance.new("Highlight")
	highlight.Name = "LocalHitFlash"
	highlight.Adornee = target
	highlight.FillColor = Color3.fromRGB(255, 245, 225)
	highlight.FillTransparency = 0.15
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = effectsFolder
	Debris:AddItem(highlight, data.Heavy and 0.18 or 0.1)
end

local function renderDefenseEffect(name, data)
	if typeof(data.Origin) ~= "Vector3" then
		return
	end
	local colors = {
		BlockImpact = Color3.fromRGB(100, 180, 255),
		PerfectBlock = Color3.fromRGB(255, 235, 90),
		DodgeAvoid = Color3.fromRGB(190, 245, 255),
	}
	local color = colors[name] or Color3.new(1, 1, 1)
	renderRing(name, data.Origin, name == "PerfectBlock" and 8 or 5, color, 0.28)
	if name == "PerfectBlock" then
		shakeCamera(data.Origin, 25, 0.75)
	end
end

local function renderDodge(data)
	if typeof(data.Origin) ~= "Vector3" or typeof(data.Direction) ~= "Vector3" then
		return
	end
	local length = 9
	local streak = createEffectPart(
		"DodgeStreak",
		Enum.PartType.Block,
		Color3.fromRGB(165, 235, 255),
		Vector3.new(2.5, 3.5, length),
		CFrame.lookAt(data.Origin - data.Direction * length / 2, data.Origin + data.Direction)
	)
	streak.Transparency = 0.55
	TweenService:Create(streak, TweenInfo.new(0.2), {Transparency = 1, Size = Vector3.new(0.2, 0.2, length * 1.4)}):Play()
	Debris:AddItem(streak, 0.24)
end

local function renderFinisher(data)
	if typeof(data.Origin) ~= "Vector3" then
		return
	end
	renderRing("FinisherImpact", data.Origin - Vector3.new(0, 1.3, 0), 10, Color3.fromRGB(255, 235, 135), 0.35)
	renderImpact(data.Origin, 6)
	shakeCamera(data.Origin, 35, 0.9)
end

local function renderAnnouncement(data)
	local container = Instance.new("Frame")
	container.Size = UDim2.fromOffset(520, 82)
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.Position = UDim2.new(0.5, 0, 0.18, 0)
	container.BackgroundTransparency = 1
	container.Parent = announcementGui
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 48)
	title.BackgroundTransparency = 1
	title.Text = tostring(data.Title or "")
	title.TextColor3 = typeof(data.Color) == "Color3" and data.Color or Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0.15
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.Parent = container
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0, 28)
	subtitle.Position = UDim2.fromOffset(0, 50)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = tostring(data.Subtitle or "")
	subtitle.TextColor3 = Color3.fromRGB(235, 245, 255)
	subtitle.TextStrokeTransparency = 0.35
	subtitle.Font = Enum.Font.GothamBold
	subtitle.TextScaled = true
	subtitle.Parent = container
	container.Position += UDim2.fromOffset(0, 15)
	TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Position = container.Position - UDim2.fromOffset(0, 15)}):Play()
	task.delay(2.1, function()
		if container.Parent then
			TweenService:Create(title, TweenInfo.new(0.35), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
			TweenService:Create(subtitle, TweenInfo.new(0.35), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
			Debris:AddItem(container, 0.4)
		end
	end)
end

local function renderBossPhase(data)
	local boss = data.Boss
	local root = typeof(boss) == "Instance" and boss:FindFirstChild("HumanoidRootPart")
	if root then
		renderImpact(root.Position, tonumber(data.Phase) and 9 + data.Phase * 2 or 12)
		shakeCamera(root.Position, 80, 1.1)
	end
	renderAnnouncement({
		Title = string.format("BOSS PHASE %d", tonumber(data.Phase) or 2),
		Subtitle = "THE ENEMY IS EVOLVING",
		Color = Color3.fromRGB(255, 80, 115),
	})
end

local function renderBossSlam(effectName, data)
	if typeof(data.Origin) ~= "Vector3" then
		return
	end
	local radius = tonumber(data.Radius) or 20
	if effectName == "BossSlamTelegraph" then
		renderRing(effectName, data.Origin - Vector3.new(0, 1.5, 0), radius, Color3.fromRGB(255, 55, 80), tonumber(data.Duration) or 0.9)
	else
		renderRing(effectName, data.Origin - Vector3.new(0, 1.4, 0), radius * 1.2, Color3.fromRGB(255, 130, 60), 0.45)
		renderImpact(data.Origin, radius * 0.55)
		shakeCamera(data.Origin, radius * 4, 1.25)
	end
end

local function renderEnemyTelegraph(data)
	if typeof(data.Origin) ~= "Vector3" then
		return
	end
	local duration = math.clamp(tonumber(data.Duration) or 0.4, 0.1, 1.5)
	local radius = math.clamp(tonumber(data.Radius) or 6, 2, 20)
	local color = typeof(data.Color) == "Color3" and data.Color or Color3.fromRGB(255, 70, 70)
	local ring = renderRing("EnemyAttackTelegraph", data.Origin - Vector3.new(0, 1.4, 0), radius, color, duration)
	ring.Transparency = 0.35
	if data.Style == "Ranged" and typeof(data.Target) == "Vector3" then
		local midpoint = data.Origin:Lerp(data.Target, 0.5) + Vector3.new(0, 1.5, 0)
		local lane = createEffectPart("EnemyRangedLane", Enum.PartType.Block, color, Vector3.new(0.25, 0.25, (data.Target - data.Origin).Magnitude), CFrame.lookAt(midpoint, data.Target + Vector3.new(0, 1.5, 0)))
		lane.Transparency = 0.3
		TweenService:Create(lane, TweenInfo.new(duration), {Transparency = 0.9, Size = Vector3.new(0.7, 0.7, lane.Size.Z)}):Play()
		Debris:AddItem(lane, duration + 0.05)
	end
	local warning = createEffectPart(
		"EnemyAttackWarning",
		Enum.PartType.Ball,
		color,
		Vector3.new(1, 1, 1),
		CFrame.new(data.Origin + Vector3.new(0, 2.5, 0))
	)
	warning.Transparency = 0.2
	TweenService:Create(warning, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = Vector3.new(2.5, 2.5, 2.5),
		Transparency = 0.75,
	}):Play()
	Debris:AddItem(warning, duration + 0.05)
end

local function renderEnemyHit(data)
	if typeof(data.Origin) ~= "Vector3" then
		return
	end
	local flash = createEffectPart(
		"EnemyHit",
		Enum.PartType.Ball,
		typeof(data.Color) == "Color3" and data.Color or Color3.fromRGB(255, 85, 65),
		Vector3.new(1, 1, 1),
		CFrame.new(data.Origin)
	)
	TweenService:Create(flash, TweenInfo.new(0.18), {
		Size = Vector3.new(5, 5, 5),
		Transparency = 1,
	}):Play()
	shakeCamera(data.Origin, 18, 0.5)
	Debris:AddItem(flash, 0.22)
end

local function renderBeam(data, color, lifetime, thickness)
	if typeof(data.Origin) ~= "Vector3" or typeof(data.Target) ~= "Vector3" then return end
	local offset = data.Target - data.Origin
	if offset.Magnitude <= 0 then return end
	local beam = createEffectPart("EnergyBeam", Enum.PartType.Block, color, Vector3.new(thickness, thickness, offset.Magnitude), CFrame.lookAt(data.Origin:Lerp(data.Target, 0.5), data.Target))
	beam.Transparency = 0.08
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Parent = color, 18, 2, beam
	TweenService:Create(beam, TweenInfo.new(lifetime), {Transparency = 1, Size = Vector3.new(thickness * 2.2, thickness * 2.2, offset.Magnitude)}):Play()
	Debris:AddItem(beam, lifetime + 0.05)
end

local function renderGravityPulse(data)
	if typeof(data.Origin) ~= "Vector3" then return end
	local radius = tonumber(data.Radius) or 20
	for index = 1, highQualityEffects() and 4 or 2 do
		task.delay((index - 1) * 0.08, function()
			local sphere = createEffectPart("GravityPulse", Enum.PartType.Ball, Color3.fromRGB(170, 75, 255), Vector3.new(radius * 2, radius * 2, radius * 2), CFrame.new(data.Origin))
			sphere.Transparency = 0.78
			TweenService:Create(sphere, TweenInfo.new(0.45), {Size = Vector3.new(1, 1, 1), Transparency = 1}):Play()
			Debris:AddItem(sphere, 0.5)
		end)
	end
	shakeCamera(data.Origin, radius * 3, 0.8)
end

local function renderGroundSlam(data)
	if typeof(data.Origin) ~= "Vector3" then return end
	local radius = tonumber(data.Radius) or 16
	for index = 1, highQualityEffects() and 3 or 2 do
		task.delay((index - 1) * 0.07, function() renderRing("SeismicShockwave", data.Origin - Vector3.new(0, 2.2, 0), radius * (0.65 + index * 0.28), Color3.fromRGB(135, 210, 105), 0.42) end)
	end
	for index = 1, highQualityEffects() and 12 or 6 do
		local angle = index / (highQualityEffects() and 12 or 6) * math.pi * 2
		local rock = createEffectPart("SlamDebris", Enum.PartType.Block, Color3.fromRGB(115, 82, 52), Vector3.new(1.2, 1.8, 1.2), CFrame.new(data.Origin + Vector3.new(math.cos(angle) * radius * 0.55, 0, math.sin(angle) * radius * 0.55)))
		TweenService:Create(rock, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = rock.Position + Vector3.new(0, math.random(3, 7), 0), Transparency = 1}):Play()
		Debris:AddItem(rock, 0.45)
	end
	shakeCamera(data.Origin, radius * 4, 1.05)
end

local function renderLightningArc(data)
	if typeof(data.Origin) ~= "Vector3" or typeof(data.Target) ~= "Vector3" then return end
	local points = {data.Origin}
	local segments = highQualityEffects() and 8 or 4
	for index = 1, segments - 1 do
		local alpha = index / segments
		table.insert(points, data.Origin:Lerp(data.Target, alpha) + Vector3.new(math.random(-15, 15) / 10, math.random(-10, 10) / 10, math.random(-15, 15) / 10))
	end
	table.insert(points, data.Target)
	for index = 1, #points - 1 do
		local offset = points[index + 1] - points[index]
		local segment = createEffectPart("SegmentedLightning", Enum.PartType.Block, Color3.fromRGB(255, 240, 105), Vector3.new(0.28, 0.28, offset.Magnitude), CFrame.lookAt(points[index]:Lerp(points[index + 1], 0.5), points[index + 1]))
		TweenService:Create(segment, TweenInfo.new(0.2), {Transparency = 1, Size = Vector3.new(0.05, 0.05, offset.Magnitude)}):Play()
		Debris:AddItem(segment, 0.24)
	end
end

local function renderBossSpecial(effectName, data)
	if effectName == "BossVortexTelegraph" or effectName == "BossVortex" then
		if typeof(data.Origin) ~= "Vector3" then return end
		local color = Color3.fromRGB(165, 65, 255)
		renderRing(effectName, data.Origin - Vector3.new(0, 1.4, 0), data.Radius or 28, color, data.Duration or 0.55)
		if effectName == "BossVortex" then renderGravityPulse(data) end
	elseif effectName == "BossLightningTelegraph" or effectName == "BossLightning" then
		for _, position in ipairs(data.Targets or {}) do
			if typeof(position) == "Vector3" then
				renderRing(effectName, position - Vector3.new(0, 2.5, 0), data.Radius or 8, Color3.fromRGB(80, 185, 255), data.Duration or 0.4)
				if effectName == "BossLightning" then renderBeam({Origin = position + Vector3.new(0, 40, 0), Target = position}, Color3.fromRGB(120, 220, 255), 0.32, 1.4) end
			end
		end
	end
end

effectsRemote.OnClientEvent:Connect(function(effectName, data)
	if type(data) ~= "table" then
		return
	end
	if effectName == "PowerCast" then
		renderPowerCast(data)
	elseif effectName == "PowerLocal" then
		renderLocalPower(data)
	elseif effectName == "EnergyBolt" then
		renderEnergyBolt(data)
	elseif effectName == "TornadoTravel" then
		renderTornadoTravel(data)
	elseif effectName == "TornadoStart" then
		renderTornado(data)
	elseif effectName == "TornadoEnd" then
		if typeof(data.Origin) == "Vector3" then renderRing("TornadoEnd", data.Origin, tonumber(data.Radius) or 16, Color3.fromRGB(220, 250, 255), 0.35) end
	elseif effectName == "EnergyBurst" then
		renderEnergyBurst(data)
	elseif effectName == "EnergyBeam" then
		renderBeam(data, Color3.fromRGB(90, 235, 255), 0.45, tonumber(data.Radius) or 3)
		shakeCamera(data.Origin, 45, 0.65)
	elseif effectName == "GravityPulse" then
		renderGravityPulse(data)
	elseif effectName == "ChainLightning" then
		renderLightningArc(data)
	elseif effectName == "GroundSlam" then
		renderGroundSlam(data)
	elseif effectName == "Melee" then
		renderMelee(data)
	elseif effectName == "EnemyTelegraph" then
		renderEnemyTelegraph(data)
	elseif effectName == "EnemyHit" then
		renderEnemyHit(data)
	elseif effectName == "DamageNumber" then
		renderDamageNumber(data)
	elseif effectName == "EnemyDamaged" then
		renderEnemyDamaged(data)
	elseif effectName == "FinisherImpact" then
		renderFinisher(data)
	elseif effectName == "Dodge" then
		renderDodge(data)
	elseif effectName == "BlockImpact" or effectName == "PerfectBlock" or effectName == "DodgeAvoid" then
		renderDefenseEffect(effectName, data)
	elseif effectName == "WaveAnnouncement" then
		renderAnnouncement(data)
	elseif effectName == "BossPhase" then
		renderBossPhase(data)
	elseif effectName == "BossSlamTelegraph" or effectName == "BossSlam" then
		renderBossSlam(effectName, data)
	elseif effectName == "BossVortexTelegraph" or effectName == "BossVortex" or effectName == "BossLightningTelegraph" or effectName == "BossLightning" then
		renderBossSpecial(effectName, data)
	end
end)
