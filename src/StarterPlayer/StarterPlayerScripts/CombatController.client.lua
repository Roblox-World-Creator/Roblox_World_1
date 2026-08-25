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

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaveDefenseHUD"
screenGui.ResetOnSpawn = false
screenGui.Enabled = true
screenGui.DisplayOrder = 100
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.fromOffset(360, 118)
status.Position = UDim2.fromOffset(18, 18)
status.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
status.BackgroundTransparency = 0.15
status.TextColor3 = Color3.fromRGB(235, 245, 255)
status.Font = Enum.Font.GothamBold
status.TextSize = 18
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Text = "CONNECTING TO WORLD...\nv0.4.4"
status.Parent = screenGui
local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 10)
statusCorner.Parent = status

local abilities = Instance.new("Frame")
abilities.Name = "Abilities"
abilities.Size = UDim2.new(0.96, 0, 0, 78)
abilities.AnchorPoint = Vector2.new(0.5, 1)
abilities.Position = UDim2.new(0.5, 0, 1, -14)
abilities.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
abilities.BackgroundTransparency = 0.15
abilities.Parent = screenGui
local abilitiesCorner = Instance.new("UICorner")
abilitiesCorner.CornerRadius = UDim.new(0, 10)
abilitiesCorner.Parent = abilities

local bars = Instance.new("Frame")
bars.Name = "PlayerBars"
bars.Size = UDim2.fromOffset(360, 58)
bars.Position = UDim2.fromOffset(18, 145)
bars.BackgroundTransparency = 1
bars.Parent = screenGui

local function makeBar(name, y, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(55, 22)
	label.Position = UDim2.fromOffset(0, y)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Parent = bars
	local back = Instance.new("Frame")
	back.Name = name .. "Bar"
	back.Size = UDim2.fromOffset(300, 18)
	back.Position = UDim2.fromOffset(58, y + 2)
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
	value.TextSize = 13
	value.Parent = back
	return back, fill, value
end

local _, healthFill, healthValue = makeBar("HP", 0, Color3.fromRGB(240, 70, 85))
local _, xpFill, xpValue = makeBar("XP", 28, Color3.fromRGB(90, 220, 255))

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(72, 66)
grid.CellPadding = UDim2.fromOffset(4, 4)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.VerticalAlignment = Enum.VerticalAlignment.Center
grid.Parent = abilities

local abilityList = {
	{"EnergyBlast", "1", "+", Color3.fromRGB(80, 220, 255)},
	{"FlameBurst", "2", "F", Color3.fromRGB(255, 100, 35)},
	{"ThunderStrike", "3", "*", Color3.fromRGB(230, 245, 80)},
	{"WindCutter", "4", "~", Color3.fromRGB(120, 255, 190)},
	{"MeteorCrash", "5", "M", Color3.fromRGB(255, 70, 30)},
	{"EnergyBeam", "6", "|", Color3.fromRGB(100, 160, 255)},
	{"VoidExplosion", "7", "O", Color3.fromRGB(180, 80, 255)},
	{"UltimateNova", "8", "X", Color3.fromRGB(255, 220, 100)},
}

local cooldownLabels = {}
local cooldownEnds = {}
local targetPosition
local selectedAbilityIndex = 1
local feedbackMessage = ""
local feedbackExpires = 0

local function selectAbility(index)
	selectedAbilityIndex = ((index - 1) % #abilityList) + 1
	for abilityIndex, entry in ipairs(abilityList) do
		local button = abilities:FindFirstChild(entry[1])
		if button then
			button.BackgroundColor3 = abilityIndex == selectedAbilityIndex and Color3.fromRGB(70, 90, 120) or Color3.fromRGB(30, 38, 55)
		end
	end
end

local function castAbility(name)
	local target = targetPosition()
	local definition = progressionConfig.Abilities[name]
	if target and definition and (cooldownEnds[name] or 0) <= os.clock() then
		abilityRemote:FireServer(name, target)
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
	key.Size = UDim2.fromOffset(20, 18)
	key.Position = UDim2.fromOffset(2, 1)
	key.BackgroundTransparency = 1
	key.Text = entry[2]
	key.TextColor3 = Color3.new(1, 1, 1)
	key.Font = Enum.Font.GothamBold
	key.TextSize = 12
	key.Parent = button
	local nameLabel = Instance.new("TextLabel")
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
		status.Text = "SERVER OFFLINE\nRestart Play mode or reconnect Rojo\nv0.4.4"
		return
	end
local combatRemote = remotes:WaitForChild("CombatRemote")
abilityRemote = remotes:WaitForChild("AbilityRemote")
local evolutionRemote = remotes:WaitForChild("EvolutionRemote")
local feedbackRemote = remotes:WaitForChild("CombatFeedback")

targetPosition = function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 then
		local camera = workspace.CurrentCamera
		if camera then
			local viewport = camera.ViewportSize
			local ray = camera:ViewportPointToRay(viewport.X / 2, viewport.Y / 2)
			local parameters = RaycastParams.new()
			parameters.FilterType = Enum.RaycastFilterType.Exclude
			parameters.FilterDescendantsInstances = {character}
			local result = workspace:Raycast(ray.Origin, ray.Direction * 80, parameters)
			return result and result.Position or root.Position + root.CFrame.LookVector * 60
		end
	end
	local target = mouse.Hit.Position
	if (target - root.Position).Magnitude > 80 then
		return root.Position + (target - root.Position).Unit * 80
	end
	return target
end

shared = ReplicatedStorage:WaitForChild("Shared")
progressionConfig = require(shared:WaitForChild("ProgressionConfig"))

feedbackRemote.OnClientEvent:Connect(function(kind, xp, coins)
	if kind == "CastRejected" then
		feedbackMessage = "CAST BLOCKED: " .. tostring(xp)
		feedbackExpires = os.clock() + 2
		return
	elseif kind == "CastAccepted" then
		feedbackMessage = "CAST: " .. tostring(xp)
		feedbackExpires = os.clock() + 1
		if xp ~= "Melee" and progressionConfig.Abilities[xp] then
			cooldownEnds[xp] = os.clock() + progressionConfig.Abilities[xp].Cooldown
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
	local worldError = workspace:GetAttribute("WorldError") or ""
	local countdown = workspace:GetAttribute("WaveCountdown") or 0
	local waveInfo = countdown > 0 and string.format("NEXT WAVE IN %d", countdown) or state
	healthFill.Size = UDim2.fromScale(math.clamp(health / math.max(maxHealth, 1), 0, 1), 1)
	xpFill.Size = UDim2.fromScale(math.clamp(xp / math.max(xpRequired, 1), 0, 1), 1)
	healthValue.Text = string.format("%d / %d", health, maxHealth)
	xpValue.Text = string.format("%d / %d", math.floor(xp), math.floor(xpRequired))
	status.Text = string.format("WORLD 1  |  v%s  |  %s\nCOMBAT: %s\nWAVE %d  |  %s\nEnemies: %d\nCore: %d / %d\nLevel %d  |  Coins %d  |  Evo %d\nSELECTED: %s%s%s%s", workspace:GetAttribute("WorldVersion") or "0.4.4", workspace:GetAttribute("WorldStatus") or "Starting", workspace:GetAttribute("CombatStatus") or "Offline", wave, waveInfo, remaining, coreHealth, coreMax, player:GetAttribute("Level") or 1, player:GetAttribute("Coins") or 0, player:GetAttribute("Evolution") or 0, abilityList[selectedAbilityIndex][1], player:GetAttribute("CanEvolve") and "\nEVOLUTION READY  [R]" or "", worldError ~= "" and "\nERROR: " .. worldError or "", os.clock() < feedbackExpires and "\n" .. feedbackMessage or "")
	status.TextColor3 = player:GetAttribute("CanEvolve") and Color3.fromRGB(255, 220, 100) or Color3.fromRGB(235, 245, 255)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		combatRemote:FireServer("Melee")
	elseif input.KeyCode == Enum.KeyCode.One then
		local target = targetPosition()
		if target then
			abilityRemote:FireServer("EnergyBlast", target)
		end
	elseif input.KeyCode == Enum.KeyCode.Two then
		local target = targetPosition()
		if target then
			abilityRemote:FireServer("FlameBurst", target)
		end
	elseif input.KeyCode == Enum.KeyCode.Three then
		local target = targetPosition()
		if target then
			abilityRemote:FireServer("ThunderStrike", target)
		end
	elseif input.KeyCode == Enum.KeyCode.Four then
		local target = targetPosition()
		if target then
			abilityRemote:FireServer("WindCutter", target)
		end
	elseif input.KeyCode == Enum.KeyCode.Five then
		local target = targetPosition()
		if target then
			abilityRemote:FireServer("MeteorCrash", target)
		end
	elseif input.KeyCode == Enum.KeyCode.Six then
		local target = targetPosition()
		if target then
			abilityRemote:FireServer("EnergyBeam", target)
		end
	elseif input.KeyCode == Enum.KeyCode.Seven then
		local target = targetPosition()
		if target then
			abilityRemote:FireServer("VoidExplosion", target)
		end
	elseif input.KeyCode == Enum.KeyCode.Eight then
		local target = targetPosition()
		if target then
			abilityRemote:FireServer("UltimateNova", target)
		end
	elseif input.KeyCode == Enum.KeyCode.R then
		evolutionRemote:FireServer()
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonR1 then
		selectAbility(selectedAbilityIndex + 1)
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonL1 then
		selectAbility(selectedAbilityIndex - 1)
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonR2 then
		castAbility(abilityList[selectedAbilityIndex][1])
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonX then
		combatRemote:FireServer("Melee")
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonY then
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
		task.wait(0.25)
	end
end)

local function handleAction(actionName, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if actionName == "CyclePowerNext" then
		selectAbility(selectedAbilityIndex + 1)
	elseif actionName == "CyclePowerPrevious" then
		selectAbility(selectedAbilityIndex - 1)
	elseif actionName == "CastPower" then
		castAbility(abilityList[selectedAbilityIndex][1])
	elseif actionName == "MeleeAttack" then
		combatRemote:FireServer("Melee")
	else
		return Enum.ContextActionResult.Pass
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("CyclePowerNext", handleAction, false, Enum.KeyCode.ButtonR1, Enum.KeyCode.RightBracket)
ContextActionService:BindAction("CyclePowerPrevious", handleAction, false, Enum.KeyCode.ButtonL1, Enum.KeyCode.LeftBracket)
ContextActionService:BindAction("CastPower", handleAction, false, Enum.KeyCode.ButtonR2, Enum.KeyCode.Return)
ContextActionService:BindAction("MeleeAttack", handleAction, false, Enum.KeyCode.ButtonX, Enum.KeyCode.F)