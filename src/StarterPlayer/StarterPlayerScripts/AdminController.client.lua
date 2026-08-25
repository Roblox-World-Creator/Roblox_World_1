local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AdminRemote")
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
panel.Size = UDim2.new(1, -36, 0, 455)
panel.BackgroundColor3 = colors.Panel
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screen
round(panel, 12)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(300, 360)
sizeConstraint.MaxSize = Vector2.new(390, 455)
sizeConstraint.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(16, 10)
title.Size = UDim2.new(1, -62, 0, 30)
title.BackgroundTransparency = 1
title.Text = "SERVER ADMIN"
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
status.Text = "Enter the server lock code to continue."
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

local targetBox = createTextBox("Target: me, username, or UserId", "me")

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
		local payload = payloadFactory and payloadFactory() or {}
		if action ~= "GetPlayers" then
			payload.Target = targetBox.Text
		end
		invoke(action, payload)
	end)
	return button
end

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
actionButton(row4, "KICK TARGET", "Kick", nil, colors.Danger)
local rowPowers = createRow()
actionButton(rowPowers, "UNLOCK ALL POWERS", "UnlockPowers", nil, colors.Accent)
actionButton(rowPowers, "GRANT 5 POTIONS", "GrantItem", function()
	return {ItemId = "HealthPotion", Quantity = 5}
end)

local spawnTitle = Instance.new("TextLabel")
spawnTitle.Size = UDim2.new(1, -6, 0, 24)
spawnTitle.BackgroundTransparency = 1
spawnTitle.Text = "PRACTICE SPAWNS"
spawnTitle.TextColor3 = colors.Accent
spawnTitle.TextXAlignment = Enum.TextXAlignment.Left
spawnTitle.Font = Enum.Font.GothamBold
spawnTitle.TextSize = 13
spawnTitle.Parent = controls

local row5 = createRow()
actionButton(row5, "SPAWN BASIC", "SpawnEnemy", function() return {EnemyType = "Basic"} end)
actionButton(row5, "SPAWN FAST", "SpawnEnemy", function() return {EnemyType = "Fast"} end)
local row6 = createRow()
actionButton(row6, "SPAWN TANK", "SpawnEnemy", function() return {EnemyType = "Tank"} end)
actionButton(row6, "SPAWN BOSS", "SpawnEnemy", function() return {EnemyType = "Boss"} end, colors.Danger)

local waveBox = createTextBox("Next wave (1-50)", "10")
local row7 = createRow()
actionButton(row7, "SET NEXT WAVE", "SetWave", function() return {Wave = waveBox.Text} end, colors.Accent)
actionButton(row7, "LIST PLAYERS", "GetPlayers")

local itemTitle = Instance.new("TextLabel")
itemTitle.Size = UDim2.new(1, -6, 0, 24)
itemTitle.BackgroundTransparency = 1
itemTitle.Text = "ITEM GRANTS"
itemTitle.TextColor3 = colors.Accent
itemTitle.TextXAlignment = Enum.TextXAlignment.Left
itemTitle.Font = Enum.Font.GothamBold
itemTitle.TextSize = 13
itemTitle.Parent = controls
local itemBox = createTextBox("IronBlade / HealthPotion / ManaPotion / EvolutionShard", "HealthPotion")
local quantityBox = createTextBox("Quantity (1-25 per grant)", "1")
local itemRow = createRow()
actionButton(itemRow, "GRANT ITEM", "GrantItem", function()
	return {ItemId = itemBox.Text, Quantity = quantityBox.Text}
end, colors.Accent)

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
