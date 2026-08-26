local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ProgressionConfig"))
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PowerRemote")
local gui = Instance.new("ScreenGui")
gui.Name = "PowersUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 125
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")
local panel = Instance.new("Frame")
panel.Name = "PowersPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(520, 500)
panel.BackgroundColor3 = Color3.fromRGB(17, 22, 34)
panel.Visible = false
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 0, 42)
title.Position = UDim2.fromOffset(18, 10)
title.BackgroundTransparency = 1
title.Text = "POWERS  •  MASTERY  •  LOADOUT"
title.TextColor3 = Color3.fromRGB(120, 220, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(34, 34)
close.Position = UDim2.new(1, -46, 0, 10)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = Color3.fromRGB(190, 60, 75)
close.Parent = panel
local info = Instance.new("TextLabel")
info.Position = UDim2.fromOffset(18, 54)
info.Size = UDim2.new(1, -36, 0, 45)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.fromRGB(190, 205, 225)
info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Left
info.Text = "Active attacks: 0/6    Motion powers: 0/2\nSelect unlocked powers to build your active combat loadout."
info.Parent = panel
local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(18, 108)
list.Size = UDim2.new(1, -36, 1, -126)
list.BackgroundColor3 = Color3.fromRGB(25, 32, 48)
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = list
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = list
local open = Instance.new("TextButton")
open.Size = UDim2.fromOffset(110, 36)
open.Position = UDim2.new(1, -390, 0, 14)
open.Text = "POWERS [P]"
open.TextColor3 = Color3.new(1, 1, 1)
open.BackgroundColor3 = Color3.fromRGB(95, 110, 190)
open.Parent = gui

local function style(button, active, unlocked)
	button.BackgroundColor3 = active and Color3.fromRGB(55, 135, 105) or Color3.fromRGB(43, 53, 75)
	button.TextColor3 = unlocked and Color3.new(1, 1, 1) or Color3.fromRGB(130, 140, 160)
	button.AutoButtonColor = unlocked
end
local function getState()
	local ok, state = pcall(function() return remote:InvokeServer("GetState") end)
	return ok and state or nil
end
local function render()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
	end
	local state = getState()
	if not state then return end
	local activeAttacks, activeMotion = {}, {}
	for _, name in ipairs(state.Attacks) do activeAttacks[name] = true end
	for _, name in ipairs(state.Motion) do activeMotion[name] = true end
	info.Text = string.format("Active attacks: %d/6    Motion powers: %d/2\nA green button is active. Click or press A to toggle.", #state.Attacks, #state.Motion)
	local function addPower(name, isMotion)
		local ability = config.Abilities[name]
		local unlocked = isMotion or state.Unlocked[name]
		local mastery = player:FindFirstChild("PowerMastery")
		local value = mastery and mastery:FindFirstChild(name)
		local level = value and (value:GetAttribute("Level") or 0) or 0
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -4, 0, 38)
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.Font = Enum.Font.GothamBold
		button.TextSize = 13
		button.Text = string.format("%s  |  Mastery %d  |  %s", ability and ability.DisplayName or name, level, unlocked and (isMotion and (activeMotion[name] and "ACTIVE" or "INACTIVE") or (activeAttacks[name] and "ACTIVE" or "INACTIVE")) or "LOCKED")
		style(button, isMotion and activeMotion[name] or activeAttacks[name], unlocked)
		button.Parent = list
		button.Activated:Connect(function()
			if not unlocked then return end
			local attacks = table.clone(state.Attacks)
			local motion = table.clone(state.Motion)
			local values = isMotion and motion or attacks
			local index = table.find(values, name)
			if index then table.remove(values, index) elseif #values < (isMotion and 2 or 6) then table.insert(values, name) else return end
			local result = remote:InvokeServer("SetLoadout", {Attacks = attacks, Motion = motion})
			if result and result.Success then render() end
		end)
	end
	local heading = Instance.new("TextLabel")
	heading.Size = UDim2.new(1, -4, 0, 24)
	heading.BackgroundTransparency = 1
	heading.Text = "ATTACKS (6 ACTIVE SLOTS)"
	heading.TextColor3 = Color3.fromRGB(255, 205, 100)
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.Parent = list
	for _, name in ipairs(config.AbilityOrder or {}) do addPower(name, false) end
	local motionHeading = heading:Clone()
	motionHeading.Text = "MOTION (2 ACTIVE SLOTS)"
	motionHeading.Parent = list
	addPower("PowerDash", true)
	addPower("Dodge", true)
end
local function toggle()
	panel.Visible = not panel.Visible
	if panel.Visible then render(); GuiService.SelectedObject = close else GuiService.SelectedObject = nil end
end
open.Activated:Connect(toggle)
close.Activated:Connect(toggle)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.P then toggle() end
end)
