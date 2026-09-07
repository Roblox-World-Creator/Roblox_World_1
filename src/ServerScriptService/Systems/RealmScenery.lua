local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Visuals = require(ReplicatedStorage.Shared.VisualConfig)
local RealmScenery = {}

local function part(parent, name, size, frame, color, material, solid, className)
	local object = Instance.new(className or "Part")
	object.Name, object.Size, object.CFrame = name, size, frame
	object.Color, object.Material = color, material
	object.Anchored, object.CanCollide, object.CanQuery, object.CanTouch = true, solid, solid, false
	object.Parent = parent
	return object
end

function RealmScenery.Start(config)
	local parent, definition = config.Parent, config.Definition
	local previous = parent:FindFirstChild("RealmScenery")
	if previous then previous:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "RealmScenery", parent
	local palette, layout = Visuals.Elements[definition.Element], Visuals.Scenery
	local center = definition.Destination - Vector3.new(0, 1, 0)
	local board = 220 * (definition.SizeScale or 1)
	local random = Random.new(7301 + config.Index * 997)
	local function make(name, size, frame, color, material, solid, className)
		return part(folder, name, size, frame, color or palette.Rock, material or palette.Material, solid == true, className)
	end
	for district = 1, layout.Outposts do
		local angle = district / layout.Outposts * math.pi * 2 + 0.35
		local position = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * board * layout.OutpostRadius
		local frame = CFrame.lookAt(position, Vector3.new(center.X, position.Y, center.Z))
		local height = palette.Height + (district % 3) * 4
		local width = layout.TerraceWidth
		make("RaisedOutpost", Vector3.new(width, height, width), frame * CFrame.new(0, height / 2, 0), nil, nil, true)
		make("OutpostSurface", Vector3.new(width, 0.5, width), frame * CFrame.new(0, height + 0.25, 0), palette.Surface, definition.Element == "Earth" and Enum.Material.Grass or palette.Material, true)
		-- Opposing wedges give ground-based AI and players a continuous climb.
		for _, side in ipairs({-1, 1}) do
			local ramp = frame * CFrame.new(0, height / 2, side * (width / 2 + layout.RampLength / 2))
			if side == 1 then ramp *= CFrame.Angles(0, math.pi, 0) end
			make("OutpostRamp", Vector3.new(layout.RampWidth, height, layout.RampLength), ramp, palette.Surface, nil, true, "WedgePart")
		end
		local top = frame * CFrame.new(width * 0.32, height, 0)
		if definition.Element == "Fire" then
			local basin = make("Caldera", Vector3.new(7, 26, 26), top * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.pi / 2))
			basin.Shape = Enum.PartType.Cylinder
			local lava = make("MoltenCaldera", Vector3.new(0.4, 20, 20), top * CFrame.new(0, 7.2, 0) * CFrame.Angles(0, 0, math.pi / 2), palette.Accent, Enum.Material.Neon)
			lava.Shape = Enum.PartType.Cylinder
			lava:SetAttribute("AmbientElement", "Fire")
		elseif definition.Element == "Ice" then
			for shard = 1, 5 do
				make("GlacierCrown", Vector3.new(4, 15 + shard * 3, 7), top * CFrame.new((shard - 3) * 4, 8, 0) * CFrame.Angles(0, shard, (shard - 3) * 0.16), palette.Accent, Enum.Material.Ice, false, "WedgePart")
			end
			local mist = make("FrostSource", Vector3.one, top, palette.Accent)
			mist.Transparency = 1
			mist:SetAttribute("AmbientElement", "Ice")
		elseif definition.Element == "Lightning" then
			for _, side in ipairs({-1, 1}) do
				make("StormArchPillar", Vector3.new(5, 30, 5), top * CFrame.new(side * 11, 15, 0))
			end
			make("StormArchLintel", Vector3.new(30, 5, 7), top * CFrame.new(0, 31, 0))
			local core = make("StormConductor", Vector3.new(2, 12, 2), top * CFrame.new(0, 30, 0), palette.Accent, Enum.Material.Neon)
			core:SetAttribute("AmbientElement", "Lightning")
		else
			make("AncientCedar", Vector3.new(8, 34, 8), top * CFrame.new(0, 17, 0), Color3.fromRGB(83, 60, 39), Enum.Material.Wood)
			for branch = 1, 5 do
				local crown = make("CedarCanopy", Vector3.new(27, 17, 25), top * CFrame.new(math.cos(branch * 2.4) * 10, 29 + branch * 2, math.sin(branch * 2.4) * 10), palette.Surface, Enum.Material.LeafyGrass)
				crown.Shape = Enum.PartType.Ball
			end
			local pollen = make("GrovePollen", Vector3.one, top * CFrame.new(0, 14, 0))
			pollen.Transparency = 1
			pollen:SetAttribute("AmbientElement", "Earth")
		end
		-- Move the existing district sign and plaza onto their new terrace.
		local biome = parent:FindFirstChild("ProceduralBiome")
		local plaza = biome and biome:FindFirstChild("DistrictPlaza" .. district)
		local marker = biome and biome:FindFirstChild("DistrictMarker" .. district)
		if plaza then plaza.Position = position + Vector3.new(0, height + 0.7, 0) end
		if marker then marker.Position = position + Vector3.new(-20, height + marker.Size.Y / 2 + 1, 18) end
	end
	-- Distant silhouettes surround the square arena without filling combat lanes.
	for index = 1, layout.Mountains do
		local angle = index / layout.Mountains * math.pi * 2
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local radius = (board * 0.5 + 38) / math.max(math.abs(direction.X), math.abs(direction.Z))
		local height = random:NextNumber(65, 150)
		local frame = CFrame.new(center + direction * radius + Vector3.new(0, height / 2 - 12, 0)) * CFrame.Angles(0, angle, 0)
		make("HorizonMassif", Vector3.new(100, height, 120), frame, nil, nil, false, "WedgePart")
		if definition.Element == "Ice" or definition.Element == "Earth" then
			make("MountainCap", Vector3.new(56, height * 0.5, 70), frame * CFrame.new(0, height * 0.25, 0), palette.Surface, definition.Element == "Ice" and Enum.Material.Snow or Enum.Material.Grass, false, "WedgePart")
		end
	end
	return function() folder:Destroy() end
end

-- Only walkable scenery is queried; decorative crowns and mountain silhouettes
-- never become enemy spawn surfaces.
function RealmScenery.GroundPosition(realm, position)
	local floor = realm and realm:FindFirstChild("RealmFloor")
	if not floor then return position end
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = {floor, realm:FindFirstChild("RealmScenery") or floor}
	parameters.RespectCanCollide = true
	local hit = workspace:Raycast(position + Vector3.new(0, 180, 0), Vector3.new(0, -360, 0), parameters)
	return hit and Vector3.new(position.X, hit.Position.Y + 3, position.Z) or position
end

return RealmScenery
