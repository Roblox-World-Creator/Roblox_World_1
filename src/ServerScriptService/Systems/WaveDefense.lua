local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyAI = require(script.Parent.EnemyAI)
local BossPhaseController = require(script.Parent.BossPhaseController)
local AssetModelService = require(script.Parent.AssetModelService)
local RealmConfig = require(ReplicatedStorage.Shared.RealmConfig)

local WaveDefense = {}
local runtimeState
local HUB_CENTER = Vector3.new(0, 4, -700)
local HUB_SPAWN = HUB_CENTER + Vector3.new(0, 0, -48)

local function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local function createPart(parent, name, size, position, color, material)
	local part = parent:FindFirstChild(name)
	if not part then
		part = Instance.new("Part")
		part.Name = name
		part.Parent = parent
	end
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = true
	part.Color = color
	part.Material = material
	return part
end

local function createTruss(parent, name, size, position, color)
	local truss = parent:FindFirstChild(name)
	if not truss or not truss:IsA("TrussPart") then
		if truss then
			truss:Destroy()
		end
		truss = Instance.new("TrussPart")
		truss.Name = name
		truss.Parent = parent
	end
	truss.Size = size
	truss.Position = position
	truss.Anchored = true
	truss.CanCollide = true
	truss.Color = color
	truss.Material = Enum.Material.Metal
	return truss
end

local function addLabel(parent, text, offset)
	local label = parent:FindFirstChild("WorldLabel") or Instance.new("BillboardGui")
	label.Name = "WorldLabel"
	label.Size = UDim2.fromOffset(150, 30)
	label.StudsOffset = offset
	label.AlwaysOnTop = true
	label.MaxDistance = 105
	label.Parent = parent
	local textLabel = label:FindFirstChild("Text") or Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.25
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextScaled = true
	textLabel.Parent = label
end

local function createPickup(parent, name, position, color, attribute, amount)
	local pickup = parent:FindFirstChild(name) or Instance.new("Part")
	pickup.Name = name
	pickup.Shape = Enum.PartType.Ball
	pickup.Size = Vector3.new(2, 2, 2)
	pickup.Position = position
	pickup.Anchored = true
	pickup.CanCollide = false
	pickup.Material = Enum.Material.Neon
	pickup.Color = color
	pickup:SetAttribute("PickupAttribute", attribute)
	pickup:SetAttribute("PickupAmount", amount)
	pickup.Parent = parent
	addLabel(pickup, name, Vector3.new(0, 2.5, 0))
	if not pickup:GetAttribute("PickupConnected") then
		pickup:SetAttribute("PickupConnected", true)
		pickup.Touched:Connect(function(hit)
			local character = hit.Parent
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local player = humanoid and Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			if attribute == "Health" then
				humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + amount)
			else
				local current = player:GetAttribute("MP") or player:GetAttribute(attribute) or 0
				local maximum = player:GetAttribute("MaxMP") or player:GetAttribute("MaxEnergy") or 100
				local restored = math.min(maximum, current + amount)
				player:SetAttribute("MP", restored)
				player:SetAttribute("Energy", restored)
			end
			pickup:SetAttribute("CollectedAt", os.clock())
			pickup.Transparency = 1
			task.delay(8, function()
				if pickup.Parent then
					pickup.Transparency = 0
				end
			end)
		end)
	end
end

local function createWarpPad(parent, name, position, destination, color, realmId, labelText)
	local pad = createPart(parent, name, Vector3.new(8, 0.35, 8), position, color, Enum.Material.Neon)
	pad.CanCollide = false
	pad:SetAttribute("WarpDestination", destination)
	pad:SetAttribute("RealmId", realmId or "Fort")
	addLabel(pad, labelText or (name .. " WARP"), Vector3.new(0, 3.2, 0))
	if not pad:GetAttribute("WarpConnected") then
		pad:SetAttribute("WarpConnected", true)
		pad.Touched:Connect(function(hit)
			local character = hit.Parent
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local player = humanoid and Players:GetPlayerFromCharacter(character)
			if not player or humanoid.Health <= 0 or os.clock() < (player:GetAttribute("WarpReadyAt") or 0) then return end
			player:SetAttribute("WarpReadyAt", os.clock() + 1.5)
			local currentDestination = pad:GetAttribute("WarpDestination") or destination
			character:PivotTo(CFrame.new(currentDestination + Vector3.new(0, 4, 0)))
		end)
	end
	return pad
end

local function placeImportedProp(parent, profile, position, targetHeight, yaw)
	local model = AssetModelService.Clone("WorldProps", profile)
	if not model then return nil end
	model.Name = profile
	model.Parent = parent
	local _, size = model:GetBoundingBox()
	if size.Y > 0.01 then pcall(function() model:ScaleTo(math.clamp(targetHeight / size.Y, 0.05, 4)) end) end
	AssetModelService.WeldModel(model)
	local pivot = model:GetPivot()
	local boxCFrame, boxSize = model:GetBoundingBox()
	local pivotToBox = pivot:ToObjectSpace(boxCFrame)
	local targetBox = CFrame.new(position + Vector3.new(0, boxSize.Y * 0.5, 0)) * CFrame.Angles(0, yaw or 0, 0)
	model:PivotTo(targetBox * pivotToBox:Inverse())
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = true
			object.CanTouch = false
		end
	end
	return model
end

local function createElementalRealms(portalHome)
	local realms = getOrCreateFolder(workspace, "ElementalRealms")
	local groundMaterials = {Fire = Enum.Material.Basalt, Ice = Enum.Material.Glacier, Lightning = Enum.Material.Slate, Earth = Enum.Material.Grass}
	local accentMaterials = {Fire = Enum.Material.CrackedLava, Ice = Enum.Material.Ice, Lightning = Enum.Material.Metal, Earth = Enum.Material.Ground}
	for _, realmId in ipairs(RealmConfig.Order) do
		local definition = RealmConfig.Realms[realmId]
		local realm = getOrCreateFolder(realms, realmId)
		local center = definition.Destination
		local floor = createPart(realm, "RealmFloor", Vector3.new(220, 3, 220), center - Vector3.new(0, 2.5, 0), definition.Color:Lerp(Color3.fromRGB(28, 30, 38), 0.68), groundMaterials[definition.Element] or Enum.Material.Slate)
		floor:SetAttribute("Element", definition.Element)
		local shrineBase = createPart(realm, "ShrinePlaza", Vector3.new(34, 2, 34), center - Vector3.new(0, 0.5, 0), definition.Color:Lerp(Color3.fromRGB(40, 44, 55), 0.52), Enum.Material.Slate)
		shrineBase.Shape = Enum.PartType.Cylinder
		shrineBase.Size = Vector3.new(2, 34, 34)
		shrineBase.CFrame = CFrame.new(center - Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
		local shrine = createPart(realm, "ElementShrine", Vector3.new(10, 22, 10), center + Vector3.new(0, 10, 0), definition.Color, Enum.Material.Neon)
		addLabel(shrine, string.format("%s\nRecommended Level %d\nBoss: %s\nRare: %s", definition.DisplayName, definition.RecommendedLevel, definition.Boss, definition.RareDrop), Vector3.new(0, 12, 0))
		for index, offset in ipairs({Vector3.new(0, 0, -62), Vector3.new(0, 0, 62), Vector3.new(-62, 0, 0), Vector3.new(62, 0, 0)}) do
			local horizontal = index >= 3
			createPart(realm, "RealmPath" .. index, horizontal and Vector3.new(52, 0.6, 10) or Vector3.new(10, 0.6, 52), center + offset * 0.55 - Vector3.new(0, 0.65, 0), definition.Color:Lerp(Color3.fromRGB(75, 78, 90), 0.55), Enum.Material.Cobblestone)
		end
		for index = 1, 12 do
			local angle = index / 12 * math.pi * 2
			local radius = index % 2 == 0 and 88 or 72
			local height = 7 + index % 4 * 3
			local width = 5 + index % 3 * 2
			createPart(realm, "ElementPillar" .. index, Vector3.new(width, height, width), center + Vector3.new(math.cos(angle) * radius, height / 2 - 1, math.sin(angle) * radius), definition.Color:Lerp(Color3.new(1, 1, 1), 0.14), index % 3 == 0 and Enum.Material.Neon or Enum.Material.Rock)
		end
		for index = 1, 16 do
			local angle = index / 16 * math.pi * 2
			local radius = index % 2 == 0 and 102 or 94
			local height = 5 + (index * 3) % 9
			local cluster = createPart(realm, "TerrainCluster" .. index, Vector3.new(10 + index % 4 * 3, height, 9 + (index + 2) % 4 * 3), center + Vector3.new(math.cos(angle) * radius, height / 2 - 1.2, math.sin(angle) * radius), definition.Color:Lerp(Color3.fromRGB(45, 48, 52), 0.62), accentMaterials[definition.Element] or Enum.Material.Rock)
			cluster.Orientation = Vector3.new((index % 3 - 1) * 5, math.deg(angle) + 20, (index % 2) * 4)
		end
		for index = 1, 6 do
			local angle = index / 6 * math.pi * 2 + math.rad(18)
			local beaconPosition = center + Vector3.new(math.cos(angle) * 54, 2.2, math.sin(angle) * 54)
			local beacon = createPart(realm, "RealmBeacon" .. index, Vector3.new(1.4, 5.5, 1.4), beaconPosition, definition.Color, Enum.Material.Neon)
			beacon.CanCollide = false
			local light = beacon:FindFirstChildOfClass("PointLight") or Instance.new("PointLight")
			light.Color, light.Brightness, light.Range, light.Parent = definition.Color, 2.2, 24, beacon
		end
		if definition.Element == "Earth" then
			for index = 1, 8 do
				local angle = index / 8 * math.pi * 2 + 0.2
				local position = center + Vector3.new(math.cos(angle) * 78, 0, math.sin(angle) * 78)
				createPart(realm, "TreeTrunk" .. index, Vector3.new(3, 11, 3), position + Vector3.new(0, 4.5, 0), Color3.fromRGB(92, 62, 38), Enum.Material.Wood)
				local crown = createPart(realm, "TreeCrown" .. index, Vector3.new(11, 9, 11), position + Vector3.new(0, 12, 0), definition.Color, Enum.Material.Grass)
				crown.Shape = Enum.PartType.Ball
			end
		elseif definition.Element == "Fire" then
			for index = 1, 8 do
				local angle = index / 8 * math.pi * 2 + 0.35
				local vent = createPart(realm, "LavaVent" .. index, Vector3.new(5, 0.5, 12), center + Vector3.new(math.cos(angle) * 66, -0.7, math.sin(angle) * 66), Color3.fromRGB(255, 70, 20), Enum.Material.Neon)
				vent.CanCollide = false
				vent.CFrame = CFrame.new(vent.Position) * CFrame.Angles(0, -angle, 0)
			end
		elseif definition.Element == "Ice" then
			for index = 1, 8 do
				local angle = index / 8 * math.pi * 2 + 0.45
				createPart(realm, "IceShelf" .. index, Vector3.new(14, 1.5, 20), center + Vector3.new(math.cos(angle) * 76, 0, math.sin(angle) * 76), Color3.fromRGB(155, 225, 255), Enum.Material.Ice)
			end
		elseif definition.Element == "Lightning" then
			for index = 1, 6 do
				local angle = index / 6 * math.pi * 2
				createPart(realm, "StormRod" .. index, Vector3.new(1, 18, 1), center + Vector3.new(math.cos(angle) * 78, 8, math.sin(angle) * 78), Color3.fromRGB(255, 230, 90), Enum.Material.Neon)
			end
		end
		for index, profile in ipairs(definition.Props or {}) do
			local angle = (index - 1) / math.max(#definition.Props, 1) * math.pi * 2 + math.rad(30)
			placeImportedProp(realm, profile, center + Vector3.new(math.cos(angle) * 48, -1, math.sin(angle) * 48), index == 1 and 16 or 10, -angle)
		end
		createWarpPad(realm, "ReturnToHub", center + Vector3.new(0, 0, 92), HUB_SPAWN, Color3.fromRGB(80, 220, 255), "Hub", "RETURN TO SAFE HUB")
	end

	local warps = getOrCreateFolder(portalHome, "Warps")
	for _, realmId in ipairs(RealmConfig.Order) do
		local definition = RealmConfig.Realms[realmId]
		local pad = warps:FindFirstChild(definition.PortalName)
		if pad then
			pad.Color = definition.Color
			pad:SetAttribute("WarpDestination", definition.Destination)
			pad:SetAttribute("RealmId", realmId)
			addLabel(pad, string.format("%s\nLEVEL %d+  |  %s", definition.DisplayName, definition.RecommendedLevel, definition.Boss), Vector3.new(0, 3.5, 0))
		end
	end
end

local function createItemPickup(parent, name, position, color, itemId, inventoryService)
	local pickup = createPart(parent, name, Vector3.new(2.5, 2.5, 2.5), position, color, Enum.Material.Neon)
	pickup.Shape = Enum.PartType.Ball
	pickup.CanCollide = false
	addLabel(pickup, itemId .. " PICKUP", Vector3.new(0, 2.5, 0))
	if not pickup:GetAttribute("ItemPickupConnected") then
		pickup:SetAttribute("ItemPickupConnected", true)
		pickup.Touched:Connect(function(hit)
			local character = hit.Parent
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local player = humanoid and Players:GetPlayerFromCharacter(character)
			if not player or pickup:GetAttribute("CollectedAt") and os.clock() - pickup:GetAttribute("CollectedAt") < 8 then return end
			local success = inventoryService and inventoryService.Grant(player, itemId, 1)
			if success then
				pickup:SetAttribute("CollectedAt", os.clock())
				pickup.Transparency = 1
				task.delay(8, function() if pickup.Parent then pickup.Transparency = 0 end end)
			end
		end)
	end
end

local function createWorldDecor(config, arena, core, inventoryService)
	local structures = getOrCreateFolder(arena, "Structures")
	local fort = getOrCreateFolder(structures, "AscendantFort")
	local items = getOrCreateFolder(arena, "DefaultItems")
	local stone = Color3.fromRGB(75, 82, 105)
	local trim = Color3.fromRGB(70, 220, 255)
	local darkStone = Color3.fromRGB(42, 50, 70)
	for index, position in ipairs({
		Vector3.new(-32, 6, -32), Vector3.new(32, 6, -32),
		Vector3.new(-32, 6, 32), Vector3.new(32, 6, 32),
	}) do
		local tower = getOrCreateFolder(structures, "Watchtower" .. index)
		createPart(tower, "Base", Vector3.new(8, 2, 8), position - Vector3.new(0, 5, 0), stone, Enum.Material.Slate)
		createPart(tower, "Tower", Vector3.new(5, 10, 5), position, stone, Enum.Material.Brick)
		local beacon = createPart(tower, "Beacon", Vector3.new(2, 2, 2), position + Vector3.new(0, 6, 0), trim, Enum.Material.Neon)
		local light = beacon:FindFirstChildOfClass("PointLight") or Instance.new("PointLight")
		light.Color = trim
		light.Range = 18
		light.Brightness = 2
		light.Parent = beacon
	end
	createPart(structures, "NorthWall", Vector3.new(70, 5, 2), Vector3.new(0, 2.5, -70), stone, Enum.Material.Brick)
	createPart(structures, "SouthWall", Vector3.new(70, 5, 2), Vector3.new(0, 2.5, 70), stone, Enum.Material.Brick)
	createPart(structures, "EastWall", Vector3.new(2, 5, 70), Vector3.new(70, 2.5, 0), stone, Enum.Material.Brick)
	createPart(structures, "WestWall", Vector3.new(2, 5, 70), Vector3.new(-70, 2.5, 0), stone, Enum.Material.Brick)

	-- Gated inner walls keep the core readable while leaving four pathfinding entrances.
	for _, wall in ipairs({
		{"NorthWest", Vector3.new(42, 12, 4), Vector3.new(-29, 6, -55)},
		{"NorthEast", Vector3.new(42, 12, 4), Vector3.new(29, 6, -55)},
		{"SouthWest", Vector3.new(42, 12, 4), Vector3.new(-29, 6, 55)},
		{"SouthEast", Vector3.new(42, 12, 4), Vector3.new(29, 6, 55)},
		{"WestNorth", Vector3.new(4, 12, 42), Vector3.new(-55, 6, -29)},
		{"WestSouth", Vector3.new(4, 12, 42), Vector3.new(-55, 6, 29)},
		{"EastNorth", Vector3.new(4, 12, 42), Vector3.new(55, 6, -29)},
		{"EastSouth", Vector3.new(4, 12, 42), Vector3.new(55, 6, 29)},
	}) do
		createPart(fort, "GateWall" .. wall[1], wall[2], wall[3], darkStone, Enum.Material.Brick)
	end

	-- A four-sided lower deck surrounds the defense core without covering it.
	createPart(fort, "NorthDeck", Vector3.new(48, 2, 12), Vector3.new(0, 10, -18), stone, Enum.Material.Slate)
	createPart(fort, "SouthDeck", Vector3.new(48, 2, 12), Vector3.new(0, 10, 18), stone, Enum.Material.Slate)
	createPart(fort, "EastDeck", Vector3.new(12, 2, 24), Vector3.new(18, 10, 0), stone, Enum.Material.Slate)
	createPart(fort, "WestDeck", Vector3.new(12, 2, 24), Vector3.new(-18, 10, 0), stone, Enum.Material.Slate)

	local northRamp = createPart(fort, "NorthRamp", Vector3.new(12, 1, 32), Vector3.new(0, 5.2, -38), stone, Enum.Material.Slate)
	northRamp.CFrame = CFrame.new(northRamp.Position) * CFrame.Angles(math.rad(-17), 0, 0)
	local southRamp = createPart(fort, "SouthRamp", Vector3.new(12, 1, 32), Vector3.new(0, 5.2, 38), stone, Enum.Material.Slate)
	southRamp.CFrame = CFrame.new(southRamp.Position) * CFrame.Angles(math.rad(17), 0, 0)
	local eastRamp = createPart(fort, "EastRamp", Vector3.new(32, 1, 12), Vector3.new(38, 5.2, 0), stone, Enum.Material.Slate)
	eastRamp.CFrame = CFrame.new(eastRamp.Position) * CFrame.Angles(0, 0, math.rad(-17))
	local westRamp = createPart(fort, "WestRamp", Vector3.new(32, 1, 12), Vector3.new(-38, 5.2, 0), stone, Enum.Material.Slate)
	westRamp.CFrame = CFrame.new(westRamp.Position) * CFrame.Angles(0, 0, math.rad(17))

	-- Upper battlement ring and four climbable lookout towers provide vertical combat space.
	createPart(fort, "UpperNorth", Vector3.new(100, 1.5, 9), Vector3.new(0, 17, -48), darkStone, Enum.Material.Metal)
	createPart(fort, "UpperSouth", Vector3.new(100, 1.5, 9), Vector3.new(0, 17, 48), darkStone, Enum.Material.Metal)
	createPart(fort, "UpperEast", Vector3.new(9, 1.5, 87), Vector3.new(48, 17, 0), darkStone, Enum.Material.Metal)
	createPart(fort, "UpperWest", Vector3.new(9, 1.5, 87), Vector3.new(-48, 17, 0), darkStone, Enum.Material.Metal)
	for index, position in ipairs({
		Vector3.new(-48, 9, -48),
		Vector3.new(48, 9, -48),
		Vector3.new(-48, 9, 48),
		Vector3.new(48, 9, 48),
	}) do
		createPart(fort, "TowerPillar" .. index, Vector3.new(9, 17, 9), position, stone, Enum.Material.Brick)
		createPart(fort, "TowerDeck" .. index, Vector3.new(16, 1.5, 16), position + Vector3.new(0, 8.5, 0), darkStone, Enum.Material.Metal)
		local inward = Vector3.new(-math.sign(position.X) * 6, 0, -math.sign(position.Z) * 6)
		createTruss(fort, "TowerLadder" .. index, Vector3.new(2, 17, 2), position + inward, trim)
		local beacon = createPart(fort, "TowerBeacon" .. index, Vector3.new(2, 5, 2), position + Vector3.new(0, 12, 0), trim, Enum.Material.Neon)
		beacon.CanCollide = false
		local light = beacon:FindFirstChildOfClass("PointLight") or Instance.new("PointLight")
		light.Color = trim
		light.Brightness = 2
		light.Range = 30
		light.Parent = beacon
	end
	createPickup(items, "HealthCrystal", Vector3.new(-12, 2, 12), Color3.fromRGB(255, 75, 105), "Health", 35)
	createPickup(items, "EnergyCrystal", Vector3.new(12, 2, 12), Color3.fromRGB(80, 180, 255), "Energy", 35)
	createPickup(items, "HealthCrystal2", Vector3.new(-12, 2, -12), Color3.fromRGB(255, 75, 105), "Health", 35)
	createPickup(items, "EnergyCrystal2", Vector3.new(12, 2, -12), Color3.fromRGB(80, 180, 255), "Energy", 35)
	createItemPickup(items, "HealthCorePickup", Vector3.new(-88, 2, 0), Color3.fromRGB(255, 80, 110), "HealthPotion", inventoryService)
	createItemPickup(items, "ManaCrystalPickup", Vector3.new(88, 2, 0), Color3.fromRGB(80, 180, 255), "ManaPotion", inventoryService)
	createItemPickup(items, "RiftShardPickup", Vector3.new(0, 2, 88), Color3.fromRGB(185, 100, 255), "EvolutionShard", inventoryService)
	local kiosk = createPart(structures, "FortSupplyKiosk", Vector3.new(8, 6, 5), Vector3.new(29, 3, -29), Color3.fromRGB(45, 58, 82), Enum.Material.Metal)
	local kioskGlow = createPart(structures, "FortSupplyKioskGlow", Vector3.new(6.5, 1.2, 0.3), Vector3.new(29, 4.5, -26.35), Color3.fromRGB(90, 205, 255), Enum.Material.Neon)
	kioskGlow.CanCollide = false
	addLabel(kiosk, "FORT SUPPLY  •  BAG [B] → STORE", Vector3.new(0, 4.5, 0))
	local questBoard = createPart(structures, "AscendantQuestBoard", Vector3.new(8, 6, 1), Vector3.new(-29, 3, -29), Color3.fromRGB(75, 52, 110), Enum.Material.Wood)
	addLabel(questBoard, "ASCENDANT QUESTS  [J]", Vector3.new(0, 4.5, 0))
	addLabel(core, "DEFENSE CORE", Vector3.new(0, 7, 0))
end

local function createArena(config, inventoryService)
	local arena = getOrCreateFolder(workspace, "Arena")
	local spawns = getOrCreateFolder(workspace, "EnemySpawns")
	local waypoints = getOrCreateFolder(workspace, "EnemyWaypoints")

	createPart(arena, "ArenaFloor", Vector3.new(config.ArenaRadius * 2, 1, config.ArenaRadius * 2), Vector3.new(0, 0, 0), Color3.fromRGB(35, 42, 58), Enum.Material.Slate)
	local boundary = config.ArenaRadius - 1
	local wallColor = Color3.fromRGB(48, 58, 82)
	createPart(arena, "BoundaryNorth", Vector3.new(config.ArenaRadius * 2, 18, 3), Vector3.new(0, 9, -boundary), wallColor, Enum.Material.Brick)
	createPart(arena, "BoundarySouth", Vector3.new(config.ArenaRadius * 2, 18, 3), Vector3.new(0, 9, boundary), wallColor, Enum.Material.Brick)
	createPart(arena, "BoundaryEast", Vector3.new(3, 18, config.ArenaRadius * 2), Vector3.new(boundary, 9, 0), wallColor, Enum.Material.Brick)
	createPart(arena, "BoundaryWest", Vector3.new(3, 18, config.ArenaRadius * 2), Vector3.new(-boundary, 9, 0), wallColor, Enum.Material.Brick)
	local hub = getOrCreateFolder(workspace, "AscendantSafeHub")
	createPart(hub, "HubFloor", Vector3.new(170, 2, 120), HUB_CENTER - Vector3.new(0, 4, 0), Color3.fromRGB(29, 40, 58), Enum.Material.Slate)
	local hubBeacon = createPart(hub, "HubBeacon", Vector3.new(8, 18, 8), HUB_CENTER + Vector3.new(0, 5, 20), Color3.fromRGB(80, 210, 255), Enum.Material.Neon)
	addLabel(hubBeacon, "ASCENDANT SAFE HUB\nChoose a realm or enter Wave Defense", Vector3.new(0, 12, 0))
	local warps = getOrCreateFolder(hub, "Warps")
	createWarpPad(warps, "NORTH", HUB_CENTER + Vector3.new(-48, -3, -28), Vector3.zero, Color3.fromRGB(80, 220, 255))
	createWarpPad(warps, "WEST", HUB_CENTER + Vector3.new(48, -3, -28), Vector3.zero, Color3.fromRGB(190, 130, 255))
	createWarpPad(warps, "EAST", HUB_CENTER + Vector3.new(-48, -3, 24), Vector3.zero, Color3.fromRGB(255, 190, 80))
	createWarpPad(warps, "SOUTH", HUB_CENTER + Vector3.new(48, -3, 24), Vector3.zero, Color3.fromRGB(100, 255, 180))
	createWarpPad(warps, "WaveDefense", HUB_CENTER + Vector3.new(0, -3, 42), Vector3.new(0, 18, -48), Color3.fromRGB(255, 90, 115), "Arena", "ENTER WAVE DEFENSE")
	createElementalRealms(hub)
	createWarpPad(arena, "ReturnToSafeHub", Vector3.new(0, 1, -92), HUB_SPAWN, Color3.fromRGB(80, 220, 255), "Hub", "RETURN TO SAFE HUB")
	local spawnLocation = workspace:FindFirstChild("SpawnLocation")
	if spawnLocation and spawnLocation:IsA("SpawnLocation") then
		spawnLocation.Size = Vector3.new(10, 1, 10)
		spawnLocation.Position = HUB_SPAWN + Vector3.new(0, -2.5, 0)
		spawnLocation.Neutral = true
	end

	local core = createPart(workspace, "DefenseCore", Vector3.new(8, 10, 8), config.CorePosition, Color3.fromRGB(70, 220, 255), Enum.Material.Neon)
	core:SetAttribute("MaxHealth", config.BaseCoreHealth)
	core:SetAttribute("Health", config.BaseCoreHealth)
	createWorldDecor(config, arena, core, inventoryService)
	
	local coreLight = core:FindFirstChildOfClass("PointLight")
	if not coreLight then
		coreLight = Instance.new("PointLight")
		coreLight.Color = core.Color
		coreLight.Range = 24
		coreLight.Brightness = 3
		coreLight.Parent = core
	end

	for index = 1, config.WaypointCount do
		local angle = (index / config.WaypointCount) * math.pi * 2
		local position = Vector3.new(math.cos(angle) * config.WaypointRadius, config.EnemyHeight, math.sin(angle) * config.WaypointRadius)
		local waypoint = createPart(waypoints, string.format("Waypoint%02d", index), Vector3.new(3, 0.35, 3), position, Color3.fromRGB(100, 190, 255), Enum.Material.Neon)
		waypoint.Transparency = 0.35
		local spawnPosition = Vector3.new(math.cos(angle) * config.EnemySpawnRadius, config.EnemyHeight, math.sin(angle) * config.EnemySpawnRadius)
		local spawn = createPart(spawns, string.format("Spawn%02d", index), Vector3.new(6, 0.4, 6), spawnPosition, Color3.fromRGB(255, 75, 100), Enum.Material.Neon)
		spawn.Transparency = 0.2
		local oldLabel = spawn:FindFirstChild("WorldLabel")
		if oldLabel then oldLabel:Destroy() end
		local spawnLight = spawn:FindFirstChildOfClass("PointLight") or Instance.new("PointLight")
		spawnLight.Color = spawn.Color
		spawnLight.Range = 12
		spawnLight.Brightness = 1.5
		spawnLight.Parent = spawn
	end

	return arena, spawns, waypoints, core
end

local function sortedChildren(folder)
	local children = folder:GetChildren()
	table.sort(children, function(left, right)
		return left.Name < right.Name
	end)
	return children
end

local function createEnemy(enemyType, definition, healthScale, damageScale, speedBonus, position, parent, eliteName, eliteDefinition)
	local model = Instance.new("Model")
	local displayName = eliteName and string.format("%s %s", string.upper(eliteName), definition.DisplayName) or definition.DisplayName
	model.Name = displayName
	model:SetAttribute("EnemyType", enemyType)
	local rewardMultiplier = eliteDefinition and eliteDefinition.RewardMultiplier or 1
	model:SetAttribute("RewardXP", math.floor(definition.RewardXP * rewardMultiplier))
	model:SetAttribute("RewardCoins", math.floor(definition.RewardCoins * rewardMultiplier))
	model:SetAttribute("AttackDamage", definition.Damage * damageScale * (eliteDefinition and eliteDefinition.DamageMultiplier or 1))
	model:SetAttribute("KnockbackResistance", definition.KnockbackResistance or 0)
	model:SetAttribute("StunResistance", definition.StunResistance or 0)
	model:SetAttribute("DamageTakenMultiplier", eliteDefinition and eliteDefinition.DamageTakenMultiplier or 1)
	model:SetAttribute("IsElite", eliteName ~= nil)
	model:SetAttribute("EliteModifier", eliteName)
	model:SetAttribute("AbilityName", definition.Ability or "Basic Strike")
	model:SetAttribute("AttackStyle", definition.AttackStyle or "Melee")
	model:SetAttribute("AttackRange", definition.AttackRange)
	model:SetAttribute("AbilityRadius", definition.AbilityRadius)
	model:SetAttribute("StatusEffect", definition.StatusEffect)
	model:SetAttribute("LootTier", definition.LootTier or enemyType)
	model:SetAttribute("AbilityColor", definition.Color)
	model:SetAttribute("FlyingEnemy", definition.Flying == true)
	model:SetAttribute("HoverHeight", definition.HoverHeight or 0)

	local body = Instance.new("Part")
	body.Name = "HumanoidRootPart"
	body.Size = Vector3.new(2, 2, 1)
	body.Position = position
	body.Transparency = 1
	body.Anchored = false
	-- The prototype made every enemy part non-collidable, causing the whole
	-- unanchored assembly to fall through the arena as soon as it spawned.
	body.CanCollide = true
	body.RootPriority = 127
	body.Parent = model

	local scale = enemyType == "Boss" and 1.7 or 1
	local fallbackLimbs = {}
	local function addLimb(name, size, offset, color, shape)
		local limb = Instance.new("Part")
		limb.Name = name
		limb.Size = size * scale
		limb.Position = position + offset * scale
		limb.Color = color
		limb.Material = Enum.Material.SmoothPlastic
		limb.Shape = shape or Enum.PartType.Block
		limb.CanCollide = false
		limb.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = limb
		weld.Parent = limb
		table.insert(fallbackLimbs, limb)
		return limb
	end

	addLimb("Torso", Vector3.new(2.2, 2.4, 1.2), Vector3.new(0, 2.6, 0), definition.Color)
	addLimb("Head", Vector3.new(1.5, 1.5, 1.5), Vector3.new(0, 4.5, 0), Color3.fromRGB(255, 205, 170), Enum.PartType.Ball)
	addLimb("LeftArm", Vector3.new(0.65, 2.3, 0.65), Vector3.new(-1.55, 2.55, 0), definition.Color)
	addLimb("RightArm", Vector3.new(0.65, 2.3, 0.65), Vector3.new(1.55, 2.55, 0), definition.Color)
	addLimb("LeftLeg", Vector3.new(0.8, 2.4, 0.8), Vector3.new(-0.65, 0.2, 0), Color3.fromRGB(35, 45, 75))
	addLimb("RightLeg", Vector3.new(0.8, 2.4, 0.8), Vector3.new(0.65, 0.2, 0), Color3.fromRGB(35, 45, 75))

	local importedVisual = definition.ModelProfile and AssetModelService.Clone(enemyType == "Boss" and "Bosses" or "Enemies", definition.ModelProfile)
	if importedVisual then
		importedVisual.Name = "ImportedVisual"
		importedVisual.Parent = model
		local _, visualSize = importedVisual:GetBoundingBox()
		local targetHeight = definition.VisualHeight or (enemyType == "Boss" and 12 or (definition.Health >= 500 and 8 or 5.5))
		if visualSize.Y > 0.01 then pcall(function() importedVisual:ScaleTo(math.clamp(targetHeight / visualSize.Y, 0.04, 4)) end) end
		AssetModelService.WeldModel(importedVisual)
		local pivot = importedVisual:GetPivot()
		local boxCFrame, boxSize = importedVisual:GetBoundingBox()
		local pivotToBox = pivot:ToObjectSpace(boxCFrame)
		local hoverHeight = definition.HoverHeight or 0
		local targetBox = CFrame.new(position + Vector3.new(0, -body.Size.Y * 0.5 + hoverHeight + boxSize.Y * 0.5, 0))
		importedVisual:PivotTo(targetBox * pivotToBox:Inverse())
		local visualRoot = importedVisual.PrimaryPart
		if visualRoot then
			local motor = Instance.new("Motor6D")
			motor.Name, motor.Part0, motor.Part1 = definition.Flying and "EnemyFlightMotor" or "EnemyVisualMotor", body, visualRoot
			motor.C0, motor.C1, motor.Parent = body.CFrame:ToObjectSpace(visualRoot.CFrame), CFrame.identity, visualRoot
			if definition.Flying then
				motor:SetAttribute("AirC0", motor.C0)
				motor:SetAttribute("GroundC0", CFrame.new(0, -hoverHeight, 0) * motor.C0)
			end
		end
		for _, limb in ipairs(fallbackLimbs) do limb.Transparency = 1 end
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = definition.Health * healthScale * (eliteDefinition and eliteDefinition.HealthMultiplier or 1)
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = (definition.Speed + speedBonus) * (eliteDefinition and eliteDefinition.SpeedMultiplier or 1)
	model:SetAttribute("BaseWalkSpeed", humanoid.WalkSpeed)
	humanoid.DisplayName = displayName
	humanoid.BreakJointsOnDeath = false
	humanoid.AutoRotate = true
	humanoid.Parent = model

	local healthGui = Instance.new("BillboardGui")
	healthGui.Name = "HealthBar"
	healthGui.Adornee = body
	healthGui.Size = UDim2.fromOffset(enemyType == "Boss" and 220 or 110, enemyType == "Boss" and 32 or 22)
	healthGui.StudsOffset = Vector3.new(0, enemyType == "Boss" and 8 or 4.5, 0)
	healthGui.AlwaysOnTop = true
	healthGui.Parent = model
	local background = Instance.new("Frame")
	background.Size = UDim2.fromScale(1, 0.38)
	background.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	background.BorderSizePixel = 0
	background.Parent = healthGui
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = enemyType == "Boss" and Color3.fromRGB(255, 70, 100) or Color3.fromRGB(80, 235, 130)
	fill.BorderSizePixel = 0
	fill.Parent = background
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0.62)
	nameLabel.Position = UDim2.fromScale(0, 0.4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = displayName
	nameLabel.Parent = healthGui
	humanoid.HealthChanged:Connect(function(health)
		fill.Size = UDim2.fromScale(math.clamp(health / humanoid.MaxHealth, 0, 1), 1)
	end)

	model.PrimaryPart = body
	model.Parent = parent
	if eliteDefinition then
		if eliteDefinition.Scale then
			model:ScaleTo(eliteDefinition.Scale)
		end
		local eliteGlow = Instance.new("Highlight")
		eliteGlow.Name = "EliteGlow"
		eliteGlow.FillColor = eliteDefinition.Color
		eliteGlow.OutlineColor = Color3.new(1, 1, 1)
		eliteGlow.FillTransparency = 0.65
		eliteGlow.OutlineTransparency = 0.25
		eliteGlow.Parent = model
	end
	local networkSuccess, networkError = pcall(function()
		body:SetNetworkOwner(nil)
	end)
	if not networkSuccess then
		warn(string.format("Could not assign server ownership to %s: %s", model.Name, tostring(networkError)))
	end
	return model, humanoid, definition.Damage * damageScale
end

local function chooseEliteModifier(wave, waveConfig)
	if wave < waveConfig.EliteStartWave then
		return nil, nil
	end
	local chance = math.min(
		waveConfig.EliteMaximumChance,
		waveConfig.EliteBaseChance + (wave - waveConfig.EliteStartWave) * waveConfig.EliteChancePerWave
	)
	if math.random() > chance then
		return nil, nil
	end
	local names = {}
	for name in pairs(waveConfig.EliteModifiers) do
		table.insert(names, name)
	end
	table.sort(names)
	local name = names[math.random(1, #names)]
	return name, waveConfig.EliteModifiers[name]
end

local function getActivePlayerScale(config)
	local playerCount = math.clamp(#Players:GetPlayers(), 1, config.MaxPlayers)
	return 1 + ((playerCount - 1) * config.PlayersPerHealthScale)
end

local WAVE_ROSTER = {
	{Id = "Basic", Wave = 1}, {Id = "Fast", Wave = 2}, {Id = "FireImp", Wave = 3},
	{Id = "Tank", Wave = 4}, {Id = "FrostWolf", Wave = 5}, {Id = "StormOrc", Wave = 6},
	{Id = "StoneWarrior", Wave = 7}, {Id = "OrcChampion", Wave = 9},
	{Id = "LavaGolem", Wave = 11}, {Id = "IceGolem", Wave = 12}, {Id = "NullHunter", Wave = 14},
	{Id = "EarthGolem", Wave = 16}, {Id = "LabyrinthHorror", Wave = 18},
}

local function chooseEnemyType(wave, index)
	local available = {}
	for _, entry in ipairs(WAVE_ROSTER) do
		if wave >= entry.Wave then table.insert(available, entry.Id) end
	end
	if wave >= 20 and wave % 10 == 5 and index == 1 then return "RiftDragon" end
	if wave >= 8 and wave % 6 == 2 and index == 1 then return "AshwingDrake" end
	if wave % 5 == 0 and index == 1 then return "Tank" end
	return available[((index + wave - 2) % #available) + 1]
end

function WaveDefense.Start(gameConfig, enemyConfig, waveConfig, progressionConfig, progression, inventoryService, questService)
	local _, spawns, waypoints, core = createArena(gameConfig, inventoryService)
	local enemyFolder = getOrCreateFolder(workspace, "Enemies")
	runtimeState = {
		GameConfig = gameConfig,
		EnemyConfig = enemyConfig,
		WaveConfig = waveConfig,
		EnemyFolder = enemyFolder,
		Core = core,
	}
	local running = true
	local currentWave = 0
	local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
	local feedbackRemote = remotes:WaitForChild("CombatFeedback")
	local effectsRemote = remotes:WaitForChild("AbilityEffects")
	workspace:SetAttribute("HighestWave", 0)
	workspace:SetAttribute("WorldStatus", "Ready")

	local function setWaveAttributes(wave, remaining, state)
		workspace:SetAttribute("Wave", wave)
		workspace:SetAttribute("EnemiesRemaining", remaining)
		workspace:SetAttribute("WaveState", state)
	end

	local function activeWaveEnemyCount()
		local count = 0
		for _, enemy in ipairs(enemyFolder:GetChildren()) do
			if not enemy:GetAttribute("IsPractice") then
				count += 1
			end
		end
		return count
	end

	local function clearEnemies()
		for _, enemy in ipairs(enemyFolder:GetChildren()) do
			if not enemy:GetAttribute("IsPractice") then
				enemy:Destroy()
			end
		end
	end

	local function rewardWave(wave)
		local xp = waveConfig.CompletionBaseXP + wave * waveConfig.CompletionXPPerWave
		local gold = waveConfig.CompletionBaseGold + wave * waveConfig.CompletionGoldPerWave
		for _, player in ipairs(Players:GetPlayers()) do
			progression.AddXP(player, xp, progressionConfig)
			progression.AddCoins(player, gold)
			feedbackRemote:FireClient(player, "Reward", xp, gold)
			questService.Record(player, "Wave", 1)
		end
		effectsRemote:FireAllClients("WaveAnnouncement", {
			Title = "WAVE CLEARED",
			Subtitle = string.format("Wave %d  •  +%d XP  •  +%d Gold", wave, xp, gold),
			Color = Color3.fromRGB(100, 235, 170),
		})
	end

	local function rewardBoss(boss, humanoid, definition, wave)
		local minimumDamage = humanoid.MaxHealth * waveConfig.BossParticipationMinimum
		local multiplier = 1 + wave * waveConfig.BossRewardWaveMultiplier
		for _, player in ipairs(Players:GetPlayers()) do
			local contribution = boss:GetAttribute("Damage_" .. player.UserId) or 0
			if contribution >= minimumDamage then
				local xp = math.floor(definition.RewardXP * multiplier)
				local gold = math.floor(definition.RewardCoins * multiplier)
				progression.AddXP(player, xp, progressionConfig)
				progression.AddCoins(player, gold)
				feedbackRemote:FireClient(player, "Reward", xp, gold)
				inventoryService.GrantBossLoot(player, boss)
				questService.Record(player, "Boss", 1)
			end
		end
	end

	-- The hub is intentionally peaceful. Each demo realm has its own spaced mob set.
	for _, realmId in ipairs(RealmConfig.Order) do
		local realm = RealmConfig.Realms[realmId]
		for index, enemyType in ipairs(realm.Mobs or {}) do
			local definition = enemyConfig[enemyType]
			if definition then
				local angle = (index - 1) / math.max(#realm.Mobs, 1) * math.pi * 2 + math.rad(45)
				local radius = index % 2 == 0 and 72 or 48
				local position = realm.Destination + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
				local realmEnemy, realmHumanoid = createEnemy(enemyType, definition, 1, 1, 0, position, enemyFolder)
				realmEnemy:SetAttribute("IsPractice", true)
				realmEnemy:SetAttribute("IsRealmMob", true)
				realmEnemy:SetAttribute("RealmId", realmId)
				EnemyAI.Run(realmEnemy, core, gameConfig, true)
				realmHumanoid.Died:Connect(function()
					task.delay(0.25, function() if realmEnemy.Parent then realmEnemy:Destroy() end end)
				end)
			end
		end
	end
	setWaveAttributes(0, 0, "Safe Hub")

	task.spawn(function()
		while running do
			local debugWave = workspace:GetAttribute("DebugNextWave")
			if typeof(debugWave) == "number" then
				currentWave = math.clamp(math.floor(debugWave) - 1, 0, gameConfig.MaximumPrototypeWave - 1)
				workspace:SetAttribute("DebugNextWave", nil)
			end
			currentWave += 1
			if currentWave > gameConfig.MaximumPrototypeWave then
				currentWave = 1
			end
			setWaveAttributes(currentWave, activeWaveEnemyCount(), "Intermission")
			workspace:SetAttribute("HighestWave", math.max(workspace:GetAttribute("HighestWave") or 0, currentWave))
			for seconds = gameConfig.IntermissionSeconds, 1, -1 do
				workspace:SetAttribute("WaveCountdown", seconds)
				task.wait(1)
			end
			workspace:SetAttribute("WaveCountdown", 0)
			effectsRemote:FireAllClients("WaveAnnouncement", {
				Title = string.format("WAVE %d", currentWave),
				Subtitle = currentWave % 10 == 0 and "BOSS WAVE" or "DEFEND THE CORE",
				Color = currentWave % 10 == 0 and Color3.fromRGB(255, 80, 100) or Color3.fromRGB(90, 190, 255),
			})

			local playerScale = getActivePlayerScale(gameConfig)
			local healthScale = playerScale * (1 + currentWave * gameConfig.WaveHealthGrowth)
			local damageScale = 1 + currentWave * gameConfig.WaveDamageGrowth
			local speedBonus = math.min(currentWave * gameConfig.WaveSpeedGrowth, gameConfig.MaximumSpeedBonus)
			local enemyCount = 8 + currentWave * 2
			local spawnList = sortedChildren(spawns)
			setWaveAttributes(currentWave, enemyCount, "Active")

			for index = 1, enemyCount do
				local enemyType = chooseEnemyType(currentWave, index)
				local definition = enemyConfig[enemyType]
				local spawn = spawnList[((index - 1) % #spawnList) + 1]
				local eliteName, eliteDefinition = chooseEliteModifier(currentWave, waveConfig)
				local enemy, humanoid, damage = createEnemy(enemyType, definition, healthScale, damageScale, speedBonus, spawn.Position, enemyFolder, eliteName, eliteDefinition)
				humanoid.Died:Connect(function()
					task.delay(0.2, function()
						if enemy.Parent then
							enemy:Destroy()
						end
					end)
				end)
				EnemyAI.Run(enemy, core, gameConfig)
				task.wait(0.35)
			end

			if currentWave % 10 == 0 then
				local definition = enemyConfig.Boss
				local boss, humanoid, damage = createEnemy("Boss", definition, healthScale * (1 + currentWave * 0.3), damageScale, speedBonus, spawnList[1].Position, enemyFolder)
				local archetype = waveConfig.BossArchetypes[((math.floor(currentWave / 10) - 1) % #waveConfig.BossArchetypes) + 1]
				boss.Name = archetype.DisplayName
				humanoid.DisplayName = archetype.DisplayName
				boss:SetAttribute("BossArchetype", archetype.Id)
				local highlight = Instance.new("Highlight")
				highlight.Name, highlight.FillColor, highlight.OutlineColor = "BossArchetypeGlow", archetype.Color, Color3.new(1, 1, 1)
				highlight.FillTransparency, highlight.OutlineTransparency, highlight.Parent = 0.7, 0.15, boss
				boss:SetAttribute("BossWave", currentWave)
				humanoid.Died:Connect(function()
					rewardBoss(boss, humanoid, definition, currentWave)
					task.delay(0.2, function()
						if boss.Parent then
							boss:Destroy()
						end
					end)
				end)
				EnemyAI.Run(boss, core, gameConfig)
				BossPhaseController.Start(boss, waveConfig, gameConfig)
			end

			repeat
				task.wait(1)
				setWaveAttributes(currentWave, activeWaveEnemyCount(), "Active")
			until activeWaveEnemyCount() == 0 or (core:GetAttribute("Health") or 0) <= 0

			if (core:GetAttribute("Health") or 0) <= 0 then
				setWaveAttributes(currentWave, activeWaveEnemyCount(), "GameOver")
				clearEnemies()
				core:SetAttribute("Health", core:GetAttribute("MaxHealth"))
				task.wait(gameConfig.IntermissionSeconds)
			else
				rewardWave(currentWave)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function()
		if #Players:GetPlayers() == 0 then
			clearEnemies()
		end
	end)
end

function WaveDefense.SpawnAdminEnemy(enemyType, player)
	if not runtimeState then
		return false, "Wave system is not ready"
	end
	local bossArchetype = string.match(enemyType, "^Boss:(.+)$")
	local definition = runtimeState.EnemyConfig[bossArchetype and "Boss" or enemyType]
	if bossArchetype then enemyType = "Boss" end
	local character = player and player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not definition or not playerRoot then
		return false, "Enemy type or spawning player is unavailable"
	end

	local desired = playerRoot.Position + playerRoot.CFrame.LookVector * 18
	local raycastParameters = RaycastParams.new()
	raycastParameters.FilterType = Enum.RaycastFilterType.Exclude
	raycastParameters.FilterDescendantsInstances = {character, runtimeState.EnemyFolder}
	raycastParameters.RespectCanCollide = true
	local ground = workspace:Raycast(desired + Vector3.new(0, 24, 0), Vector3.new(0, -64, 0), raycastParameters)
	local spawnPosition = ground and (ground.Position + Vector3.new(0, runtimeState.GameConfig.EnemyHeight, 0))
		or desired
	local enemy, humanoid = createEnemy(enemyType, definition, 1, 1, 0, spawnPosition, runtimeState.EnemyFolder)
	enemy.Name = "Admin" .. enemyType
	enemy:SetAttribute("IsPractice", true)
	enemy:SetAttribute("IsAdminSpawn", true)
	if enemyType == "Boss" then
		enemy:SetAttribute("BossWave", 0)
		enemy:SetAttribute("BossArchetype", bossArchetype or "Stone")
		BossPhaseController.Start(enemy, runtimeState.WaveConfig, runtimeState.GameConfig)
	end
	humanoid.Died:Connect(function()
		task.delay(0.2, function()
			if enemy.Parent then
				enemy:Destroy()
			end
		end)
	end)
	EnemyAI.Run(enemy, runtimeState.Core, runtimeState.GameConfig, true)
	return true, "Spawned " .. enemyType .. " in front of " .. player.Name
end

function WaveDefense.GetSpawnCatalog()
	if not runtimeState then return {} end
	local catalog = {}
	for enemyType, definition in pairs(runtimeState.EnemyConfig) do
		local count = 0
		for _, enemy in ipairs(runtimeState.EnemyFolder:GetChildren()) do
			if enemy:GetAttribute("EnemyType") == enemyType then count += 1 end
		end
		table.insert(catalog, {
			Id = enemyType, Name = definition.DisplayName, Health = definition.Health,
			Damage = definition.Damage, Speed = definition.Speed, Ability = definition.Ability,
			AttackStyle = definition.AttackStyle or "Melee", LootTier = definition.LootTier or enemyType, Count = count,
		})
	end
	for _, boss in ipairs(runtimeState.WaveConfig.BossArchetypes or {}) do
		table.insert(catalog, {Id = "Boss:" .. boss.Id, Name = boss.DisplayName, Health = runtimeState.EnemyConfig.Boss.Health, Damage = runtimeState.EnemyConfig.Boss.Damage, Count = 0})
	end
	table.sort(catalog, function(left, right) return left.Id < right.Id end)
	return catalog
end

function WaveDefense.ClearPracticeEnemies()
	if not runtimeState then return false, "Wave system is not ready" end
	local removed = 0
	for _, enemy in ipairs(runtimeState.EnemyFolder:GetChildren()) do
		if enemy:GetAttribute("IsPractice") or enemy:GetAttribute("IsAdminSpawn") then
			enemy:Destroy()
			removed += 1
		end
	end
	return true, string.format("Removed %d practice enemy(s)", removed)
end

return WaveDefense
