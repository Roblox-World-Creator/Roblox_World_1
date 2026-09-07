local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.VisualConfig)
local ElementVFX = {}

function ElementVFX.Start(config)
	local folder, quality = config.Parent, config.HighQuality
	local active = 0
	local function holder(position, lifetime)
		if active >= Config.Effects.MaxParts then return nil end
		local object = Instance.new("Part")
		object.Name, object.Size, object.Position = "ElementVFX", Vector3.one * 0.05, position
		object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
		object.Transparency, object.CastShadow, object.Parent = 1, false, folder
		active += 1
		object.Destroying:Once(function() active -= 1 end)
		Debris:AddItem(object, lifetime)
		return object
	end
	local api = {}
	function api.Ring(name, position, radius, color, duration)
		local root = holder(position, duration + 0.1)
		if not root then return nil end
		root.Name = name
		local segments = quality() and Config.Effects.ArcSegments or Config.Effects.LowArcSegments
		local points = {}
		for index = 0, segments do
			local angle = index / segments * math.pi * 2
			local point = Instance.new("Attachment")
			local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
			point.Position, point.Parent = direction * 0.5, root
			TweenService:Create(point, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = direction * radius}):Play()
			table.insert(points, point)
		end
		for index = 1, segments do
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = points[index], points[index + 1]
			beam.FaceCamera, beam.LightEmission, beam.Segments = true, 1, 1
			beam.Color, beam.Transparency = ColorSequence.new(color), NumberSequence.new(0.12)
			beam.Width0, beam.Width1, beam.Parent = 0.5, 0.5, root
			TweenService:Create(beam, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Width0 = 0, Width1 = 0}):Play()
		end
		return root
	end
	function api.Burst(position, element, color, scale)
		local root = holder(position, 1.5)
		if not root then return end
		local palette = Config.Elements[element]
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = palette and palette.Particle or "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.65), color)
		emitter.LightEmission = element == "Earth" and 0.1 or 0.8
		emitter.Rate, emitter.Lifetime = 0, NumberRange.new(0.35, 1.1)
		emitter.Speed, emitter.SpreadAngle = NumberRange.new(8 * scale, 18 * scale), Vector2.new(180, 180)
		emitter.Drag = element == "Ice" and 5 or 3
		emitter.Acceleration = Vector3.new(0, element == "Fire" and 16 or -12, 0)
		emitter.Rotation, emitter.RotSpeed = NumberRange.new(-180, 180), NumberRange.new(-100, 100)
		emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4 * scale), NumberSequenceKeypoint.new(0.2, 1.6 * scale), NumberSequenceKeypoint.new(1, 0)})
		emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.6, 0.4), NumberSequenceKeypoint.new(1, 1)})
		emitter.Parent = root
		emitter:Emit(quality() and Config.Effects.BurstCount or Config.Effects.LowBurstCount)
	end
	function api.Projectile(projectile, element, color)
		local palette = Config.Elements[element]
		local a, b = Instance.new("Attachment"), Instance.new("Attachment")
		a.Position, b.Position = Vector3.new(-0.65, 0, 0), Vector3.new(0.65, 0, 0)
		a.Parent, b.Parent = projectile, projectile
		local trail = Instance.new("Trail")
		trail.Attachment0, trail.Attachment1 = a, b
		trail.FaceCamera, trail.LightEmission, trail.Lifetime = true, 1, 0.32
		trail.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
		trail.Transparency, trail.WidthScale = NumberSequence.new(0.15, 1), NumberSequence.new(1.5, 0)
		trail.Parent = projectile
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = palette and palette.Particle or "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color, emitter.LightEmission = ColorSequence.new(color), 0.8
		emitter.Lifetime, emitter.Rate = NumberRange.new(0.15, 0.4), quality() and 45 or 12
		emitter.Speed, emitter.SpreadAngle = NumberRange.new(1, 4), Vector2.new(180, 180)
		emitter.Size, emitter.Transparency = NumberSequence.new(1.2, 0), NumberSequence.new(0.15, 1)
		emitter.Parent = projectile
	end
	return api
end

return ElementVFX
