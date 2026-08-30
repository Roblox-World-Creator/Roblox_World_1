local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetModelService = require(script.Parent.AssetModelService)

local WeaponService = {}
local itemConfig
local rebuildTokens = {}

local RARITY_COLORS = {
	Common = Color3.fromRGB(185, 205, 225), Uncommon = Color3.fromRGB(95, 225, 135),
	Rare = Color3.fromRGB(75, 155, 255), Epic = Color3.fromRGB(185, 95, 255),
	Legendary = Color3.fromRGB(255, 180, 55),
	Mythic = Color3.fromRGB(255, 75, 180),
}

local function visualPart(parent, name, size, color, material)
	local part = Instance.new("Part")
	part.Name, part.Size, part.Color = name, size, color
	part.Material = material or Enum.Material.Metal
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.CastShadow, part.Massless, part.Parent = false, true, parent
	return part
end

local function attach(part, bodyPart, offset, name)
	part.CFrame = bodyPart.CFrame * offset
	local motor = Instance.new("Motor6D")
	-- Keep the joint inside the visual model so a rebuild removes both the part and its joint.
	motor.Name, motor.Part0, motor.Part1, motor.C0, motor.Parent = name or "EquipmentGrip", bodyPart, part, offset, part
	return motor
end

local function attachAtGrip(part, bodyPart, offset, name, importedToolGrip)
	local handAttachment = bodyPart:FindFirstChild("RightGripAttachment") or bodyPart:FindFirstChild("LeftGripAttachment")
	local weaponAttachment = part:FindFirstChild("RightGripAttachment") or part:FindFirstChild("LeftGripAttachment")
	if handAttachment and not weaponAttachment and typeof(importedToolGrip) == "CFrame" then
		part.CFrame = bodyPart.CFrame * handAttachment.CFrame * importedToolGrip:Inverse()
		local motor = Instance.new("Motor6D")
		motor.Name, motor.Part0, motor.Part1 = name or "EquipmentGrip", bodyPart, part
		motor.C0, motor.C1, motor.Parent = handAttachment.CFrame, importedToolGrip, part
		return motor
	end
	if not handAttachment or not weaponAttachment then return attach(part, bodyPart, offset, name) end
	part.CFrame = bodyPart.CFrame * handAttachment.CFrame * weaponAttachment.CFrame:Inverse()
	local motor = Instance.new("Motor6D")
	motor.Name, motor.Part0, motor.Part1 = name or "EquipmentGrip", bodyPart, part
	motor.C0, motor.C1, motor.Parent = handAttachment.CFrame, weaponAttachment.CFrame, part
	return motor
end

local function addGlow(part, definition)
	if definition.Rarity == "Common" then return end
	local light = Instance.new("PointLight")
	light.Color, light.Range = part.Color, definition.Rarity == "Legendary" and 14 or 8
	light.Brightness, light.Parent = definition.Rarity == "Legendary" and 2.2 or 1.2, part
end

local function createImportedWeapon(container, hand, itemId, definition, secondary, offset)
	local model = AssetModelService.Clone("Weapons", definition.ModelProfile)
	if not model then return false end
	local handle
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local name = string.lower(descendant.Name)
			if name == "handle" or name == "grip" or string.find(name, "weaponhandle", 1, true) then handle = descendant; break end
		end
	end
	if handle then model.PrimaryPart = handle end
	model.Name = secondary and "SecondaryWeaponVisual" or "PrimaryWeaponVisual"
	model:SetAttribute("ItemId", itemId)
	model:SetAttribute("WeaponKind", definition.WeaponKind or "Melee")
	model.Parent = container
	local desired = definition.WeaponSize or Vector3.new(0.3, 4.2, 0.65)
	local extents = model:GetExtentsSize()
	local longest = math.max(extents.X, extents.Y, extents.Z)
	if longest > 0 then pcall(function() model:ScaleTo(model:GetScale() * math.clamp(desired.Y / longest, 0.15, 6)) end) end
	-- Normalize arbitrary Creator Store model axes: blades point upward; barrels point forward.
	local correction = CFrame.identity
	if secondary then
		if extents.X >= extents.Y and extents.X >= extents.Z then correction = CFrame.Angles(0, math.rad(90), 0)
		elseif extents.Y >= extents.X and extents.Y >= extents.Z then correction = CFrame.Angles(math.rad(90), 0, 0) end
	else
		if extents.X >= extents.Y and extents.X >= extents.Z then correction = CFrame.Angles(0, 0, math.rad(90))
		elseif extents.Z >= extents.X and extents.Z >= extents.Y then correction = CFrame.Angles(math.rad(90), 0, 0) end
	end
	local gripOffset = offset * correction
	AssetModelService.WeldModel(model)
	attachAtGrip(model.PrimaryPart, hand, gripOffset, secondary and "SecondaryGrip" or "SwordGrip", model:GetAttribute("ImportedToolGrip"))
	addGlow(model.PrimaryPart, definition)
	return true
end

local function createWeapon(container, hand, itemId, definition, secondary)
	local size = definition.WeaponSize or Vector3.new(0.3, 4.2, 0.65)
	local offset = secondary
		and CFrame.new(0, -0.2, -0.45) * CFrame.Angles(math.rad(-8), 0, math.rad(-8))
		or CFrame.new(0, -0.12, -0.4) * CFrame.Angles(math.rad(-12), 0, math.rad(-8))
	if definition.ModelProfile and not definition.UseProceduralVisual and createImportedWeapon(container, hand, itemId, definition, secondary, offset) then return end
	local model = Instance.new("Model")
	model.Name, model.Parent = secondary and "SecondaryWeaponVisual" or "PrimaryWeaponVisual", container
	model:SetAttribute("ItemId", itemId)
	model:SetAttribute("WeaponKind", definition.WeaponKind or "Melee")
	local blade = visualPart(model, definition.WeaponKind and "RangedWeapon" or "Blade", size, definition.WeaponColor or RARITY_COLORS[definition.Rarity])
	local fallbackOffset = secondary and offset or CFrame.new(0, size.Y * 0.44, -0.4) * CFrame.Angles(math.rad(-12), 0, math.rad(-8))
	attach(blade, hand, fallbackOffset, secondary and "SecondaryGrip" or "SwordGrip")
	model.PrimaryPart = blade

	local detailColor, detailSize = Color3.fromRGB(45, 58, 82), Vector3.new(1.6, 0.25, 0.35)
	local detailOffset = CFrame.new(0, -size.Y / 2 + 0.15, 0)
	if definition.WeaponKind == "Bow" then
		detailColor, detailSize, detailOffset = Color3.fromRGB(110, 72, 38), Vector3.new(0.16, size.Y * 0.92, math.max(1.6, size.Y * 0.48)), CFrame.identity
	elseif definition.WeaponKind == "Gun" or definition.WeaponKind == "Rifle" then
		detailSize, detailOffset = Vector3.new(0.75, 0.9, math.max(1.2, size.Z * 1.35)), CFrame.new(0, -size.Y * 0.28, size.Z * 0.35)
	end
	local detail = visualPart(model, "WeaponDetail", detailSize, detailColor)
	detail.CFrame = blade.CFrame * detailOffset
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = blade, detail, detail
	if definition.Rarity ~= "Common" then
		local top, bottom = Instance.new("Attachment"), Instance.new("Attachment")
		top.Position, bottom.Position, top.Parent, bottom.Parent = Vector3.new(0, size.Y / 2, 0), Vector3.new(0, -size.Y / 2, 0), blade, blade
		local trail = Instance.new("Trail")
		trail.Attachment0, trail.Attachment1 = top, bottom
		trail.Color, trail.Transparency = ColorSequence.new(blade.Color, Color3.new(1, 1, 1)), NumberSequence.new(0.15, 1)
		trail.Lifetime, trail.LightEmission, trail.Parent = definition.Rarity == "Legendary" and 0.26 or 0.14, 1, blade
		addGlow(blade, definition)
	end
end

local function firstPart(character, ...)
	for _, name in ipairs({...}) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then return part end
	end
end

local function createArmorPiece(container, bodyPart, name, scale, offset, definition)
	if not bodyPart then return end
	local size = Vector3.new(math.max(0.35, bodyPart.Size.X * scale.X), math.max(0.25, bodyPart.Size.Y * scale.Y), math.max(0.2, bodyPart.Size.Z * scale.Z))
	local part = visualPart(container, name, size, RARITY_COLORS[definition.Rarity] or Color3.fromRGB(150, 170, 200))
	part.Transparency = 0.08
	attach(part, bodyPart, offset, name .. "Grip")
	addGlow(part, definition)
end

local function createEquipmentVisual(container, character, slotName, definition)
	local head, torso = firstPart(character, "Head"), firstPart(character, "UpperTorso", "Torso")
	if slotName == "Head" then
		createArmorPiece(container, head, "Helmet", Vector3.new(1.08, 0.72, 1.08), CFrame.new(0, 0.28, 0), definition)
	elseif slotName == "Chest" then
		createArmorPiece(container, torso, "Chestplate", Vector3.new(1.08, 0.82, 1.22), CFrame.new(0, 0, -0.08), definition)
	elseif slotName == "Legs" then
		for _, limb in ipairs({firstPart(character, "LeftUpperLeg", "Left Leg"), firstPart(character, "RightUpperLeg", "Right Leg")}) do
			createArmorPiece(container, limb, "LegGuard", Vector3.new(1.12, 0.72, 1.12), CFrame.new(0, 0.15, 0), definition)
		end
	elseif slotName == "Boots" then
		for _, limb in ipairs({firstPart(character, "LeftFoot", "Left Leg"), firstPart(character, "RightFoot", "Right Leg")}) do
			if limb then createArmorPiece(container, limb, "Boot", Vector3.new(1.16, 0.38, 1.35), CFrame.new(0, -limb.Size.Y * 0.28, -0.12), definition) end
		end
	elseif slotName == "Gloves" then
		for _, limb in ipairs({firstPart(character, "LeftHand", "Left Arm"), firstPart(character, "RightHand", "Right Arm")}) do
			createArmorPiece(container, limb, "Gauntlet", Vector3.new(1.18, 0.72, 1.18), CFrame.identity, definition)
		end
	elseif string.find(slotName, "Artifact", 1, true) == 1 or slotName == "Core" then
		if not torso then return end
		local index = tonumber(string.match(slotName, "%d+")) or 2
		local core = visualPart(container, slotName .. "Visual", Vector3.one * 0.62, RARITY_COLORS[definition.Rarity], Enum.Material.Neon)
		core.Shape = Enum.PartType.Ball
		attach(core, torso, CFrame.new((index - 2) * 1.25, 0.35, 1), slotName .. "Grip")
		addGlow(core, definition)
	elseif slotName == "Cape" and torso then
		local cape = visualPart(container, "Cape", Vector3.new(torso.Size.X * 0.92, torso.Size.Y * 1.35, 0.12), RARITY_COLORS[definition.Rarity], Enum.Material.Fabric)
		attach(cape, torso, CFrame.new(0, -torso.Size.Y * 0.35, torso.Size.Z * 0.58) * CFrame.Angles(math.rad(8), 0, 0), "CapeGrip")
	end
end

local function rebuild(player, character)
	if not character or character ~= player.Character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	local old = character:FindFirstChild("EquippedItemVisuals")
	if old then old:Destroy() end
	local container = Instance.new("Model")
	container.Name, container.Parent = "EquippedItemVisuals", character
	local equipment = player:FindFirstChild("Equipment")
	if not equipment then return end
	local primary, secondary = equipment:FindFirstChild("Weapon"), equipment:FindFirstChild("SecondaryWeapon")
	local primaryDefinition = primary and itemConfig.Items[primary.Value]
	local secondaryDefinition = secondary and itemConfig.Items[secondary.Value]
	local rightName = humanoid.RigType == Enum.HumanoidRigType.R15 and "RightHand" or "Right Arm"
	local leftName = humanoid.RigType == Enum.HumanoidRigType.R15 and "LeftHand" or "Left Arm"
	local rightHand = character:FindFirstChild(rightName) or character:WaitForChild(rightName, 5)
	local leftHand = character:FindFirstChild(leftName) or character:WaitForChild(leftName, 5)
	if primaryDefinition and rightHand then createWeapon(container, rightHand, primary.Value, primaryDefinition, false) end
	if secondaryDefinition and leftHand then createWeapon(container, leftHand, secondary.Value, secondaryDefinition, true) end
	player:SetAttribute("EquippedWeaponKind", secondaryDefinition and (secondaryDefinition.WeaponKind or "Ranged") or "Melee")
	for _, slot in ipairs(equipment:GetChildren()) do
		local definition = slot:IsA("StringValue") and itemConfig.Items[slot.Value]
		if definition and slot.Name ~= "Weapon" and slot.Name ~= "SecondaryWeapon" then createEquipmentVisual(container, character, slot.Name, definition) end
	end
end

local function queueRebuild(player)
	rebuildTokens[player] = (rebuildTokens[player] or 0) + 1
	local token = rebuildTokens[player]
	task.defer(function()
		if player.Parent and token == rebuildTokens[player] then rebuild(player, player.Character) end
	end)
end

function WeaponService.Start(config)
	itemConfig = config
	local importedNames = ReplicatedStorage:FindFirstChild("ImportedStarterItemNames")
	local function isArchivedStarterItem(instance)
		if not instance:IsA("Tool") or not importedNames then return false end
		for _, marker in ipairs(importedNames:GetChildren()) do
			if marker:IsA("StringValue") and marker.Value == instance.Name then return true end
		end
		return false
	end
	local function removeArchivedStarterTools(container)
		if not container then return end
		for _, child in ipairs(container:GetChildren()) do
			if isArchivedStarterItem(child) then child:Destroy() end
		end
		container.ChildAdded:Connect(function(child)
			if isArchivedStarterItem(child) then child:Destroy() end
		end)
	end
	local function setup(player)
		local connectedSlots = {}
		local function connectEquipment(equipment)
			local function connectSlot(slot)
				if slot:IsA("StringValue") and not connectedSlots[slot] then
					connectedSlots[slot] = true
					slot.Changed:Connect(function() queueRebuild(player) end)
				end
			end
			for _, slot in ipairs(equipment:GetChildren()) do connectSlot(slot) end
			equipment.ChildAdded:Connect(function(slot) connectSlot(slot); queueRebuild(player) end)
			queueRebuild(player)
		end
		player.CharacterAdded:Connect(function(character)
			removeArchivedStarterTools(character)
			task.defer(rebuild, player, character)
		end)
		removeArchivedStarterTools(player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 5))
		local equipment = player:FindFirstChild("Equipment")
		if equipment then connectEquipment(equipment) end
		player.ChildAdded:Connect(function(child) if child.Name == "Equipment" and child:IsA("Folder") then connectEquipment(child) end end)
		if player.Character then removeArchivedStarterTools(player.Character); queueRebuild(player) end
	end
	Players.PlayerAdded:Connect(setup)
	for _, player in ipairs(Players:GetPlayers()) do setup(player) end
	Players.PlayerRemoving:Connect(function(player) rebuildTokens[player] = nil end)
end

return WeaponService
