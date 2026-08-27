local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local shared
local progressionConfig
local abilityRemote
local dashRemote
local dodgeRemote
local movementRemote

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaveDefenseHUD"
screenGui.ResetOnSpawn = false
screenGui.Enabled = true
screenGui.DisplayOrder = 100
screenGui.IgnoreGuiInset = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.fromOffset(300, 118)
status.Position = UDim2.fromOffset(18, 8)
status.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
status.BackgroundTransparency = 0.15
status.TextColor3 = Color3.fromRGB(235, 245, 255)
status.Font = Enum.Font.GothamBold
status.TextSize = 14
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Text = "CONNECTING TO EVOLUTION ASCENDANT..."
status.Parent = screenGui
local statusPadding = Instance.new("UIPadding")
statusPadding.PaddingTop, statusPadding.PaddingLeft, statusPadding.PaddingRight = UDim.new(0, 8), UDim.new(0, 10), UDim.new(0, 8)
statusPadding.Parent = status
local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 10)
statusCorner.Parent = status

local abilities = Instance.new("Frame")
abilities.Name = "Abilities"
abilities.Size = UDim2.new(1, -24, 0, 78)
abilities.AnchorPoint = Vector2.new(0.5, 1)
abilities.Position = UDim2.new(0.5, 0, 1, -14)
abilities.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
abilities.BackgroundTransparency = 0.15
abilities.Parent = screenGui
local abilitiesConstraint = Instance.new("UISizeConstraint")
abilitiesConstraint.MinSize, abilitiesConstraint.MaxSize, abilitiesConstraint.Parent = Vector2.new(320, 78), Vector2.new(820, 78), abilities
local abilitiesCorner = Instance.new("UICorner")
abilitiesCorner.CornerRadius = UDim.new(0, 10)
abilitiesCorner.Parent = abilities

local bars = Instance.new("Frame")
bars.Name = "PlayerBars"
bars.Size = UDim2.fromOffset(300, 104)
bars.Position = UDim2.fromOffset(18, 132)
bars.BackgroundTransparency = 1
bars.Parent = screenGui

local function updateHudPlacement()
	local camera = workspace.CurrentCamera
	local compact = camera and camera.ViewportSize.X < 960
	status.Position = UDim2.fromOffset(18, compact and 64 or 8)
	bars.Position = UDim2.fromOffset(18, compact and 188 or 132)
end
updateHudPlacement()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateHudPlacement) end

local function makeBar(name, y, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(45, 20)
	label.Position = UDim2.fromOffset(0, y)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.Parent = bars
	local back = Instance.new("Frame")
	back.Name = name .. "Bar"
	back.Size = UDim2.fromOffset(250, 16)
	back.Position = UDim2.fromOffset(48, y + 2)
	back.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
	back.BorderSizePixel = 0
	back.Parent = bars
	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 6)
	backCorner.Parent = back
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = back
	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Size = UDim2.fromScale(1, 1)
	value.BackgroundTransparency = 1
	value.TextColor3 = Color3.new(1, 1, 1)
	value.Font = Enum.Font.GothamBold
	value.TextSize = 12
	value.Parent = back
	return back, fill, value
end

local _, healthFill, healthValue = makeBar("HP", 0, Color3.fromRGB(240, 70, 85))
local _, mpFill, mpValue = makeBar("MP", 24, Color3.fromRGB(65, 145, 255))
local _, staminaFill, staminaValue = makeBar("STA", 48, Color3.fromRGB(90, 230, 155))
local _, xpFill, xpValue = makeBar("XP", 72, Color3.fromRGB(185, 105, 255))

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(64, 66)
grid.CellPadding = UDim2.fromOffset(4, 4)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.VerticalAlignment = Enum.VerticalAlignment.Center
grid.Parent = abilities

local abilityList = {
	{"EnergyBolt", "1", "+", Color3.fromRGB(80, 220, 255)},
	{"EnergyBurst", "2", "*", Color3.fromRGB(120, 245, 255)},
	{"EnergyBeam", "Z", "=", Color3.fromRGB(95, 245, 255)},
	{"GravityPulse", "X", "O", Color3.fromRGB(185, 95, 255)},
	{"ChainLightning", "C", "~", Color3.fromRGB(255, 235, 90)},
	{"Tornado", "V", "@", Color3.fromRGB(170, 210, 255)},
	{"FireBolt", "", "F", Color3.fromRGB(255, 95, 40)}, {"FlameWave", "", "W", Color3.fromRGB(255, 130, 45)}, {"Meteor", "", "M", Color3.fromRGB(255, 180, 55)},
	{"IceShard", "", "I", Color3.fromRGB(105, 225, 255)}, {"FrostNova", "", "N", Color3.fromRGB(185, 245, 255)}, {"Blizzard", "", "B", Color3.fromRGB(125, 190, 255)},
	{"LightningBolt", "", "L", Color3.fromRGB(255, 240, 80)}, {"Thunderstorm", "", "S", Color3.fromRGB(175, 205, 255)},
	{"RockShot", "", "R", Color3.fromRGB(175, 125, 70)}, {"GroundSlam", "", "G", Color3.fromRGB(125, 210, 105)}, {"Boulder", "", "O", Color3.fromRGB(145, 105, 65)},
	{"GravityPull", "", "P", Color3.fromRGB(190, 100, 255)}, {"GravityWell", "", "W", Color3.fromRGB(145, 65, 230)}, {"BlackHole", "", "H", Color3.fromRGB(95, 35, 150)},
	{"PowerDash", "Q", ">", Color3.fromRGB(100, 180, 255)},
	{"SuperJump", "Q", "^", Color3.fromRGB(105, 235, 170)},
	{"Flight", "Q", "F", Color3.fromRGB(125, 205, 255)},
	{"Dodge", "SHIFT", "↝", Color3.fromRGB(190, 235, 255)},
	{"PhaseGuard", "SHIFT", "O", Color3.fromRGB(195, 130, 255)},
}
local gamepadHints = setmetatable({PowerDash = "B", SuperJump = "B", Flight = "B", Dodge = "LS", PhaseGuard = "LS"}, {__index = function() return "RT/LT" end})

local cooldownLabels = {}
local cooldownEnds = {}
local targetPosition
local selectedAbilityIndex = 1
local feedbackMessage = ""
local feedbackExpires = 0
local function attributeList(name)
	local values = {}
	for _, value in ipairs(string.split(player:GetAttribute(name) or "", ",")) do if value ~= "" then table.insert(values, value) end end
	return values
end

local function isMotionPower(name)
	return progressionConfig and progressionConfig.MotionPowers and progressionConfig.MotionPowers[name] ~= nil
end

local function isGamepadInput(inputType)
	return inputType and string.find(inputType.Name, "Gamepad") ~= nil
end

local function selectAbility(index)
	selectedAbilityIndex = math.clamp(index, 1, #abilityList)
	for abilityIndex, entry in ipairs(abilityList) do
		local button = abilities:FindFirstChild(entry[1])
		if button then
			button.BackgroundColor3 = abilityIndex == selectedAbilityIndex and Color3.fromRGB(70, 90, 120) or Color3.fromRGB(30, 38, 55)
		end
	end
end

local function isAbilityAvailable(entry)
	local name = entry[1]
	if isMotionPower(name) then return false end
	local active = "," .. (player:GetAttribute("ActiveAttacks") or "") .. ","
	local definition = progressionConfig and progressionConfig.Abilities[name]
	local unlocked = definition and (player:GetAttribute("AdminAllPowersUnlocked")
		or ((player:GetAttribute("Level") or 1) >= (definition.RequiredLevel or 1)
			and (player:GetAttribute("Evolution") or 0) >= (definition.RequiredEvolution or 0)))
	return unlocked and (active == ",," or string.find(active, "," .. name .. ",", 1, true) ~= nil)
end

local function cycleAbility(direction)
	local available = {}
	for _, activeName in ipairs(attributeList("ActiveAttacks")) do
		for index, entry in ipairs(abilityList) do
			if entry[1] == activeName and isAbilityAvailable(entry) then
				table.insert(available, index)
				break
			end
		end
	end
	if #available == 0 then return end
	local position = table.find(available, selectedAbilityIndex) or (direction > 0 and 0 or 1)
	selectAbility(available[(position - 1 + direction) % #available + 1])
end

local function castAbility(name, mode)
	if name == "PowerDash" then
		if (cooldownEnds[name] or 0) <= os.clock() then
			dashRemote:FireServer()
		end
		return
	elseif name == "Dodge" then
		if (cooldownEnds[name] or 0) <= os.clock() then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if humanoid and root then
				local direction = humanoid.MoveDirection.Magnitude > 0 and humanoid.MoveDirection or -root.CFrame.LookVector
				dodgeRemote:FireServer(direction)
			end
		end
		return
	elseif isMotionPower(name) then
		if (cooldownEnds[name] or 0) <= os.clock() then movementRemote:FireServer(name) end
		return
	end
	local definition = progressionConfig.Abilities[name]
	local target
	if mode == "Close" then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		target = root and root.Position
	else
		target = targetPosition(definition and definition.Range)
	end
	if target and definition and (cooldownEnds[name] or 0) <= os.clock() then
		abilityRemote:FireServer(name, target, mode or "Ranged")
	end
end

for abilityIndex, entry in ipairs(abilityList) do
	local button = Instance.new("TextButton")
	button.Name = entry[1]
	button.LayoutOrder = abilityIndex
	button:SetAttribute("AbilityIndex", abilityIndex)
	button.BackgroundColor3 = Color3.fromRGB(30, 38, 55)
	button.TextColor3 = entry[4]
	button.Font = Enum.Font.GothamBold
	button.Text = ""
	button.AutoButtonColor = true
	button.Parent = abilities
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button
	local icon = Instance.new("TextLabel")
	icon.Name = "SpellIcon"
	icon.Size = UDim2.fromOffset(38, 38)
	icon.Position = UDim2.fromOffset(17, 3)
	icon.BackgroundColor3 = entry[4]
	icon.BackgroundTransparency = 0.18
	icon.Text = entry[3]
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.TextStrokeTransparency = 0
	icon.TextStrokeColor3 = Color3.fromRGB(20, 20, 30)
	icon.Font = Enum.Font.GothamBlack
	icon.TextSize = 25
	icon.Parent = button
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Color3.new(1, 1, 1)
	iconStroke.Thickness = 2
	iconStroke.Parent = icon
	local shine = Instance.new("Frame")
	shine.Size = UDim2.fromOffset(9, 9)
	shine.Position = UDim2.fromOffset(5, 5)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.25
	shine.BorderSizePixel = 0
	shine.Parent = icon
	local key = Instance.new("TextLabel")
	key.Name = "KeyHint"
	key.Size = UDim2.fromOffset(20, 18)
	key.Position = UDim2.fromOffset(2, 1)
	key.BackgroundTransparency = 1
	key.Text = entry[2]
	key:SetAttribute("KeyboardHint", entry[2])
	key:SetAttribute("GamepadHint", gamepadHints[entry[1]])
	key.TextColor3 = Color3.new(1, 1, 1)
	key.Font = Enum.Font.GothamBold
	key.TextSize = 12
	key.Parent = button
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.Position = UDim2.new(0, 0, 1, -18)
	nameLabel.Text = entry[1]
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Parent = button
	local cooldown = Instance.new("TextLabel")
	cooldown.BackgroundTransparency = 1
	cooldown.Size = UDim2.fromScale(1, 1)
	cooldown.TextColor3 = Color3.new(1, 1, 1)
	cooldown.TextScaled = true
	cooldown.Font = Enum.Font.GothamBold
	cooldown.Visible = false
	cooldown.Parent = button
	cooldownLabels[entry[1]] = cooldown
	button.Activated:Connect(function()
		castAbility(entry[1])
	end)
end

local function style(label)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 190, 255)
	stroke.Thickness = 2
	stroke.Parent = label
	end

style(status)
style(abilities)

local remotes = ReplicatedStorage:WaitForChild("Remotes", 12)
	if not remotes then
		status.Text = "SERVER OFFLINE\nRestart Play mode or reconnect Rojo"
		return
	end
local combatRemote = remotes:WaitForChild("CombatRemote")
abilityRemote = remotes:WaitForChild("AbilityRemote")
dashRemote = remotes:WaitForChild("DashRemote")
dodgeRemote = remotes:WaitForChild("DodgeRemote")
movementRemote = remotes:WaitForChild("MovementRemote")
local evolutionRemote = remotes:WaitForChild("EvolutionRemote")
local feedbackRemote = remotes:WaitForChild("CombatFeedback")

targetPosition = function(maximumRange)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local range = math.max(1, tonumber(maximumRange) or 80)
	if isGamepadInput(UserInputService:GetLastInputType()) then
		local camera = workspace.CurrentCamera
		if camera then
			local viewport = camera.ViewportSize
			local ray = camera:ViewportPointToRay(viewport.X / 2, viewport.Y / 2)
			local parameters = RaycastParams.new()
			parameters.FilterType = Enum.RaycastFilterType.Exclude
			parameters.FilterDescendantsInstances = {character}
			local result = workspace:Raycast(ray.Origin, ray.Direction * range, parameters)
			return result and result.Position or root.Position + root.CFrame.LookVector * math.min(range, 60)
		end
	end
	local target = mouse.Hit.Position
	if (target - root.Position).Magnitude > range then
		return root.Position + (target - root.Position).Unit * range
	end
	return target
end

shared = ReplicatedStorage:WaitForChild("Shared")
progressionConfig = require(shared:WaitForChild("ProgressionConfig"))

feedbackRemote.OnClientEvent:Connect(function(kind, xp, coins, duration)
	if kind == "CastRejected" then
		feedbackMessage = "CAST BLOCKED: " .. tostring(xp)
		feedbackExpires = os.clock() + 2
		return
	elseif kind == "CastAccepted" then
		feedbackMessage = "CAST: " .. tostring(xp)
		feedbackExpires = os.clock() + 1
		if xp ~= "Melee" and progressionConfig.Abilities[xp] then
			cooldownEnds[xp] = os.clock() + (duration or progressionConfig.Abilities[xp].Cooldown)
		elseif xp == "PowerDash" then
			cooldownEnds[xp] = os.clock() + (duration or coins or 1.25)
		elseif xp == "Dodge" or (progressionConfig.MotionPowers and progressionConfig.MotionPowers[xp]) then
			cooldownEnds[xp] = os.clock() + (duration or coins or 1)
		end
		return
	end
	if kind ~= "Reward" then
		return
	end
	local reward = Instance.new("TextLabel")
	reward.Size = UDim2.fromOffset(260, 36)
	reward.Position = UDim2.new(0.5, -130, 0.35, 0)
	reward.BackgroundTransparency = 1
	reward.TextColor3 = Color3.fromRGB(255, 230, 100)
	reward.Font = Enum.Font.GothamBold
	reward.TextScaled = true
	reward.Text = string.format("+%d XP   +%d COINS", xp, coins)
	reward.Parent = screenGui
	TweenService:Create(reward, TweenInfo.new(1.2), {Position = reward.Position - UDim2.fromOffset(0, 45), TextTransparency = 1}):Play()
	task.delay(1.3, function()
		if reward.Parent then
			reward:Destroy()
		end
	end)
end)

local function refreshStatus()
	local wave = workspace:GetAttribute("Wave") or 0
	local remaining = workspace:GetAttribute("EnemiesRemaining") or 0
	local state = workspace:GetAttribute("WaveState") or "Starting"
	local core = workspace:FindFirstChild("DefenseCore")
	local coreHealth = core and core:GetAttribute("Health") or 0
	local coreMax = core and core:GetAttribute("MaxHealth") or 0
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local health = humanoid and humanoid.Health or 0
	local maxHealth = humanoid and humanoid.MaxHealth or 100
	local xp = player:GetAttribute("XP") or 0
	local xpRequired = player:GetAttribute("XPRequired") or 100
	local mp = player:GetAttribute("MP") or 0
	local maxMP = player:GetAttribute("MaxMP") or 100
	local stamina = player:GetAttribute("Stamina") or 0
	local maxStamina = player:GetAttribute("MaxStamina") or 100
	local worldError = workspace:GetAttribute("WorldError") or ""
	local countdown = workspace:GetAttribute("WaveCountdown") or 0
	local waveInfo = countdown > 0 and string.format("NEXT WAVE IN %d", countdown) or state
	healthFill.Size = UDim2.fromScale(math.clamp(health / math.max(maxHealth, 1), 0, 1), 1)
	mpFill.Size = UDim2.fromScale(math.clamp(mp / math.max(maxMP, 1), 0, 1), 1)
	staminaFill.Size = UDim2.fromScale(math.clamp(stamina / math.max(maxStamina, 1), 0, 1), 1)
	xpFill.Size = UDim2.fromScale(math.clamp(xp / math.max(xpRequired, 1), 0, 1), 1)
	healthValue.Text = string.format("%d / %d", health, maxHealth)
	mpValue.Text = string.format("%d / %d", math.floor(mp), math.floor(maxMP))
	staminaValue.Text = string.format("%d / %d", math.floor(stamina), math.floor(maxStamina))
	xpValue.Text = string.format("%d / %d", math.floor(xp), math.floor(xpRequired))
	status.Text = string.format("EVOLUTION ASCENDANT  |  v%s  |  %s\nCOMBAT: %s\nWAVE %d  |  %s\nEnemies: %d\nCore: %d / %d\nLevel %d  |  Gold %d  |  Evo %d\nSELECTED: %s%s%s%s%s", workspace:GetAttribute("WorldVersion") or "DEV", workspace:GetAttribute("WorldStatus") or "Starting", workspace:GetAttribute("CombatStatus") or "Offline", wave, waveInfo, remaining, coreHealth, coreMax, player:GetAttribute("Level") or 1, player:GetAttribute("Coins") or 0, player:GetAttribute("Evolution") or 0, abilityList[selectedAbilityIndex][1], player:GetAttribute("CanEvolve") and "\nEVOLUTION READY  [R]" or "", player:GetAttribute("Blocking") and "\nBLOCKING  [F]" or "", worldError ~= "" and "\nERROR: " .. worldError or "", os.clock() < feedbackExpires and "\n" .. feedbackMessage or "")
	status.TextColor3 = player:GetAttribute("CanEvolve") and Color3.fromRGB(255, 220, 100) or Color3.fromRGB(235, 245, 255)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		combatRemote:FireServer("Melee")
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		local target = targetPosition(120)
		if target then combatRemote:FireServer("Ranged", target) end
	elseif input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.Three
		or input.KeyCode == Enum.KeyCode.Four or input.KeyCode == Enum.KeyCode.Five or input.KeyCode == Enum.KeyCode.Six then
		local keySlots = {[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6}
		local active = attributeList("ActiveAttacks")
		if active[keySlots[input.KeyCode]] then castAbility(active[keySlots[input.KeyCode]]) end
	elseif input.KeyCode == Enum.KeyCode.Q then
		local motion = attributeList("ActiveMotion")
		if motion[1] then castAbility(motion[1]) end
	elseif input.KeyCode == Enum.KeyCode.R then
		evolutionRemote:FireServer()
	end
end)

selectAbility(selectedAbilityIndex)

task.spawn(function()
	while screenGui.Parent do
		refreshStatus()
		for name, cooldown in pairs(cooldownLabels) do
			local remaining = math.max(0, (cooldownEnds[name] or 0) - os.clock())
			cooldown.Visible = remaining > 0
			cooldown.Text = remaining > 0 and string.format("%.1f", remaining) or ""
		end
		for _, entry in ipairs(abilityList) do
			local definition = progressionConfig.Abilities[entry[1]]
			local button = abilities:FindFirstChild(entry[1])
			local nameLabel = button and button:FindFirstChild("NameLabel")
			if definition and button and nameLabel then
				local unlocked = player:GetAttribute("AdminAllPowersUnlocked") or ((player:GetAttribute("Level") or 1) >= (definition.RequiredLevel or 1) and (player:GetAttribute("Evolution") or 0) >= (definition.RequiredEvolution or 0))
				local mastery = player:FindFirstChild("PowerMastery")
				local value = mastery and mastery:FindFirstChild(entry[1])
				nameLabel.Text = string.format("%s M%d", definition.DisplayName, value and (value:GetAttribute("Level") or 0) or 0)
				button.BackgroundTransparency = unlocked and 0 or 0.55
				button.Visible = isAbilityAvailable(entry)
			elseif button then
				local motion = attributeList("ActiveMotion")
				local motionSlot = table.find(motion, entry[1])
				button.Visible = motionSlot ~= nil
				if motionSlot then
					button.LayoutOrder = 6 + motionSlot
					local keyHint = button:FindFirstChild("KeyHint")
					if keyHint then
						keyHint:SetAttribute("KeyboardHint", motionSlot == 1 and "Q" or "SHIFT")
						keyHint.Text = motionSlot == 1 and "Q" or "SHIFT"
					end
				end
			end
		end
		local attacks = attributeList("ActiveAttacks")
		for slot, name in ipairs(attacks) do
			local button = abilities:FindFirstChild(name)
			if button then
				button.LayoutOrder = slot
				local keyHint = button:FindFirstChild("KeyHint")
				if keyHint then keyHint:SetAttribute("KeyboardHint", tostring(slot)); keyHint.Text = tostring(slot) end
			end
		end
		if not isAbilityAvailable(abilityList[selectedAbilityIndex]) then cycleAbility(1) end
		task.wait(0.25)
	end
end)

local function resizeHotbar()
	grid.CellSize = abilities.AbsoluteSize.X < 500 and UDim2.fromOffset(46, 60) or UDim2.fromOffset(64, 66)
end
abilities:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeHotbar)
resizeHotbar()

local function handleAction(actionName, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	for _, guiName in ipairs({"InventoryUI", "QuestLog", "AdminControls", "CombatSettings", "PowersUI", "EvolutionUI", "AscensionUI"}) do
		local gui = playerGui and playerGui:FindFirstChild(guiName)
		if gui then
			for _, child in ipairs(gui:GetChildren()) do
				if child:IsA("GuiObject") and string.find(child.Name, "Panel", 1, true) and child.Visible then
					return Enum.ContextActionResult.Pass
				end
			end
		end
	end
	if actionName == "CyclePowerNext" then
		cycleAbility(1)
	elseif actionName == "CyclePowerPrevious" then
		cycleAbility(-1)
	elseif actionName == "CastPower" then
		castAbility(abilityList[selectedAbilityIndex][1], "Ranged")
	elseif actionName == "CastClosePower" then
		castAbility(abilityList[selectedAbilityIndex][1], "Close")
	elseif actionName == "MeleeAttack" then
		combatRemote:FireServer("Melee")
	elseif actionName == "RangedWeapon" then
		local target = targetPosition(120)
		if target then combatRemote:FireServer("Ranged", target) end
	elseif actionName == "PowerDash" then
		local motion = attributeList("ActiveMotion")
		if motion[1] then castAbility(motion[1]) end
	elseif actionName == "Evolve" then
		evolutionRemote:FireServer()
	elseif actionName == "Dodge" then
		local motion = attributeList("ActiveMotion")
		if motion[2] then castAbility(motion[2]) end
	else
		return Enum.ContextActionResult.Pass
	end
	return Enum.ContextActionResult.Sink
end

local function updateInputHints(inputType)
	local usingGamepad = isGamepadInput(inputType)
	for _, entry in ipairs(abilityList) do
		local button = abilities:FindFirstChild(entry[1])
		local keyLabel = button and button:FindFirstChild("KeyHint")
		if keyLabel then keyLabel.Text = usingGamepad and keyLabel:GetAttribute("GamepadHint") or keyLabel:GetAttribute("KeyboardHint") end
	end
end

UserInputService.LastInputTypeChanged:Connect(updateInputHints)
updateInputHints(UserInputService:GetLastInputType())

local function handleBlock(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		combatRemote:FireServer("Block", true)
		return Enum.ContextActionResult.Sink
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		combatRemote:FireServer("Block", false)
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local combatPriority = 3500
ContextActionService:BindActionAtPriority("CyclePowerNext", handleAction, false, combatPriority, Enum.KeyCode.ButtonR1, Enum.KeyCode.RightBracket)
ContextActionService:BindActionAtPriority("CyclePowerPrevious", handleAction, false, combatPriority, Enum.KeyCode.ButtonL1, Enum.KeyCode.LeftBracket)
ContextActionService:BindActionAtPriority("CastPower", handleAction, false, combatPriority, Enum.KeyCode.ButtonR2, Enum.KeyCode.Return)
ContextActionService:BindActionAtPriority("CastClosePower", handleAction, false, combatPriority, Enum.KeyCode.ButtonL2)
ContextActionService:BindActionAtPriority("MeleeAttack", handleAction, true, combatPriority, Enum.KeyCode.ButtonX)
ContextActionService:BindActionAtPriority("RangedWeapon", handleAction, true, combatPriority, Enum.KeyCode.ButtonA)
ContextActionService:SetTitle("RangedWeapon", "FIRE")
ContextActionService:SetPosition("RangedWeapon", UDim2.new(1, -70, 1, -170))
ContextActionService:SetTitle("MeleeAttack", "ATTACK")
ContextActionService:SetPosition("MeleeAttack", UDim2.new(1, -70, 1, -110))
ContextActionService:BindAction("PowerDash", handleAction, true, Enum.KeyCode.ButtonB)
ContextActionService:SetTitle("PowerDash", "DASH")
ContextActionService:SetPosition("PowerDash", UDim2.new(1, -150, 1, -170))
ContextActionService:BindAction("Evolve", handleAction, true, Enum.KeyCode.ButtonY)
ContextActionService:SetTitle("Evolve", "EVOLVE")
ContextActionService:SetPosition("Evolve", UDim2.new(1, -230, 1, -170))
ContextActionService:BindAction("Dodge", handleAction, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
ContextActionService:SetTitle("Dodge", "DODGE")
ContextActionService:SetPosition("Dodge", UDim2.new(1, -150, 1, -100))
ContextActionService:BindAction("Block", handleBlock, true, Enum.KeyCode.F)
ContextActionService:SetTitle("Block", "BLOCK")
ContextActionService:SetPosition("Block", UDim2.new(1, -230, 1, -100))
