local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.VisualConfig)
local Realms = require(ReplicatedStorage.Shared.RealmConfig)
local VFX = require(script.Parent:WaitForChild("ElementVFX"))
local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name, folder.Parent = "RealmAtmosphereEffects", workspace
local existingAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local atmosphere = existingAtmosphere or Instance.new("Atmosphere")
local baseline = {Density = existingAtmosphere and atmosphere.Density or 0, Color = atmosphere.Color, Decay = atmosphere.Decay, Haze = atmosphere.Haze}
if not existingAtmosphere then atmosphere.Name, atmosphere.Density, atmosphere.Parent = "RealmHaze", 0, Lighting end
local grade = Instance.new("ColorCorrectionEffect")
grade.Name, grade.Parent = "RealmColor", Lighting
local bloom = Instance.new("BloomEffect")
bloom.Name, bloom.Intensity, bloom.Size, bloom.Threshold, bloom.Parent = "ElementGlow", 0.16, 24, 1.3, Lighting
local highQuality = function() return player:GetAttribute("EffectQuality") ~= "LOW" end
local vfx = VFX.Start({Parent = folder, HighQuality = highQuality})
local function source(parent)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate, emitter.Lifetime = 0, NumberRange.new(1.5, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rotation, emitter.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-25, 25)
	emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.35), NumberSequenceKeypoint.new(0.8, 0.6), NumberSequenceKeypoint.new(1, 1)})
	emitter.Parent = parent
	return emitter
end
local weather = Instance.new("Part")
weather.Name, weather.Size = "LocalWeather", Vector3.new(95, 1, 95)
weather.Anchored, weather.CanCollide, weather.CanQuery, weather.CanTouch = true, false, false, false
weather.Transparency, weather.Parent = 1, folder
local precipitation = source(weather)
local sources, connections = {}, {}
local function register(object)
	if not object:IsA("BasePart") or not object:GetAttribute("AmbientElement") or sources[object] then return end
	local palette = Config.Elements[object:GetAttribute("AmbientElement")]
	if not palette then return end
	local emitter = source(object)
	emitter.Name, emitter.Texture = "LocalElementAmbience", palette.Particle
	emitter.Color, emitter.Speed = ColorSequence.new(palette.Accent), NumberRange.new(2, 8)
	emitter.Acceleration, emitter.LightEmission = Vector3.new(0, 5, 0), 0.7
	emitter.Size = NumberSequence.new(2, 0)
	sources[object] = emitter
end
connections[#connections + 1] = CollectionService:GetInstanceAddedSignal("RealmAmbientSource"):Connect(register)
connections[#connections + 1] = CollectionService:GetInstanceRemovedSignal("RealmAmbientSource"):Connect(function(object)
	local emitter = sources[object]
	if emitter then sources[object] = nil; emitter:Destroy() end
end)
for _, object in ipairs(CollectionService:GetTagged("RealmAmbientSource")) do register(object) end
local current, elapsed, stormTime = nil, 0, 0
local hazeTween, gradeTween
connections[#connections + 1] = RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < Config.Weather.UpdateInterval then return end
	stormTime += elapsed
	elapsed = 0
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local id = root and humanoid and humanoid.Health > 0 and player:GetAttribute("CurrentRealmId") or ""
	local definition = Realms.Realms[id]
	local palette = definition and Config.Elements[definition.Element]
	if current ~= id then
		current, stormTime = id, 0
		precipitation:Clear()
		if hazeTween then hazeTween:Cancel() end
		if gradeTween then gradeTween:Cancel() end
		hazeTween = TweenService:Create(atmosphere, TweenInfo.new(Config.Weather.Transition), {Density = palette and palette.Density or baseline.Density, Color = palette and palette.Mist or baseline.Color, Decay = palette and palette.Mist or baseline.Decay, Haze = palette and 1.2 or baseline.Haze})
		gradeTween = TweenService:Create(grade, TweenInfo.new(Config.Weather.Transition), {TintColor = palette and palette.Tint or Color3.new(1, 1, 1), Contrast = palette and 0.06 or 0, Saturation = palette and 0.08 or 0})
		hazeTween:Play(); gradeTween:Play()
		if palette then
			precipitation.Texture = definition.Element == "Fire" and "rbxasset://textures/particles/sparkles_main.dds" or palette.Particle
			precipitation.Color = ColorSequence.new(palette.Accent)
			precipitation.Size = NumberSequence.new(definition.Element == "Earth" and 0.6 or 0.22)
			precipitation.Speed = NumberRange.new(2, 5)
			precipitation.Acceleration = Vector3.new(4, definition.Element == "Fire" and 3 or -5, 1)
			precipitation.LightEmission = definition.Element == "Fire" and 1 or 0.3
		end
	end
	precipitation.Rate = palette and (highQuality() and Config.Weather.Rate or Config.Weather.LowRate) or 0
	bloom.Enabled = highQuality()
	if root then weather.Position = root.Position + Vector3.new(0, definition and definition.Element == "Fire" and 1 or 20, 0) end
	for object, emitter in pairs(sources) do
		emitter.Rate = root and palette and (object.Position - root.Position).Magnitude < Config.Scenery.AmbientRange and (highQuality() and 14 or 3) or 0
	end
	if palette and definition.Element == "Lightning" and highQuality() and stormTime > Config.Weather.StormInterval then
		stormTime = 0
		-- Distant local arcs add motion without full-screen flashes or gameplay damage.
		local point = root.Position + Vector3.new(65, 42, -65)
		for index = 1, 4 do
			vfx.Ring("DistantThunderArc", point + Vector3.new(index % 2 * 3, index * 5, 0), 3, palette.Accent, 0.35)
		end
	end
end)
script.Destroying:Connect(function()
	for _, connection in ipairs(connections) do connection:Disconnect() end
	for _, emitter in pairs(sources) do emitter:Destroy() end
	if hazeTween then hazeTween:Cancel() end
	if gradeTween then gradeTween:Cancel() end
	if existingAtmosphere then for property, value in pairs(baseline) do atmosphere[property] = value end else atmosphere:Destroy() end
	grade:Destroy(); bloom:Destroy(); folder:Destroy()
end)
