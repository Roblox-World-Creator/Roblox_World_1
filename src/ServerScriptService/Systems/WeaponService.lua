local Players = game:GetService("Players")

local WeaponService = {}

local itemConfig

local function equipWeapon(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then
		return
	end
	local handName = humanoid.RigType == Enum.HumanoidRigType.R15 and "RightHand" or "Right Arm"
	local hand = character:WaitForChild(handName, 5)
	if not hand then
		return
	end
	local oldWeapon = character:FindFirstChild("EquippedWeaponVisual")
	if oldWeapon then oldWeapon:Destroy() end
	local equipment = player:FindFirstChild("Equipment")
	local secondary = equipment and equipment:FindFirstChild("SecondaryWeapon")
	local secondaryDefinition = secondary and itemConfig.Items[secondary.Value]
	local itemId = secondaryDefinition and secondary.Value or player:GetAttribute("EquippedWeapon") or "IronBlade"
	local definition = itemConfig.Items[itemId] or itemConfig.Items.IronBlade
	player:SetAttribute("EquippedWeaponKind", definition.WeaponKind or "Melee")
	local sword = Instance.new("Model")
	sword.Name = "EquippedWeaponVisual"
	sword:SetAttribute("ItemId", itemId)
	sword:SetAttribute("WeaponKind", definition.WeaponKind or "Melee")
	local blade = Instance.new("Part")
	blade.Name = definition.WeaponKind and "RangedWeapon" or "Blade"
	blade.Size = definition.WeaponSize or Vector3.new(0.3, 4.2, 0.65)
	blade.Material = Enum.Material.Metal
	blade.Color = definition.WeaponColor or Color3.fromRGB(185, 205, 225)
	blade.CanCollide = false
	blade.Massless = true
	blade.Parent = sword
	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(1.6, 0.25, 0.35)
	guard.Material = Enum.Material.Metal
	guard.Color = Color3.fromRGB(55, 75, 105)
	guard.CanCollide = false
	guard.Massless = true
	guard.CFrame = blade.CFrame * CFrame.new(0, -2, 0)
	guard.Parent = sword
	if definition.WeaponKind == "Bow" then
		guard.Size = Vector3.new(0.2, 3.8, 0.2)
		guard.Color = Color3.fromRGB(100, 65, 35)
	elseif definition.WeaponKind == "Gun" or definition.WeaponKind == "Rifle" then
		guard.Size = Vector3.new(0.7, 0.8, 1.4)
		guard.Color = Color3.fromRGB(35, 42, 58)
	end
	local bladeWeld = Instance.new("WeldConstraint")
	bladeWeld.Part0 = blade
	bladeWeld.Part1 = guard
	bladeWeld.Parent = guard
	blade.CFrame = hand.CFrame * CFrame.new(0, -1.4, -0.25) * CFrame.Angles(0, 0, math.rad(10))
	local swordGrip = Instance.new("Motor6D")
	swordGrip.Name = "SwordGrip"
	swordGrip.Part0 = hand
	swordGrip.Part1 = blade
	swordGrip.C0 = hand.CFrame:ToObjectSpace(blade.CFrame)
	swordGrip.Parent = hand
	sword.PrimaryPart = blade
	sword.Parent = character
	if definition.Rarity ~= "Common" then
		local top = Instance.new("Attachment")
		top.Position = Vector3.new(0, blade.Size.Y / 2, 0)
		top.Parent = blade
		local bottom = Instance.new("Attachment")
		bottom.Position = Vector3.new(0, -blade.Size.Y / 2, 0)
		bottom.Parent = blade
		local trail = Instance.new("Trail")
		trail.Attachment0, trail.Attachment1 = top, bottom
		trail.Color = ColorSequence.new(blade.Color, Color3.new(1, 1, 1))
		trail.Lifetime = definition.Rarity == "Legendary" and 0.28 or 0.16
		trail.LightEmission = 1
		trail.Parent = blade
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness = blade.Color, definition.Rarity == "Legendary" and 18 or 10, 2
		light.Parent = blade
	end
end

function WeaponService.Start(config)
	itemConfig = config
	local function setup(player)
		player.CharacterAdded:Connect(function(character)
			task.defer(equipWeapon, player, character)
		end)
		player:GetAttributeChangedSignal("EquippedWeapon"):Connect(function()
			if player.Character then task.defer(equipWeapon, player, player.Character) end
		end)
		local equipment = player:FindFirstChild("Equipment")
		local secondary = equipment and equipment:FindFirstChild("SecondaryWeapon")
		if secondary then secondary.Changed:Connect(function() if player.Character then task.defer(equipWeapon, player, player.Character) end end) end
		if player.Character then
			task.defer(equipWeapon, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(setup)
	for _, player in ipairs(Players:GetPlayers()) do
		setup(player)
	end
end

return WeaponService
