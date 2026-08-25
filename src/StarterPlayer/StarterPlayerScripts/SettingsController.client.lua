local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local settingsRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SettingsRemote")

local screen = Instance.new("ScreenGui")
screen.Name = "CombatSettings"
screen.ResetOnSpawn = false
screen.DisplayOrder = 120
screen.Parent = playerGui

local toggle = Instance.new("TextButton")
toggle.Name = "SettingsToggle"
toggle.Size = UDim2.fromOffset(46, 40)
toggle.Position = UDim2.new(1, -58, 0, 14)
toggle.BackgroundColor3 = Color3.fromRGB(22, 30, 47)
toggle.BackgroundTransparency = 0.1
toggle.Text = "⚙"
toggle.TextColor3 = Color3.fromRGB(210, 235, 255)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 24
toggle.Parent = screen
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 9)
toggleCorner.Parent = toggle

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(220, 150)
panel.Position = UDim2.new(1, -232, 0, 62)
panel.BackgroundColor3 = Color3.fromRGB(16, 22, 35)
panel.BackgroundTransparency = 0.08
panel.Visible = false
panel.Parent = screen
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = panel

local function makeSettingButton(name)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, 0, 0, 36)
	button.BackgroundColor3 = Color3.fromRGB(35, 48, 70)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = button
	return button
end

local qualityButton = makeSettingButton("EffectQuality")
local shakeButton = makeSettingButton("CameraShake")
local numbersButton = makeSettingButton("DamageNumbers")

local function refresh()
	qualityButton.Text = "EFFECTS: " .. tostring(player:GetAttribute("EffectQuality") or "HIGH")
	shakeButton.Text = "CAMERA SHAKE: " .. ((player:GetAttribute("CameraShakeEnabled") ~= false) and "ON" or "OFF")
	numbersButton.Text = "DAMAGE NUMBERS: " .. ((player:GetAttribute("DamageNumbersEnabled") ~= false) and "ON" or "OFF")
end

toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

local function settingsGamepadAction(actionName, inputState)
	if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	if actionName == "SettingsPanelToggle" then
		panel.Visible = not panel.Visible
		GuiService.SelectedObject = panel.Visible and qualityButton or nil
		return Enum.ContextActionResult.Sink
	elseif actionName == "SettingsPanelClose" and panel.Visible then
		panel.Visible = false
		GuiService.SelectedObject = nil
		return Enum.ContextActionResult.Sink
	elseif actionName == "SettingsBlockCombat" and panel.Visible then
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindActionAtPriority("SettingsPanelToggle", settingsGamepadAction, false, 2800, Enum.KeyCode.ButtonR3)
ContextActionService:BindActionAtPriority("SettingsPanelClose", settingsGamepadAction, false, 2800, Enum.KeyCode.ButtonB)
ContextActionService:BindActionAtPriority("SettingsBlockCombat", settingsGamepadAction, false, 2800, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2, Enum.KeyCode.ButtonL3, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)

qualityButton.Activated:Connect(function()
	local current = player:GetAttribute("EffectQuality") or "HIGH"
	local value = current == "LOW" and "HIGH" or "LOW"
	player:SetAttribute("EffectQuality", value)
	settingsRemote:FireServer("EffectQuality", value)
	refresh()
end)

shakeButton.Activated:Connect(function()
	local value = not (player:GetAttribute("CameraShakeEnabled") ~= false)
	player:SetAttribute("CameraShakeEnabled", value)
	settingsRemote:FireServer("CameraShakeEnabled", value)
	refresh()
end)

numbersButton.Activated:Connect(function()
	local value = not (player:GetAttribute("DamageNumbersEnabled") ~= false)
	player:SetAttribute("DamageNumbersEnabled", value)
	settingsRemote:FireServer("DamageNumbersEnabled", value)
	refresh()
end)

refresh()
for _, attribute in ipairs({"EffectQuality", "CameraShakeEnabled", "DamageNumbersEnabled"}) do player:GetAttributeChangedSignal(attribute):Connect(refresh) end
