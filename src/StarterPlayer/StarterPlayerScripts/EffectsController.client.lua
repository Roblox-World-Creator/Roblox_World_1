local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local effectsRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AbilityEffects")
local localPlayer = Players.LocalPlayer
local progressionConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ProgressionConfig"))
local effectsFolder = workspace:FindFirstChild("ClientEffects") or Instance.new("Folder")
effectsFolder.Name = "ClientEffects"
effectsFolder.Parent = workspace

local ENERGY_COLOR = Color3.fromRGB(80, 220, 255)
local ELEMENT_COLORS = {
	Fire = Color3.fromRGB(255, 85, 35), Ice = Color3.fromRGB(95, 220, 255),
	Lightning = Color3.fromRGB(255, 235, 75), Earth = Color3.fromRGB(145, 195, 95),
	Gravity = Color3.fromRGB(180, 80, 255), Poison = Color3.fromRGB(105, 235, 80),
	Prismatic = Color3.fromRGB(255, 105, 220), Arcane = ENERGY_COLOR, Wind = Color3.fromRGB(175, 235, 255),
}

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

-- Built-in Roblox sound content keeps the effect layer self-contained and avoids
-- shipping an unaudited Creator Store model or script. Pitch and timbre are varied
-- per element/cast family so high-tier powers do not all sound identical.
local CAST_SOUNDS = {
	Projectile = "rbxasset://sounds/action_jump.mp3",
	Beam = "rbxasset://sounds/volume_slider.ogg",
	Radial = "rbxasset://sounds/impact_explosion_03.mp3",
	Gravity = "rbxasset://sounds/action_jump_land.mp3",
	Chain = "rbxasset://sounds/volume_slider.ogg",
	Tornado = "rbxasset://sounds/impact_water.mp3",
	Melee = "rbxasset://sounds/swordslash.wav",
}

local function effectColor(data)
	local definition = progressionConfig.Abilities[tostring(data.Ability or "")]
	return POWER_COLORS[data.Ability] or ELEMENT_COLORS[data.Element or (definition and definition.Element)] or ENERGY_COLOR
end
local ELEMENT_PITCH = {Fire = 0.88, Ice = 1.18, Lightning = 1.38, Earth = 0.72, Gravity = 0.58, Poison = 0.96, Prismatic = 1.28, Wind = 1.08, Arcane = 1}
local function playEffectSound(position, data)
	if typeof(position) ~= "Vector3" then return end
	local holder = createEffectPart("EffectSound", Enum.PartType.Ball, Color3.new(), Vector3.new(0.1, 0.1, 0.1), CFrame.new(position))
	holder.Transparency = 1
	local sound = Instance.new("Sound")
	sound.SoundId = CAST_SOUNDS[data.CastType] or CAST_SOUNDS.Projectile
	sound.Volume = math.clamp((data.Impact and 0.42 or 0.32) + (tonumber(data.Tier) or 1) * 0.025, 0.32, 0.68)
	sound.PlaybackSpeed = math.clamp((tonumber(data.SoundPitch) or 1) * (ELEMENT_PITCH[data.Element] or 1) * (data.Impact and 0.82 or 1), 0.5, 1.7)
	sound.RollOffMinDistance, sound.RollOffMaxDistance = 10, 95
	sound.Parent = holder
	sound:Play()
	Debris:AddItem(holder, 4)
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

local function renderUltimateTitle(data, tier, color)
	if tier < 9 then return end
	local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - data.Target).Magnitude > 240 then return end
	local label = Instance.new("TextLabel")
	label.Name = "UltimatePowerTitle"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.27)
	label.Size = UDim2.fromOffset(620, 68)
	label.BackgroundTransparency = 1
	label.Text = "ULTIMATE  •  " .. string.upper(tostring(data.Ability or "ASCENDANT POWER"))
	label.TextColor3 = color
	label.TextStrokeColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.25
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = announcementGui
	label.Rotation = -3
	TweenService:Create(label, TweenInfo.new(0.18, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(760, 82), Rotation = 0}):Play()
	task.delay(0.38, function()
		if label.Parent then TweenService:Create(label, TweenInfo.new(0.4), {TextTransparency = 1, TextStrokeTransparency = 1, Position = UDim2.fromScale(0.5, 0.22)}):Play() end
	end)
	Debris:AddItem(label, 0.85)
end

local function renderTierSpectacle(data, color, tier)
	if tier < 7 or not highQualityEffects() or typeof(data.Target) ~= "Vector3" then return end
	local position = data.Target
	local scale = 1 + (tier - 7) * 0.22
	local radius = (9 + tier * 1.25) * scale
	local white = color:Lerp(Color3.new(1, 1, 1), 0.7)
	local pillarHeight = 80 + tier * 8
	local pillar = createEffectPart("AscendantSkyPillar", Enum.PartType.Cylinder, white, Vector3.new(pillarHeight, 1.5, 1.5), CFrame.new(position + Vector3.new(0, pillarHeight * 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)))
	pillar.Transparency = 0.12
	TweenService:Create(pillar, TweenInfo.new(0.48, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = Vector3.new(pillarHeight, radius * 0.32, radius * 0.32), Transparency = 1}):Play()
	Debris:AddItem(pillar, 0.55)

	local shellColor = data.Element == "Gravity" and Color3.fromRGB(25, 5, 45) or color
	local shell = createEffectPart("AscendantImpactShell", Enum.PartType.Ball, shellColor, Vector3.one * 2, CFrame.new(position + Vector3.new(0, 2, 0)))
	shell.Transparency = data.Element == "Gravity" and 0.08 or 0.3
	TweenService:Create(shell, TweenInfo.new(0.52, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = Vector3.one * radius * 2, Transparency = 1}):Play()
	Debris:AddItem(shell, 0.58)

	for index = 1, math.min(7, tier - 3) do
		task.delay((index - 1) * 0.045, function()
			local ringColor = data.Element == "Prismatic" and Color3.fromHSV((index / 7 + tier * 0.07) % 1, 0.82, 1) or (index % 2 == 0 and white or color)
			local ring = renderRing("AscendantShockwave", position - Vector3.new(0, 1.1 - index * 0.12, 0), radius * (0.45 + index * 0.2), ringColor, 0.38 + index * 0.045)
			ring.CFrame *= CFrame.Angles(math.rad((index % 3 - 1) * 10), 0, math.rad(index * 7))
		end)
	end

	local shardCount = math.min(14, tier + 2)
	for index = 1, shardCount do
		local angle = index / shardCount * math.pi * 2
		local start = position + Vector3.new(math.cos(angle) * 2, 1 + index % 3, math.sin(angle) * 2)
		local shardColor = data.Element == "Prismatic" and Color3.fromHSV(index / shardCount, 0.75, 1) or (index % 2 == 0 and color or white)
		local shape = (data.Element == "Earth" or data.Element == "Ice") and Enum.PartType.Block or Enum.PartType.Ball
		local shard = createEffectPart("AscendantDebris", shape, shardColor, Vector3.one * (0.6 + tier * 0.055), CFrame.new(start) * CFrame.Angles(angle, angle * 0.6, angle * 1.4))
		local finish = start + Vector3.new(math.cos(angle) * radius * 0.9, 7 + (index % 4) * 2.5, math.sin(angle) * radius * 0.9)
		TweenService:Create(shard, TweenInfo.new(0.5 + (index % 3) * 0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = finish, Size = Vector3.one * 0.08, Transparency = 1}):Play()
		Debris:AddItem(shard, 0.75)
	end

	if data.Element == "Lightning" or data.Element == "Prismatic" then
		for index = 1, math.min(5, tier - 5) do
			local angle = index * 2.399
			local strikePosition = position + Vector3.new(math.cos(angle) * radius * 0.42, 0, math.sin(angle) * radius * 0.42)
			local strikeColor = data.Element == "Prismatic" and Color3.fromHSV(index / 5, 0.75, 1) or white
			local strike = createEffectPart("AscendantLightning", Enum.PartType.Block, strikeColor, Vector3.new(0.5, pillarHeight, 0.5), CFrame.new(strikePosition + Vector3.new(0, pillarHeight * 0.5, 0)))
			strike.Transparency = 0.08
			TweenService:Create(strike, TweenInfo.new(0.22), {Size = Vector3.new(2.2, pillarHeight, 2.2), Transparency = 1}):Play()
			Debris:AddItem(strike, 0.28)
		end
	end

	shakeCamera(position, radius * 5, math.min(1.8, 0.7 + tier * 0.08))
	renderUltimateTitle(data, tier, color)
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

local function renderFireImpact(position, radius, ability)
	radius = math.clamp(radius, 3, 45)
	-- A scorched footprint makes fire magic feel anchored to the battlefield instead of
	-- disappearing as soon as the projectile lands.
	local patchCount = highQualityEffects() and 10 or 6
	for index = 1, patchCount do
		local angle = index / patchCount * math.pi * 2 + radius * 0.13
		local distance = radius * (0.15 + ((index * 37) % 70) / 100)
		local width = math.max(2, radius * (0.2 + (index % 3) * 0.055))
		local patchPosition = position + Vector3.new(math.cos(angle) * distance, -1.08, math.sin(angle) * distance)
		local patch = createEffectPart("BurningGround", Enum.PartType.Cylinder, index % 3 == 0 and Color3.fromRGB(255, 174, 32) or Color3.fromRGB(110, 28, 12), Vector3.new(0.12, width, width * 0.72), CFrame.new(patchPosition) * CFrame.Angles(0, angle, math.rad(90)))
		patch.Material = index % 3 == 0 and Enum.Material.Neon or Enum.Material.CrackedLava
		patch.Transparency = index % 3 == 0 and 0.25 or 0.12
		TweenService:Create(patch, TweenInfo.new(1.7 + index * 0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1, Size = Vector3.new(0.08, width * 1.18, width * 0.85)}):Play()
		Debris:AddItem(patch, 2.2)
	end
	local count = highQualityEffects() and 14 or 8
	for index = 1, count do
		local angle = index / count * math.pi * 2
		local distance = radius * (0.25 + (index % 4) * 0.18)
		local base = position + Vector3.new(math.cos(angle) * distance, 0.4, math.sin(angle) * distance)
		local flame = createEffectPart("LivingFlame", Enum.PartType.Ball, index % 3 == 0 and Color3.fromRGB(255, 235, 80) or Color3.fromRGB(255, 70, 18), Vector3.new(0.7, 1.4, 0.7), CFrame.new(base))
		flame.Transparency = 0.08
		TweenService:Create(flame, TweenInfo.new(0.42 + (index % 3) * 0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = base + Vector3.new(math.cos(angle) * 2.5, 4 + index % 4, math.sin(angle) * 2.5),
			Size = Vector3.new(0.12, 0.3, 0.12), Transparency = 1,
		}):Play()
		Debris:AddItem(flame, 0.7)
	end
	if ability == "FlameWave" or string.find(tostring(ability), "Inferno", 1, true) then
		local segments = highQualityEffects() and 18 or 10
		for index = 1, segments do
			local angle = index / segments * math.pi * 2
			local wallPosition = position + Vector3.new(math.cos(angle) * radius * 0.72, 2.3, math.sin(angle) * radius * 0.72)
			local wall = createEffectPart("SpreadingFireWall", Enum.PartType.Block, index % 2 == 0 and Color3.fromRGB(255, 185, 45) or Color3.fromRGB(255, 62, 18), Vector3.new(1.15, 4.8 + index % 3, math.max(2.2, radius * 0.28)), CFrame.lookAt(wallPosition, position))
			wall.Transparency = 0.2
			TweenService:Create(wall, TweenInfo.new(0.65, Enum.EasingStyle.Quad), {Position = wallPosition + Vector3.new(0, 1.5, 0), Size = Vector3.new(0.2, 7, wall.Size.Z * 1.35), Transparency = 1}):Play()
			Debris:AddItem(wall, 0.72)
		end
	elseif ability == "Meteor" or string.find(tostring(ability), "Starfall", 1, true) then
		for index = 1, highQualityEffects() and 5 or 3 do
			local offset = Vector3.new((index - 3) * 2.2, 24 + index * 3, ((index * 7) % 5 - 2) * 2.2)
			local meteor = createEffectPart("FallingMeteor", Enum.PartType.Ball, Color3.fromRGB(255, 92, 22), Vector3.one * (2.5 + index * 0.35), CFrame.new(position + offset))
			meteor.Material = Enum.Material.Neon
			TweenService:Create(meteor, TweenInfo.new(0.28 + index * 0.025, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = position + Vector3.new(offset.X * 0.25, 1, offset.Z * 0.25), Size = Vector3.one * 0.5, Transparency = 0.25}):Play()
			Debris:AddItem(meteor, 0.42)
		end
	end
	renderRing("ScorchFront", position - Vector3.new(0, 1.1, 0), radius * 1.35, Color3.fromRGB(255, 105, 25), 0.55)
	shakeCamera(position, radius * 4, 0.8)
end

local function renderIceImpact(position, radius, ability)
	radius = math.clamp(radius, 3, 45)
	local sheetCount = highQualityEffects() and 12 or 7
	for index = 1, sheetCount do
		local angle = index / sheetCount * math.pi * 2 + 0.35
		local distance = radius * (0.12 + ((index * 29) % 72) / 100)
		local width = math.max(2.2, radius * (0.18 + (index % 4) * 0.04))
		local sheetPosition = position + Vector3.new(math.cos(angle) * distance, -1.06, math.sin(angle) * distance)
		local sheet = createEffectPart("FrozenGround", Enum.PartType.Cylinder, index % 2 == 0 and Color3.fromRGB(205, 250, 255) or Color3.fromRGB(70, 165, 235), Vector3.new(0.14, width, width * 0.68), CFrame.new(sheetPosition) * CFrame.Angles(0, angle, math.rad(90)))
		sheet.Material = index % 3 == 0 and Enum.Material.Glass or Enum.Material.Ice
		sheet.Transparency = 0.28
		TweenService:Create(sheet, TweenInfo.new(2.1 + index * 0.03, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Transparency = 1, Size = Vector3.new(0.06, width * 1.12, width * 0.75)}):Play()
		Debris:AddItem(sheet, 2.6)
	end
	local count = highQualityEffects() and 16 or 9
	for index = 1, count do
		local angle = index / count * math.pi * 2
		local distance = radius * (0.35 + (index % 3) * 0.22)
		local height = 2.5 + (index % 5) * 1.15
		local spikePosition = position + Vector3.new(math.cos(angle) * distance, height * 0.45, math.sin(angle) * distance)
		local spike = createEffectPart("IceWallShard", Enum.PartType.Block, index % 2 == 0 and Color3.fromRGB(205, 250, 255) or Color3.fromRGB(75, 175, 255), Vector3.new(0.65, height, 1.1), CFrame.new(spikePosition) * CFrame.Angles(math.rad(index % 2 == 0 and 12 or -12), angle, math.rad(18)))
		spike.Transparency = 0.12
		spike.Material = Enum.Material.Glass
		TweenService:Create(spike, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = spikePosition + Vector3.new(0, 1.3, 0), Size = Vector3.new(0.08, height * 1.25, 0.15), Transparency = 1}):Play()
		Debris:AddItem(spike, 0.76)
	end
	if ability == "FrostNova" or string.find(tostring(ability), "Cage", 1, true) then
		for index = 1, highQualityEffects() and 20 or 12 do
			local angle = index / (highQualityEffects() and 20 or 12) * math.pi * 2
			local wallPosition = position + Vector3.new(math.cos(angle) * radius * 0.78, 2.8, math.sin(angle) * radius * 0.78)
			local wall = createEffectPart("FrostWall", Enum.PartType.Block, Color3.fromRGB(165, 235, 255), Vector3.new(0.8, 5.5, math.max(1.8, radius * 0.22)), CFrame.lookAt(wallPosition, position))
			wall.Material, wall.Transparency = Enum.Material.Ice, 0.24
			TweenService:Create(wall, TweenInfo.new(0.75), {Transparency = 1, Size = Vector3.new(0.1, 7.5, wall.Size.Z * 1.1)}):Play()
			Debris:AddItem(wall, 0.82)
		end
	end
	renderRing("FreezingFront", position - Vector3.new(0, 1.05, 0), radius * 1.25, Color3.fromRGB(205, 250, 255), 0.62)
end

local function renderBlizzard(data)
	local position = data.Origin
	local radius = math.clamp(tonumber(data.Radius) or 18, 5, 45)
	local duration = math.clamp(tonumber(data.Duration) or 4, 1, 8)
	local cloud = createEffectPart("BlizzardCloud", Enum.PartType.Cylinder, Color3.fromRGB(185, 220, 245), Vector3.new(1.5, radius * 1.7, radius * 1.7), CFrame.new(position + Vector3.new(0, 12, 0)) * CFrame.Angles(0, 0, math.rad(90)))
	cloud.Transparency = 0.62
	TweenService:Create(cloud, TweenInfo.new(duration), {CFrame = cloud.CFrame * CFrame.Angles(math.rad(240), 0, 0), Transparency = 0.9}):Play()
	Debris:AddItem(cloud, duration + 0.1)
	task.spawn(function()
		local endAt = os.clock() + duration
		local index = 0
		while os.clock() < endAt and cloud.Parent do
			index += 1
			for flakeIndex = 1, highQualityEffects() and 3 or 1 do
				local angle = (index * 1.7 + flakeIndex * 2.1) % (math.pi * 2)
				local distance = ((index * 7 + flakeIndex * 11) % 100) / 100 * radius
				local start = position + Vector3.new(math.cos(angle) * distance, 13 + flakeIndex, math.sin(angle) * distance)
				local shard = createEffectPart("BlizzardSnow", Enum.PartType.Block, Color3.fromRGB(225, 250, 255), Vector3.new(0.16, 0.65, 0.16), CFrame.new(start) * CFrame.Angles(angle, angle * 0.7, 0))
				shard.Material = Enum.Material.Neon
				TweenService:Create(shard, TweenInfo.new(0.75, Enum.EasingStyle.Linear), {Position = start + Vector3.new(math.sin(angle) * 4, -14, math.cos(angle) * 4), Transparency = 0.5}):Play()
				Debris:AddItem(shard, 0.82)
			end
			task.wait(0.11)
		end
	end)
	renderIceImpact(position, radius, "Blizzard")
	shakeCamera(position, radius * 3, 0.55)
end

local function renderEnergyBolt(data)
	if typeof(data.Origin) ~= "Vector3" or typeof(data.Target) ~= "Vector3" then
		return
	end
	local projectileColor = effectColor(data)
	local soundData = table.clone(data)
	soundData.CastType = soundData.CastType or "Projectile"
	playEffectSound(data.Origin, soundData)
	local projectileShape = (data.Element == "Ice" or data.Element == "Earth") and Enum.PartType.Block or Enum.PartType.Ball
	local projectileSize = data.Element == "Fire" and Vector3.new(2.3, 2.3, 2.3)
		or data.Element == "Ice" and Vector3.new(0.65, 0.65, 4.2)
		or data.Element == "Lightning" and Vector3.new(1.8, 1.8, 3.6)
		or data.Element == "Earth" and Vector3.new(2.8, 2.8, 2.8)
		or data.Element == "Gravity" and Vector3.new(2.5, 2.5, 2.5)
		or Vector3.new(1.4, 1.4, 1.4)
	local projectile = createEffectPart(
		data.Element == "Fire" and "RoaringFireball"
			or data.Element == "Ice" and "IceLance"
			or data.Element == "Lightning" and "TravelingLightningBolt"
			or data.Element == "Earth" and "TravelingBoulder"
			or data.Element == "Gravity" and "TravelingSingularity"
			or "EnergyBolt",
		projectileShape,
		projectileColor,
		projectileSize,
		(data.Element == "Ice" or data.Element == "Lightning") and CFrame.lookAt(data.Origin, data.Target) or CFrame.new(data.Origin)
	)
	if data.Element == "Fire" then projectile.Material = Enum.Material.Neon end
	if data.Element == "Ice" then projectile.Material = Enum.Material.Glass end
	if data.Element == "Earth" then projectile.Material = Enum.Material.Slate end
	if data.Element == "Lightning" or data.Element == "Gravity" then projectile.Material = Enum.Material.Neon end
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
	local requestedDuration = tonumber(data.Duration) or 0.25
	local duration = requestedDuration
	if tonumber(data.ImpactTime) then
		duration = math.max(requestedDuration, data.ImpactTime - workspace:GetServerTimeNow())
	end
	-- Network transit must never collapse the visual into a one-frame flash.
	duration = math.clamp(duration, data.Element == "Lightning" and 0.24 or 0.18, 2)
	local tween = TweenService:Create(projectile, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Position = data.Target,
		Size = Vector3.new(2.1, 2.1, 2.1),
	})
	tween:Play()
	if data.Element == "Fire" and highQualityEffects() then
		task.spawn(function()
			while projectile.Parent do
				local ember = createEffectPart("FireballEmber", Enum.PartType.Ball, math.random() > 0.45 and Color3.fromRGB(255, 220, 70) or Color3.fromRGB(255, 65, 15), Vector3.one * 0.3, projectile.CFrame)
				TweenService:Create(ember, TweenInfo.new(0.26), {Position = ember.Position + Vector3.new(math.random(-12, 12) / 10, math.random(8, 22) / 10, math.random(-12, 12) / 10), Size = Vector3.one * 0.05, Transparency = 1}):Play()
				Debris:AddItem(ember, 0.3)
				task.wait(0.045)
			end
		end)
	end
	if data.Element == "Lightning" then
		task.spawn(function()
			local previous = data.Origin
			local segmentIndex = 0
			while projectile.Parent do
				segmentIndex += 1
				local current = projectile.Position
				local jitter = Vector3.new(math.random(-8, 8) / 10, math.random(-5, 9) / 10, math.random(-8, 8) / 10)
				local endpoint = current + jitter
				local delta = endpoint - previous
				if delta.Magnitude > 0.08 then
					local segment = createEffectPart("LightningTravelArc", Enum.PartType.Block, segmentIndex % 2 == 0 and Color3.new(1, 1, 1) or projectileColor, Vector3.new(0.16, 0.16, delta.Magnitude), CFrame.lookAt(previous:Lerp(endpoint, 0.5), endpoint))
					segment.Material, segment.Transparency = Enum.Material.Neon, 0.05
					TweenService:Create(segment, TweenInfo.new(0.18), {Transparency = 1, Size = Vector3.new(0.03, 0.03, delta.Magnitude)}):Play()
					Debris:AddItem(segment, 0.2)
				end
				previous = endpoint
				task.wait(0.025)
			end
		end)
	elseif data.Element == "Earth" then
		TweenService:Create(projectile, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Orientation = Vector3.new(540, 720, 360)}):Play()
	end
	tween.Completed:Connect(function()
		if projectile.Parent then
			projectile:Destroy()
			if data.Element == "Fire" then renderFireImpact(data.Target, tonumber(data.Radius) or 4, data.Ability)
			elseif data.Element == "Ice" then renderIceImpact(data.Target, tonumber(data.Radius) or 4, data.Ability)
			else
				renderImpact(data.Target, tonumber(data.Radius) or 4)
				if data.Element == "Lightning" then
					local splashRadius = math.max(7, tonumber(data.Radius) or 7)
					for index = 1, highQualityEffects() and 10 or 6 do
						local angle = index / (highQualityEffects() and 10 or 6) * math.pi * 2
						local endpoint = data.Target + Vector3.new(math.cos(angle) * splashRadius, (index % 3) * 1.1, math.sin(angle) * splashRadius)
						local delta = endpoint - data.Target
						local arc = createEffectPart("LightningSplashZap", Enum.PartType.Block, index % 2 == 0 and Color3.new(1, 1, 1) or projectileColor, Vector3.new(0.2, 0.2, delta.Magnitude), CFrame.lookAt(data.Target:Lerp(endpoint, 0.5), endpoint))
						arc.Material, arc.Transparency = Enum.Material.Neon, 0.08
						TweenService:Create(arc, TweenInfo.new(0.3), {Transparency = 1, Size = Vector3.new(0.03, 0.03, delta.Magnitude * 1.12)}):Play()
						Debris:AddItem(arc, 0.34)
					end
					renderRing("LightningSplashRadius", data.Target - Vector3.new(0, 1.1, 0), splashRadius, projectileColor, 0.42)
				elseif data.Element == "Earth" then
					for index = 1, highQualityEffects() and 9 or 5 do
						local angle = index * 2.399
						local chunk = createEffectPart("EarthImpactChunk", Enum.PartType.Block, Color3.fromRGB(120, 92, 62), Vector3.one * (0.7 + index % 3 * 0.35), CFrame.new(data.Target + Vector3.new(0, 0.4, 0)))
						chunk.Material = Enum.Material.Rock
						TweenService:Create(chunk, TweenInfo.new(0.48, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = data.Target + Vector3.new(math.cos(angle) * (4 + index), 2 + index % 4, math.sin(angle) * (4 + index)), Transparency = 1}):Play()
						Debris:AddItem(chunk, 0.55)
					end
				elseif data.Element == "Gravity" then
					local well = createEffectPart("GravityImpactWell", Enum.PartType.Ball, projectileColor, Vector3.one * math.max(4, tonumber(data.Radius) or 4), CFrame.new(data.Target))
					well.Material, well.Transparency = Enum.Material.Neon, 0.55
					TweenService:Create(well, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = Vector3.one * 0.15, Transparency = 1}):Play()
					Debris:AddItem(well, 0.55)
				end
			end
			soundData.Impact = true
			playEffectSound(data.Target, soundData)
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
	local soundData = table.clone(data)
	soundData.CastType = "Tornado"
	playEffectSound(data.Origin, soundData)
	local color = effectColor(data)
	local vortex = createEffectPart("TornadoTravel", Enum.PartType.Ball, color, Vector3.new(3, 3, 3), CFrame.new(data.Origin))
	vortex.Transparency = 0.2
	local duration = math.clamp((tonumber(data.ImpactTime) or 0) - workspace:GetServerTimeNow(), 0.05, 2)
	TweenService:Create(vortex, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Position = data.Target, Size = Vector3.new(7, 7, 7), Transparency = 0.85}):Play()
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = color, 18, 3
	light.Parent = vortex
	Debris:AddItem(vortex, duration + 0.1)
end

local function renderTornado(data)
	if typeof(data.Origin) ~= "Vector3" then return end
	local soundData = table.clone(data)
	soundData.CastType, soundData.Impact = "Tornado", true
	playEffectSound(data.Origin, soundData)
	local color = effectColor(data)
	local radius = math.clamp(tonumber(data.Radius) or 16, 4, 60)
	local duration = math.clamp(tonumber(data.Duration) or 4, 0.5, 8)
	if data.Ability == "Blizzard" or data.Element == "Ice" then renderBlizzard(data); return end
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
	local core = createEffectPart("RiftTornado", Enum.PartType.Cylinder, color, Vector3.new(2, 8, 8), CFrame.new(data.Origin + Vector3.new(0, 4, 0)))
	core.Transparency = 0.4
	local rings = {}
	for index = 1, 5 do
		local ring = createEffectPart("TornadoVortex", Enum.PartType.Cylinder, color:Lerp(Color3.new(1, 1, 1), 0.45), Vector3.new(0.28, radius * (1 - index * 0.1), radius * (1 - index * 0.1)), CFrame.new(data.Origin + Vector3.new(0, index * 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)))
		ring.Transparency = 0.22
		table.insert(rings, ring)
	end
	renderRing("TornadoGround", data.Origin - Vector3.new(0, 2.5, 0), radius, color, 0.5)
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
	local color = effectColor(data)
	local soundData = table.clone(data)
	soundData.CastType, soundData.Impact = "Radial", true
	playEffectSound(data.Origin, soundData)
	if data.Element == "Fire" then renderFireImpact(data.Origin, radius, data.Ability); return end
	if data.Element == "Ice" then renderIceImpact(data.Origin, radius, data.Ability); return end
	if data.Element == "Lightning" then
		for index = 1, highQualityEffects() and 12 or 7 do
			local angle = index / (highQualityEffects() and 12 or 7) * math.pi * 2
			local endpoint = data.Origin + Vector3.new(math.cos(angle) * radius, index % 3, math.sin(angle) * radius)
			local offset = endpoint - data.Origin
			local arc = createEffectPart("StormGroundArc", Enum.PartType.Block, index % 2 == 0 and Color3.new(1, 1, 1) or color, Vector3.new(0.18, 0.18, offset.Magnitude), CFrame.lookAt(data.Origin:Lerp(endpoint, 0.5), endpoint))
			arc.Material, arc.Transparency = Enum.Material.Neon, 0.08
			TweenService:Create(arc, TweenInfo.new(0.34), {Transparency = 1, Size = Vector3.new(0.03, 0.03, offset.Magnitude * 1.1)}):Play()
			Debris:AddItem(arc, 0.38)
		end
	elseif data.Element == "Earth" then
		for index = 1, highQualityEffects() and 10 or 6 do
			local angle = index * 2.399
			local rock = createEffectPart("EarthBurstRock", Enum.PartType.Block, Color3.fromRGB(120, 88, 55), Vector3.one * (0.8 + index % 3 * 0.4), CFrame.new(data.Origin + Vector3.new(math.cos(angle) * radius * 0.5, 0, math.sin(angle) * radius * 0.5)))
			rock.Material = Enum.Material.Rock
			TweenService:Create(rock, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = rock.Position + Vector3.new(0, 3 + index % 4, 0), Transparency = 1}):Play()
			Debris:AddItem(rock, 0.55)
		end
	elseif data.Element == "Gravity" then
		for index = 1, 3 do
			task.delay(index * 0.055, function()
				local gravityRing = createEffectPart("GravityGroundWell", Enum.PartType.Cylinder, color, Vector3.new(0.12, radius * 2, radius * 2), CFrame.new(data.Origin - Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, 0, math.rad(90)))
				gravityRing.Material, gravityRing.Transparency = Enum.Material.Neon, 0.48
				TweenService:Create(gravityRing, TweenInfo.new(0.48, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = Vector3.new(0.05, 0.5, 0.5), Transparency = 1}):Play()
				Debris:AddItem(gravityRing, 0.52)
			end)
		end
	end
	local sphere = createEffectPart(
		"EnergyBurst",
		Enum.PartType.Ball,
		color,
		Vector3.new(2, 2, 2),
		CFrame.new(data.Origin)
	)
	sphere.Transparency = 0.35
	TweenService:Create(sphere, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.one * radius * 2,
		Transparency = 1,
	}):Play()

	renderRing("EnergyBurstRing", data.Origin - Vector3.new(0, 2.5, 0), radius * 1.2, color:Lerp(Color3.new(1, 1, 1), 0.45), 0.45)
	if highQualityEffects() then
		task.delay(0.08, function()
			renderRing("EnergyBurstEcho", data.Origin - Vector3.new(0, 2.45, 0), radius * 0.9, color, 0.38)
		end)
	end
	shakeCamera(data.Origin, radius * 3, 0.65)
	Debris:AddItem(sphere, 0.5)
end

local function renderUltimateSignature(data)
	local position = data.Target
	if typeof(position) ~= "Vector3" then return end
	local element = data.Element or "Arcane"
	local color = effectColor(data)
	if element == "Fire" then
		renderFireImpact(position, 24, data.Ability)
	elseif element == "Ice" then
		renderIceImpact(position, 24, data.Ability == "Blizzard" and "FrostNova" or data.Ability)
	elseif element == "Lightning" then
		for index = 1, 9 do
			local angle = index / 9 * math.pi * 2
			local strikePosition = position + Vector3.new(math.cos(angle) * 13, 15, math.sin(angle) * 13)
			local strike = createEffectPart("UltimateThunderPillar", Enum.PartType.Block, index % 2 == 0 and Color3.new(1, 1, 1) or color, Vector3.new(0.5, 30, 0.5), CFrame.new(strikePosition))
			TweenService:Create(strike, TweenInfo.new(0.42), {Size = Vector3.new(2.4, 30, 2.4), Transparency = 1}):Play()
			Debris:AddItem(strike, 0.48)
		end
	elseif element == "Earth" then
		for index = 1, 12 do
			local angle = index / 12 * math.pi * 2
			local rock = createEffectPart("UltimateMountain", Enum.PartType.Block, color, Vector3.new(4, 2, 4), CFrame.new(position + Vector3.new(math.cos(angle) * 15, -1, math.sin(angle) * 15)) * CFrame.Angles(index * 0.3, angle, index * 0.17))
			TweenService:Create(rock, TweenInfo.new(0.55, Enum.EasingStyle.Back), {Position = rock.Position + Vector3.new(0, 9 + index % 4, 0), Size = Vector3.new(5, 11, 5)}):Play()
			Debris:AddItem(rock, 1.1)
		end
	elseif element == "Gravity" then
		for index = 1, 16 do
			local angle = index / 16 * math.pi * 2
			local start = position + Vector3.new(math.cos(angle) * 28, (index % 5) * 3, math.sin(angle) * 28)
			local orb = createEffectPart("UltimateGravityCollapse", Enum.PartType.Ball, index % 2 == 0 and color or Color3.fromRGB(20, 5, 35), Vector3.one * 4, CFrame.new(start))
			TweenService:Create(orb, TweenInfo.new(0.72, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = position + Vector3.new(0, 4, 0), Size = Vector3.one * 0.2, Transparency = 1}):Play()
			Debris:AddItem(orb, 0.8)
		end
	elseif element == "Poison" then
		for index = 1, 12 do
			local angle = index / 12 * math.pi * 2
			local cloud = createEffectPart("UltimateVenomCloud", Enum.PartType.Ball, index % 2 == 0 and color or Color3.fromRGB(65, 115, 35), Vector3.one * 3, CFrame.new(position + Vector3.new(math.cos(angle) * 8, 2 + index % 4, math.sin(angle) * 8)))
			cloud.Transparency = 0.32
			TweenService:Create(cloud, TweenInfo.new(1.1), {Size = Vector3.one * 13, Position = cloud.Position + Vector3.new(math.cos(angle) * 8, 5, math.sin(angle) * 8), Transparency = 1}):Play()
			Debris:AddItem(cloud, 1.2)
		end
	elseif element == "Prismatic" then
		for index = 1, 7 do
			local rainbow = {Color3.fromRGB(255, 65, 75), Color3.fromRGB(255, 155, 55), Color3.fromRGB(255, 235, 75), Color3.fromRGB(85, 235, 135), Color3.fromRGB(75, 175, 255), Color3.fromRGB(145, 90, 255), Color3.fromRGB(255, 95, 220)}
			local ring = renderRing("SevenfoldUltimate", position + Vector3.new(0, index * 0.5, 0), 8 + index * 3, rainbow[index], 0.55 + index * 0.04)
			ring.CFrame *= CFrame.Angles(math.rad(index * 11), 0, math.rad(index * 17))
		end
	else
		renderTierSpectacle(data, color, 11)
	end
	renderUltimateTitle(data, 11, color)
	shakeCamera(position, 110, 1.55)
end

local function renderPowerCast(data)
	if typeof(data.Origin) ~= "Vector3" or typeof(data.Target) ~= "Vector3" then return end
	local color = POWER_COLORS[data.Ability] or ELEMENT_COLORS[data.Element] or ENERGY_COLOR
	local radius = data.Mode == "Close" and 5 or 2.5
	local tier = math.clamp(math.floor(tonumber(data.Tier) or 1), 1, 11)
	local variant = math.clamp(math.floor(tonumber(data.VisualVariant) or tier), 1, 12)
	playEffectSound(data.Origin, data)
	if data.Ultimate then
		task.delay(math.max(0, tonumber(data.ImpactTime) and data.ImpactTime - workspace:GetServerTimeNow() or tonumber(data.Duration) or 0), function()
			renderUltimateSignature(data)
		end)
	end
	renderRing("PowerCastRing", data.Origin - Vector3.new(0, 1.5, 0), radius, color, 0.22)
	for index = 2, math.min(5, math.ceil(tier / 2)) do
		task.delay(index * 0.025, function()
			renderRing("PowerTierRing", data.Origin - Vector3.new(0, 1.45 - index * 0.08, 0), radius * (1 + index * 0.28), index % 2 == 0 and color or Color3.new(1, 1, 1), 0.2 + tier * 0.018)
		end)
	end
	if highQualityEffects() then
		local count = math.min(3 + math.floor(tier / 2), 8)
		for index = 1, count do
			local angle = index / count * math.pi * 2 + variant * 0.37
			local start = data.Origin + Vector3.new(math.cos(angle) * (1.2 + variant * 0.08), (index % 3) * 0.65, math.sin(angle) * (1.2 + variant * 0.08))
			local shape = data.Element == "Earth" and Enum.PartType.Block or Enum.PartType.Ball
			local mote = createEffectPart("PowerSignature", shape, index % 2 == 0 and color or color:Lerp(Color3.new(1, 1, 1), 0.55), Vector3.one * (0.28 + tier * 0.035), CFrame.new(start))
			local spread = data.CastType == "Beam" and Vector3.new(math.cos(angle) * 2, 0, math.sin(angle) * 2)
				or Vector3.new(math.cos(angle) * (3 + variant * 0.2), 1.5 + (index % 2) * 1.2, math.sin(angle) * (3 + variant * 0.2))
			TweenService:Create(mote, TweenInfo.new(0.28 + variant * 0.012, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = start + spread, Size = Vector3.one * 0.05, Transparency = 1}):Play()
			Debris:AddItem(mote, 0.5)
		end
	end
	-- Projectile and storm renderers own their travel silhouette. Avoid laying the
	-- same generic energy orb over fireballs, ice lances, tornadoes and blizzards.
	if data.CastType == "Projectile" or data.CastType == "Tornado" then return end
	local distance = (data.Target - data.Origin).Magnitude
	if data.Mode == "Ranged" and distance > 2 then
		local requestedDuration = tonumber(data.Duration) or 0.24
		local duration = tonumber(data.ImpactTime) and math.max(requestedDuration, data.ImpactTime - workspace:GetServerTimeNow()) or requestedDuration
		duration = math.clamp(duration, 0.2, 1.8)
		local shape = (data.Element == "Ice" or data.Element == "Earth" or data.Element == "Lightning") and Enum.PartType.Block or Enum.PartType.Ball
		local size = data.Element == "Ice" and Vector3.new(0.55, 0.55, 3.2)
			or data.Element == "Lightning" and Vector3.new(0.75, 0.75, 3.8)
			or data.Element == "Earth" and Vector3.one * (1.4 + tier * 0.08)
			or data.Element == "Gravity" and Vector3.one * (1.8 + tier * 0.1)
			or data.Element == "Fire" and Vector3.one * (1.5 + tier * 0.1)
			or Vector3.one * (0.8 + tier * 0.07)
		local travelCFrame = (data.Element == "Ice" or data.Element == "Lightning") and CFrame.lookAt(data.Origin, data.Target) or CFrame.new(data.Origin)
		local traveler = createEffectPart((data.Element or "Arcane") .. "PowerTravel", shape, color, size, travelCFrame)
		traveler.Transparency = 0.12
		traveler.Material = data.Element == "Earth" and Enum.Material.Rock or data.Element == "Ice" and Enum.Material.Glass or Enum.Material.Neon
		local light = Instance.new("PointLight")
		light.Color, light.Brightness, light.Range, light.Parent = color, 2.5, 10 + tier, traveler
		if highQualityEffects() then
			local back, front = Instance.new("Attachment"), Instance.new("Attachment")
			back.Position, front.Position = Vector3.new(0, 0, 0.7), Vector3.new(0, 0, -0.7)
			back.Parent, front.Parent = traveler, traveler
			local trail = Instance.new("Trail")
			trail.Attachment0, trail.Attachment1 = back, front
			trail.Color = data.Element == "Prismatic" and ColorSequence.new(Color3.fromRGB(255, 75, 90), Color3.fromRGB(80, 220, 255)) or ColorSequence.new(Color3.new(1, 1, 1), color)
			trail.Transparency = NumberSequence.new(0.02, 1)
			trail.WidthScale = NumberSequence.new(1.4 + tier * 0.08, 0)
			trail.Lifetime, trail.LightEmission, trail.FaceCamera = 0.18 + tier * 0.018, 1, true
			trail.Parent = traveler
		end
		local tween = TweenService:Create(traveler, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Position = data.Target, Size = size * 1.2, Transparency = 0.35})
		tween:Play()
		tween.Completed:Connect(function()
			if traveler.Parent then traveler:Destroy() end
			renderRing("PowerCastImpact", data.Target - Vector3.new(0, 1.2, 0), radius * 1.4, color, 0.3)
			local impactData = table.clone(data)
			impactData.Impact = true
			playEffectSound(data.Target, impactData)
			renderTierSpectacle(data, color, tier)
			if tier >= 9 then
				impactData.SoundPitch = (tonumber(data.SoundPitch) or 1) * 0.72
				task.delay(0.08, function() playEffectSound(data.Target, impactData) end)
			end
		end)
		Debris:AddItem(traveler, duration + 0.1)
	else
		renderRing("PowerCastImpact", data.Target - Vector3.new(0, 1.2, 0), radius * 1.4, color, 0.3)
		renderTierSpectacle(data, color, tier)
	end
end

local function renderLocalPower(data)
	if typeof(data.Origin) ~= "Vector3" then return end
	local ability = tostring(data.Ability or "EnergyBolt")
	local color = POWER_COLORS[ability] or ELEMENT_COLORS[data.Element] or ENERGY_COLOR
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
	local style = tostring(data.Style or "Sword")
	local slashSize = style == "Spear" and Vector3.new(0.2, 1.1, 12) or (style == "Hammer" or style == "Greatsword") and Vector3.new(0.55, 8, 9) or style == "Katana" and Vector3.new(0.08, 4.2, 11) or Vector3.new(0.18, 5, 8)
	local slashCFrame = style == "Spear" and CFrame.lookAt(center, center + data.Direction)
		or CFrame.lookAt(center, center + data.Direction) * CFrame.Angles(0, 0, math.rad(combo % 2 == 0 and -55 or 55))
	local slash = createEffectPart(
		"SwordSlash",
		Enum.PartType.Block,
		data.Legendary and Color3.fromRGB(255, 105, 220) or Color3.fromRGB(205, 235, 255),
		slashSize,
		slashCFrame
	)
	slash.Transparency = 0.2
	TweenService:Create(slash, TweenInfo.new(0.18), {
		Transparency = 1,
		Size = Vector3.new(0.05, 7, 10),
	}):Play()
	if highQualityEffects() then
		local echo = slash:Clone()
		echo.Name = "SwordSlashEcho"
		echo.Color = data.Legendary and Color3.fromRGB(255, 225, 75) or Color3.fromRGB(90, 185, 255)
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
	-- The owning client poses its weapon immediately when input begins. Replicated
	-- posing remains here for every other observer so attacks still read in multiplayer.
	if character == localPlayer.Character then return end
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
	gui.Size = UDim2.fromOffset(data.Critical and 155 or 125, data.Critical and 48 or 40)
	gui.StudsOffset = Vector3.new(math.random(-12, 12) / 10, 3, 0)
	gui.AlwaysOnTop = true
	gui.Parent = effectsFolder
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = string.format("-%d%s", math.floor(tonumber(data.Amount) or 0), data.Critical and "!!" or "!")
	label.TextColor3 = data.Critical and Color3.fromRGB(255, 235, 65) or Color3.fromRGB(255, 62, 72)
	label.Text = data.Critical and ("CRIT! " .. label.Text) or label.Text
	label.TextStrokeColor3 = Color3.fromRGB(70, 5, 12)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Rotation = math.random(-9, 9)
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
	local root = target:FindFirstChild("HumanoidRootPart")
	if root and data.Element == "Ice" then
		local frost = Instance.new("Highlight")
		frost.Name, frost.Adornee = "FrozenEnemyShell", target
		frost.FillColor, frost.OutlineColor = Color3.fromRGB(145, 225, 255), Color3.fromRGB(225, 255, 255)
		frost.FillTransparency, frost.OutlineTransparency, frost.Parent = 0.55, 0.12, effectsFolder
		Debris:AddItem(frost, 0.8)
		for index = 1, 5 do
			local angle = index / 5 * math.pi * 2
			local shard = createEffectPart("EnemyFreezeShard", Enum.PartType.Block, Color3.fromRGB(175, 240, 255), Vector3.new(0.22, 2.2, 0.4), CFrame.new(root.Position + Vector3.new(math.cos(angle) * 1.5, 1.2, math.sin(angle) * 1.5)) * CFrame.Angles(math.rad(18), angle, math.rad(12)))
			shard.Material, shard.Transparency = Enum.Material.Ice, 0.18
			TweenService:Create(shard, TweenInfo.new(0.75), {Transparency = 1, Size = Vector3.new(0.05, 3.1, 0.08)}):Play()
			Debris:AddItem(shard, 0.8)
		end
	elseif root and data.Element == "Fire" then
		for index = 1, 4 do
			local ember = createEffectPart("EnemyBurnFlare", Enum.PartType.Ball, index % 2 == 0 and Color3.fromRGB(255, 225, 70) or Color3.fromRGB(255, 65, 18), Vector3.one * 0.45, CFrame.new(root.Position + Vector3.new(math.random(-10, 10) / 10, index * 0.55, math.random(-10, 10) / 10)))
			TweenService:Create(ember, TweenInfo.new(0.45), {Position = ember.Position + Vector3.new(0, 3.5, 0), Size = Vector3.one * 0.05, Transparency = 1}):Play()
			Debris:AddItem(ember, 0.5)
		end
	end
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
	local color = effectColor(data)
	for index = 1, highQualityEffects() and 4 or 2 do
		task.delay((index - 1) * 0.08, function()
			local sphere = createEffectPart("GravityPulse", Enum.PartType.Ball, color, Vector3.new(radius * 2, radius * 2, radius * 2), CFrame.new(data.Origin))
			sphere.Transparency = 0.78
			TweenService:Create(sphere, TweenInfo.new(0.45), {Size = Vector3.new(1, 1, 1), Transparency = 1}):Play()
			Debris:AddItem(sphere, 0.5)
		end)
	end
	shakeCamera(data.Origin, radius * 3, 0.8)
end

local function renderBlinkStrike(data)
	if typeof(data.Origin) ~= "Vector3" or typeof(data.Target) ~= "Vector3" then return end
	local offset = data.Target - data.Origin
	if offset.Magnitude < 0.1 then return end
	local streak = createEffectPart("BackstrikeBlink", Enum.PartType.Block, Color3.fromRGB(105, 205, 255), Vector3.new(1.2, 3.2, offset.Magnitude), CFrame.lookAt(data.Origin:Lerp(data.Target, 0.5), data.Target))
	streak.Transparency = 0.3
	TweenService:Create(streak, TweenInfo.new(0.28), {Size = Vector3.new(0.05, 0.15, offset.Magnitude), Transparency = 1}):Play()
	Debris:AddItem(streak, 0.32)
	for _, point in ipairs({data.Origin, data.Target}) do
		for index = 1, 3 do renderRing("BlinkPortal", point, 2.5 + index * 1.2, index == 2 and Color3.new(1, 1, 1) or Color3.fromRGB(105, 205, 255), 0.24 + index * 0.04) end
	end
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
	local color = effectColor(data)
	local points = {data.Origin}
	local segments = highQualityEffects() and 8 or 4
	for index = 1, segments - 1 do
		local alpha = index / segments
		table.insert(points, data.Origin:Lerp(data.Target, alpha) + Vector3.new(math.random(-15, 15) / 10, math.random(-10, 10) / 10, math.random(-15, 15) / 10))
	end
	table.insert(points, data.Target)
	for index = 1, #points - 1 do
		local offset = points[index + 1] - points[index]
		local segment = createEffectPart("SegmentedLightning", Enum.PartType.Block, color, Vector3.new(0.28, 0.28, offset.Magnitude), CFrame.lookAt(points[index]:Lerp(points[index + 1], 0.5), points[index + 1]))
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
		playEffectSound(data.Origin, {CastType = "Beam", Element = data.Element, Tier = data.Tier, SoundPitch = data.SoundPitch})
		renderBeam(data, effectColor(data), 0.45, tonumber(data.Radius) or 3)
		shakeCamera(data.Origin, 45, 0.65)
	elseif effectName == "GravityPulse" then
		playEffectSound(data.Origin, {CastType = "Gravity", Element = data.Element, Tier = data.Tier, Impact = true})
		renderGravityPulse(data)
	elseif effectName == "ChainLightning" then
		if not data.Index or data.Index == 1 then playEffectSound(data.Origin, {CastType = "Chain", Element = data.Element, Tier = data.Tier, Impact = true}) end
		renderLightningArc(data)
	elseif effectName == "GroundSlam" then
		playEffectSound(data.Origin, {CastType = "Radial", Element = data.Element or "Earth", Tier = data.Tier, Impact = true})
		renderGroundSlam(data)
	elseif effectName == "Melee" then
		playEffectSound(data.Origin, {CastType = "Melee", Element = data.Element, Tier = data.Finisher and 6 or data.Combo, SoundPitch = 0.9 + (tonumber(data.Combo) or 1) * 0.07})
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
		playEffectSound(data.Origin, {CastType = "Radial", Element = "Physical", Tier = 7, Impact = true, SoundPitch = 0.78})
		renderFinisher(data)
	elseif effectName == "Dodge" then
		renderDodge(data)
	elseif effectName == "BlinkStrike" then
		renderBlinkStrike(data)
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
