local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AdminRemote")
local itemConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemConfig"))
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local colors = {
	Panel = Color3.fromRGB(20, 25, 38),
	PanelLight = Color3.fromRGB(34, 42, 60),
	Accent = Color3.fromRGB(255, 177, 64),
	Danger = Color3.fromRGB(210, 65, 75),
	Success = Color3.fromRGB(80, 220, 145),
	Text = Color3.fromRGB(238, 243, 255),
	Muted = Color3.fromRGB(155, 170, 195),
}

local function round(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function styleButton(button, color)
	button.AutoButtonColor = true
	button.BackgroundColor3 = color or colors.PanelLight
	button.BorderSizePixel = 0
	button.TextColor3 = colors.Text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	round(button, 7)
end

local screen = Instance.new("ScreenGui")
screen.Name = "AdminControls"
screen.ResetOnSpawn = false
screen.DisplayOrder = 130
screen.IgnoreGuiInset = false
screen.Parent = playerGui

local openButton = Instance.new("TextButton")
openButton.Name = "AdminButton"
openButton.AnchorPoint = Vector2.new(1, 0)
openButton.Position = UDim2.new(1, -120, 0, 14)
openButton.Size = UDim2.fromOffset(82, 36)
openButton.Text = "ADMIN"
styleButton(openButton, colors.Accent)
openButton.TextColor3 = Color3.fromRGB(38, 30, 20)
openButton.Parent = screen

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -18, 0, 58)
panel.Size = UDim2.new(1, -36, 1, -76)
panel.BackgroundColor3 = colors.Panel
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screen
round(panel, 12)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(300, 360)
sizeConstraint.MaxSize = Vector2.new(430, 650)
sizeConstraint.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(16, 10)
title.Size = UDim2.new(1, -62, 0, 30)
title.BackgroundTransparency = 1
title.Text = "ASCENDANT DEV CONSOLE"
title.TextColor3 = colors.Accent
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBlack
title.TextSize = 19
title.Parent = panel

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -10, 0, 9)
close.Size = UDim2.fromOffset(32, 32)
close.Text = "X"
styleButton(close, colors.Danger)
close.Parent = panel

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(16, 42)
status.Size = UDim2.new(1, -32, 0, 38)
status.BackgroundTransparency = 1
status.Text = "Secure server tools • target, progression, forms, realms, waves, and stress testing"
status.TextColor3 = colors.Muted
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.Parent = panel

local lockFrame = Instance.new("Frame")
lockFrame.Position = UDim2.fromOffset(16, 88)
lockFrame.Size = UDim2.new(1, -32, 0, 118)
lockFrame.BackgroundColor3 = colors.PanelLight
lockFrame.BorderSizePixel = 0
lockFrame.Parent = panel
round(lockFrame, 9)

local codeBox = Instance.new("TextBox")
codeBox.Position = UDim2.fromOffset(12, 14)
codeBox.Size = UDim2.new(1, -24, 0, 42)
codeBox.BackgroundColor3 = Color3.fromRGB(15, 19, 30)
codeBox.BorderSizePixel = 0
codeBox.PlaceholderText = "Lock code"
codeBox.Text = ""
codeBox.ClearTextOnFocus = false
codeBox.TextColor3 = colors.Text
codeBox.PlaceholderColor3 = colors.Muted
codeBox.Font = Enum.Font.Gotham
codeBox.TextSize = 17
codeBox.TextTruncate = Enum.TextTruncate.AtEnd
round(codeBox, 7)
codeBox.Parent = lockFrame

local unlock = Instance.new("TextButton")
unlock.Position = UDim2.fromOffset(12, 66)
unlock.Size = UDim2.new(1, -24, 0, 40)
unlock.Text = "UNLOCK ADMIN"
styleButton(unlock, colors.Accent)
unlock.TextColor3 = Color3.fromRGB(38, 30, 20)
unlock.Parent = lockFrame

local controls = Instance.new("ScrollingFrame")
controls.Position = UDim2.fromOffset(16, 84)
controls.Size = UDim2.new(1, -32, 1, -100)
controls.BackgroundTransparency = 1
controls.BorderSizePixel = 0
controls.ScrollBarThickness = 5
controls.ScrollBarImageColor3 = colors.Accent
controls.AutomaticCanvasSize = Enum.AutomaticSize.Y
controls.CanvasSize = UDim2.new()
controls.Visible = false
controls.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = controls

local function createSection(text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -6, 0, 25)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = colors.Accent
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.Parent = controls
	return label
end

local function createTextBox(placeholder, defaultText)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -6, 0, 38)
	box.BackgroundColor3 = colors.PanelLight
	box.BorderSizePixel = 0
	box.PlaceholderText = placeholder
	box.Text = defaultText or ""
	box.ClearTextOnFocus = false
	box.TextColor3 = colors.Text
	box.PlaceholderColor3 = colors.Muted
	box.Font = Enum.Font.Gotham
	box.TextSize = 14
	box.TextXAlignment = Enum.TextXAlignment.Left
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = box
	round(box, 7)
	box.Parent = controls
	return box
end

createSection("PLAYER TARGET")
local targetBox = createTextBox("Target: me, username, display name, or UserId", "me")

local function createRow()
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, 38)
	row.BackgroundTransparency = 1
	row.Parent = controls
	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.fromOffset(7, 0)
	grid.CellSize = UDim2.new(0.5, -4, 1, 0)
	grid.FillDirectionMaxCells = 2
	grid.Parent = row
	return row
end

local function setStatus(message, success)
	status.Text = tostring(message or "No response from server")
	status.TextColor3 = success and colors.Success or colors.Danger
end

local busy = false
local spawnCatalog
local playerCatalog = {{Name = "me", DisplayName = "Me", UserId = 0}}
local playerCatalogIndex = 0
local function invoke(action, payload)
	if busy then
		return nil
	end
	busy = true
	local success, result = pcall(function()
		return remote:InvokeServer(action, payload or {})
	end)
	busy = false
	if not success then
		setStatus("Server request failed", false)
		return nil
	end
	setStatus(result.Message, result.Success)
	return result
end

local function actionButton(parent, text, action, payloadFactory, color)
	local button = Instance.new("TextButton")
	button.Text = text
	styleButton(button, color)
	button.Parent = parent
	button.Activated:Connect(function()
		if action == "Kick" and os.clock() > (button:GetAttribute("ConfirmUntil") or 0) then
			button:SetAttribute("ConfirmUntil", os.clock() + 3)
			button.Text = "CONFIRM KICK"
			setStatus("Press CONFIRM KICK within 3 seconds", false)
			task.delay(3, function() if button.Parent then button.Text = text end end)
			return
		end
		local payload = payloadFactory and payloadFactory() or {}
		if action ~= "GetPlayers" then
			payload.Target = targetBox.Text
		end
		local result = invoke(action, payload)
		if action == "Kick" then button.Text = text; button:SetAttribute("ConfirmUntil", 0) end
		if action == "GetSpawnCatalog" and result and type(result.Data) == "table" and spawnCatalog then
			local lines = {}
			for _, entry in ipairs(result.Data) do table.insert(lines, string.format("%s | HP %d | DMG %d | ACTIVE %d", entry.Name, entry.Health, entry.Damage, entry.Count)) end
			spawnCatalog.Text = table.concat(lines, "\n")
		end
	end)
	return button
end

local targetRow = createRow()
local targetMe = Instance.new("TextButton")
targetMe.Text, targetMe.Parent = "TARGET ME", targetRow
styleButton(targetMe, colors.Success)
targetMe.Activated:Connect(function() targetBox.Text = "me"; setStatus("Target set to yourself", true) end)
local cycleTarget = Instance.new("TextButton")
cycleTarget.Text, cycleTarget.Parent = "NEXT PLAYER", targetRow
styleButton(cycleTarget)
cycleTarget.Activated:Connect(function()
	local result = invoke("GetPlayers")
	if result and type(result.Data) == "table" and #result.Data > 0 then playerCatalog = result.Data end
	playerCatalogIndex = playerCatalogIndex % #playerCatalog + 1
	local target = playerCatalog[playerCatalogIndex]
	targetBox.Text = target.UserId == 0 and "me" or tostring(target.UserId)
	cycleTarget.Text = "TARGET: " .. string.upper(target.DisplayName or target.Name)
end)

createSection("PLAYER TOOLS")
local row1 = createRow()
actionButton(row1, "GOD MODE", "GodMode")
actionButton(row1, "HEAL", "Heal")
local row2 = createRow()
actionButton(row2, "REFILL ALL", "Refill")
actionButton(row2, "DAMAGE x2 (60s)", "DamageBoost")
local row3 = createRow()
actionButton(row3, "SPEED 36", "SetSpeed", function() return {Preset = "Normal"} end)
actionButton(row3, "SPEED 60", "SetSpeed", function() return {Preset = "Boost"} end)
local row4 = createRow()
actionButton(row4, "SPEED 90", "SetSpeed", function() return {Preset = "Extreme"} end)
actionButton(row4, "RESET SPEED", "ResetSpeed")
local rowSafety = createRow()
actionButton(rowSafety, "RESPAWN", "Respawn")
actionButton(rowSafety, "KICK TARGET", "Kick", nil, colors.Danger)
local rowPowers = createRow()
actionButton(rowPowers, "UNLOCK ALL POWERS", "UnlockPowers", nil, colors.Accent)
actionButton(rowPowers, "GRANT 5 POTIONS", "GrantItem", function()
	return {ItemId = "HealthPotion", Quantity = 5}
end)
local rowEvolution = createRow()
actionButton(rowEvolution, "FORCE NEXT EVOLUTION", "ForceEvolution", nil, colors.Accent)

createSection("PROGRESSION")
local amountBox = createTextBox("Gold / XP amount (1-1,000,000)", "1000")
local progressionRow = createRow()
actionButton(progressionRow, "GRANT GOLD", "AddCoins", function() return {Amount = amountBox.Text} end, colors.Accent)
actionButton(progressionRow, "GRANT XP", "AddXP", function() return {Amount = amountBox.Text} end, colors.Accent)
local levelBox = createTextBox("Set level (1-100)", "10")
local levelRow = createRow()
actionButton(levelRow, "SET LEVEL", "SetLevel", function() return {Level = levelBox.Text} end, colors.Accent)
local skillRow = createRow()
actionButton(skillRow, "GRANT 5 SKILL + ELEMENT", "GrantSkillPoints", function() return {Amount = 5, ElementAmount = 5} end, colors.Success)
actionButton(skillRow, "RESET POWER COOLDOWNS", "ResetCooldowns", nil, colors.Success)

createSection("ANIMAL TRANSFORMATIONS")
local transformUnlockRow = createRow()
actionButton(transformUnlockRow, "UNLOCK ALL FORMS", "UnlockAllTransformations", nil, colors.Accent)
actionButton(transformUnlockRow, "RETURN TO HUMAN", "SetTransformation", function() return {FormId = ""} end)
local transformRow1 = createRow()
actionButton(transformRow1, "WOLF FORM", "SetTransformation", function() return {FormId = "Wolf"} end, Color3.fromRGB(70, 125, 180))
actionButton(transformRow1, "BEAR FORM", "SetTransformation", function() return {FormId = "Bear"} end, Color3.fromRGB(135, 85, 50))
local transformRow2 = createRow()
actionButton(transformRow2, "EAGLE FORM", "SetTransformation", function() return {FormId = "Eagle"} end, Color3.fromRGB(175, 145, 65))

createSection("ELEMENTAL REALMS")
local realmRow1 = createRow()
actionButton(realmRow1, "FIRE REALM", "TeleportRealm", function() return {RealmId = "FireWorld"} end, Color3.fromRGB(180, 65, 35))
actionButton(realmRow1, "ICE REALM", "TeleportRealm", function() return {RealmId = "IceWorld"} end, Color3.fromRGB(60, 145, 190))
local realmRow2 = createRow()
actionButton(realmRow2, "STORM REALM", "TeleportRealm", function() return {RealmId = "StormWorld"} end, Color3.fromRGB(165, 145, 45))
actionButton(realmRow2, "EARTH REALM", "TeleportRealm", function() return {RealmId = "EarthWorld"} end, Color3.fromRGB(75, 125, 65))

createSection("PRACTICE SPAWNS")

local row5 = createRow()
actionButton(row5, "SPAWN BASIC", "SpawnEnemy", function() return {EnemyType = "Basic"} end)
actionButton(row5, "SPAWN FAST", "SpawnEnemy", function() return {EnemyType = "Fast"} end)
local row6 = createRow()
actionButton(row6, "SPAWN TANK", "SpawnEnemy", function() return {EnemyType = "Tank"} end)
actionButton(row6, "SPAWN BOSS", "SpawnEnemy", function() return {EnemyType = "Boss"} end, colors.Danger)
local cleanupRow = createRow()
actionButton(cleanupRow, "CLEAR PRACTICE ENEMIES", "ClearPracticeEnemies", nil, colors.Danger)
local stressCount = createTextBox("Stress count (1-100)", "25")
local stressRow = createRow()
actionButton(stressRow, "STRESS: BASIC", "SpawnStressTest", function() return {EnemyType = "Basic", Count = stressCount.Text} end, colors.Danger)
actionButton(stressRow, "STRESS: TANK", "SpawnStressTest", function() return {EnemyType = "Tank", Count = stressCount.Text} end, colors.Danger)
spawnCatalog = Instance.new("TextLabel")
spawnCatalog.Size = UDim2.new(1, -6, 0, 70)
spawnCatalog.BackgroundColor3 = colors.PanelLight
spawnCatalog.TextColor3 = colors.Text
spawnCatalog.TextWrapped = true
spawnCatalog.TextXAlignment = Enum.TextXAlignment.Left
spawnCatalog.TextYAlignment = Enum.TextYAlignment.Top
spawnCatalog.Text = "CREATURE CATALOG: press LIST SPAWNS"
spawnCatalog.Parent = controls
local spawnListButton = actionButton(createRow(), "LIST SPAWNS + COUNTS", "GetSpawnCatalog")

local waveBox = createTextBox("Next wave (1-50)", "10")
local row7 = createRow()
actionButton(row7, "SET NEXT WAVE", "SetWave", function() return {Wave = waveBox.Text} end, colors.Accent)
actionButton(row7, "LIST PLAYERS", "GetPlayers")

createSection("ITEM GRANTS")
local itemBox = createTextBox("IronBlade / HealthPotion / ManaPotion / EvolutionShard", "HealthPotion")
local quantityBox = createTextBox("Quantity (1-25 per grant)", "1")
itemBox.Visible = false
local grantCategories = {"Weapon", "Armor", "Artifact", "Consumable", "Material"}
local grantCategoryIndex = 4
local grantItemIds = {}
local grantItemIndex = 1
local grantPlayers = {{Name = "me", DisplayName = "Me", UserId = 0}}
local grantPlayerIndex = 0
local function choiceButton(text)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -6, 0, 38)
	button.Text = text
	styleButton(button, colors.PanelLight)
	button.Parent = controls
	return button
end
local categoryButton = choiceButton("TYPE: CONSUMABLE")
local itemChoiceButton = choiceButton("ITEM: HEALTH CORE")
local targetChoiceButton = choiceButton("TARGET: ME")
local function refreshGrantItems()
	grantItemIds = {}
	local category = grantCategories[grantCategoryIndex]
	for itemId, definition in pairs(require(ReplicatedStorage.Shared.ItemConfig).Items) do
		if definition.Category == category then table.insert(grantItemIds, itemId) end
	end
	table.sort(grantItemIds)
	grantItemIndex = math.clamp(grantItemIndex, 1, math.max(1, #grantItemIds))
	local itemId = grantItemIds[grantItemIndex]
	itemBox.Text = itemId or ""
	local definition = itemId and itemConfig.Items[itemId]
	local symbol = ({Weapon = "SWORD", Armor = "ARMOR", Artifact = "CORE", Consumable = "POTION", Material = "MATERIAL"})[definition and definition.Category] or "ITEM"
	itemChoiceButton.Text = string.format("%s: %s | %s", symbol, definition and definition.DisplayName or "NONE", definition and (definition.Stats and "STATS " .. tostring(definition.Stats.Attack or definition.Stats.Power or definition.Stats.Health or 0) or "NO STATS") or "")
end
categoryButton.Activated:Connect(function()
	grantCategoryIndex = grantCategoryIndex % #grantCategories + 1
	categoryButton.Text = "TYPE: " .. string.upper(grantCategories[grantCategoryIndex])
	refreshGrantItems()
end)
itemChoiceButton.Activated:Connect(function()
	if #grantItemIds == 0 then return end
	grantItemIndex = grantItemIndex % #grantItemIds + 1
	refreshGrantItems()
end)
targetChoiceButton.Activated:Connect(function()
	local result = invoke("GetPlayers")
	if result and type(result.Data) == "table" and #result.Data > 0 then grantPlayers = result.Data end
	grantPlayerIndex = grantPlayerIndex % #grantPlayers + 1
	local target = grantPlayers[grantPlayerIndex]
	targetBox.Text = target.UserId == 0 and "me" or tostring(target.UserId)
	targetChoiceButton.Text = "TARGET: " .. (target.DisplayName or target.Name)
end)
local itemRow = createRow()
actionButton(itemRow, "GRANT ITEM", "GrantItem", function()
	return {ItemId = itemBox.Text, Quantity = quantityBox.Text}
end, colors.Accent)
refreshGrantItems()

openButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)
close.Activated:Connect(function()
	panel.Visible = false
end)

local function tryUnlock()
	local result = invoke("Unlock", {Code = codeBox.Text})
	codeBox.Text = ""
	if result and result.Success then
		lockFrame.Visible = false
		controls.Visible = true
	end
end

unlock.Activated:Connect(tryUnlock)
codeBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		tryUnlock()
	end
end)

local function adminGamepadAction(actionName, inputState)
	if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	if actionName == "AdminPanelChord" then
		if not UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonL2) then return Enum.ContextActionResult.Pass end
		panel.Visible = not panel.Visible
		GuiService.SelectedObject = panel.Visible and (lockFrame.Visible and unlock or close) or nil
		return Enum.ContextActionResult.Sink
	elseif actionName == "AdminPanelClose" and panel.Visible then
		panel.Visible = false
		GuiService.SelectedObject = nil
		return Enum.ContextActionResult.Sink
	elseif actionName == "AdminBlockCombat" and panel.Visible then
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindActionAtPriority("AdminPanelChord", adminGamepadAction, false, 3200, Enum.KeyCode.DPadUp)
ContextActionService:BindActionAtPriority("AdminPanelClose", adminGamepadAction, false, 2900, Enum.KeyCode.ButtonB)
ContextActionService:BindActionAtPriority("AdminBlockCombat", adminGamepadAction, false, 2900, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2, Enum.KeyCode.ButtonL3, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.F8 then
		panel.Visible = not panel.Visible
	end
end)
