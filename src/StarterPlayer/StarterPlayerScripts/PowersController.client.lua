local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local config = require(ReplicatedStorage.Shared.ProgressionConfig)
local remote = ReplicatedStorage.Remotes:WaitForChild("PowerRemote")
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.IgnoreGuiInset, gui.Parent = "PowersUI", false, 125, false, player:WaitForChild("PlayerGui")

local colors = {Panel = Color3.fromRGB(17, 23, 35), Card = Color3.fromRGB(39, 50, 72), Active = Color3.fromRGB(45, 142, 107), Locked = Color3.fromRGB(47, 48, 58), Accent = Color3.fromRGB(105, 215, 255), Gold = Color3.fromRGB(255, 205, 90)}
local function round(object, radius) local value = Instance.new("UICorner") value.CornerRadius, value.Parent = UDim.new(0, radius), object end
local function style(button, color)
	button.BackgroundColor3, button.BorderSizePixel, button.TextColor3 = color or colors.Card, 0, Color3.new(1, 1, 1)
	button.Font, button.TextSize = Enum.Font.GothamBold, 12
	round(button, 7)
end

local open = Instance.new("TextButton")
open.Size, open.Position, open.Text, open.BackgroundColor3, open.TextColor3, open.Parent = UDim2.fromOffset(110, 36), UDim2.new(1, -390, 0, 14), "POWERS [P]", Color3.fromRGB(95, 110, 190), Color3.new(1, 1, 1), gui

local panel = Instance.new("Frame")
panel.Name, panel.AnchorPoint, panel.Position, panel.Size = "PowersPanel", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.53), UDim2.fromOffset(590, 520)
panel.BackgroundColor3, panel.BorderSizePixel, panel.Visible, panel.Parent = colors.Panel, 0, false, gui
round(panel, 12)
local constraint = Instance.new("UISizeConstraint")
constraint.MinSize, constraint.MaxSize, constraint.Parent = Vector2.new(500, 440), Vector2.new(590, 520), panel

local title = Instance.new("TextLabel")
title.Position, title.Size, title.BackgroundTransparency, title.Text = UDim2.fromOffset(18, 10), UDim2.new(1, -75, 0, 34), 1, "POWER LIBRARY  •  6 COMBAT  •  2 SPECIAL"
title.TextColor3, title.Font, title.TextSize, title.TextXAlignment, title.Parent = colors.Accent, Enum.Font.GothamBlack, 18, Enum.TextXAlignment.Left, panel
local close = Instance.new("TextButton")
close.Position, close.Size, close.Text, close.Parent = UDim2.new(1, -48, 0, 9), UDim2.fromOffset(36, 36), "X", panel
style(close, Color3.fromRGB(190, 60, 75))
local info = Instance.new("TextLabel")
info.Position, info.Size, info.BackgroundTransparency = UDim2.fromOffset(18, 46), UDim2.new(1, -36, 0, 34), 1
info.TextColor3, info.TextXAlignment, info.Font, info.TextSize, info.Parent = Color3.fromRGB(180, 195, 215), Enum.TextXAlignment.Left, Enum.Font.Gotham, 12, panel

local slots = Instance.new("Frame")
slots.Position, slots.Size, slots.BackgroundTransparency, slots.Parent = UDim2.fromOffset(18, 82), UDim2.new(1, -36, 0, 106), 1, panel
local slotGrid = Instance.new("UIGridLayout")
slotGrid.CellSize, slotGrid.CellPadding, slotGrid.FillDirectionMaxCells, slotGrid.Parent = UDim2.new(0.25, -6, 0, 48), UDim2.fromOffset(7, 7), 4, slots

local filterValues = {"ALL", "UNLOCKED", "LOCKED", "FIRE", "ICE", "LIGHTNING", "EARTH", "GRAVITY", "POISON", "PRISMATIC", "WIND", "ARCANE", "SPECIAL"}
local sortValues = {"LEVEL", "NAME", "MASTERY", "ELEMENT"}
local filterIndex, sortIndex, selectedSlot = 1, 1, 1
local filterButton = Instance.new("TextButton")
filterButton.Position, filterButton.Size, filterButton.Parent = UDim2.fromOffset(18, 198), UDim2.fromOffset(150, 36), panel
style(filterButton)
local sortButton = Instance.new("TextButton")
sortButton.Position, sortButton.Size, sortButton.Parent = UDim2.fromOffset(176, 198), UDim2.fromOffset(150, 36), panel
style(sortButton)
local hint = Instance.new("TextLabel")
hint.Position, hint.Size, hint.BackgroundTransparency, hint.Text = UDim2.fromOffset(340, 198), UDim2.new(1, -358, 0, 36), 1, "Select a slot, then choose a power."
hint.TextColor3, hint.Font, hint.TextSize, hint.TextXAlignment, hint.Parent = Color3.fromRGB(145, 165, 190), Enum.Font.Gotham, 12, Enum.TextXAlignment.Right, panel

local list = Instance.new("ScrollingFrame")
list.Position, list.Size, list.BackgroundColor3, list.BorderSizePixel = UDim2.fromOffset(18, 244), UDim2.new(1, -36, 1, -262), Color3.fromRGB(24, 31, 47), 0
list.ScrollBarThickness, list.AutomaticCanvasSize, list.CanvasSize, list.Parent = 5, Enum.AutomaticSize.Y, UDim2.new(), panel
local layout = Instance.new("UIGridLayout")
layout.CellSize, layout.CellPadding, layout.FillDirectionMaxCells, layout.Parent = UDim2.fromOffset(128, 128), UDim2.fromOffset(7, 7), 4, list
local padding = Instance.new("UIPadding") padding.PaddingTop, padding.PaddingLeft, padding.PaddingRight, padding.PaddingBottom, padding.Parent = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8), list

local currentState
local function masteryLevel(name)
	local folder = player:FindFirstChild("PowerMastery")
	local value = folder and folder:FindFirstChild(name)
	return value and (value:GetAttribute("Level") or 0) or 0
end
local function request(action, payload)
	local ok, result = pcall(function() return remote:InvokeServer(action, payload) end)
	if not ok then info.Text = "Power server unavailable"; return nil end
	if result and result.Message then info.Text = result.Message end
	return result
end
local function getDefinitions(state)
	local values = {}
	for _, name in ipairs(config.AbilityOrder or {}) do
		local definition = config.Abilities[name]
		table.insert(values, {Name = name, Definition = definition, Kind = "Attack", Unlocked = state.Unlocked[name] == true, Mastery = masteryLevel(name)})
	end
	for _, name in ipairs(config.MotionOrder or {}) do
		local definition = config.MotionPowers[name]
		table.insert(values, {Name = name, Definition = definition, Kind = definition.Category, Unlocked = state.MotionUnlocked[name] == true, Mastery = 0})
	end
	return values
end
local function matches(entry)
	if selectedSlot <= 6 and entry.Kind ~= "Attack" then return false end
	if selectedSlot == 7 and entry.Kind ~= "Mobility" then return false end
	if selectedSlot == 8 and entry.Kind ~= "Technique" then return false end
	local filter = filterValues[filterIndex]
	if filter == "ALL" then return true end
	if filter == "UNLOCKED" then return entry.Unlocked end
	if filter == "LOCKED" then return not entry.Unlocked end
	if filter == "SPECIAL" then return entry.Kind ~= "Attack" end
	return string.upper(entry.Definition.Element or "") == filter
end
local function save(attacks, motion)
	local result = request("SetLoadout", {Attacks = attacks, Motion = motion})
	if result and result.Success then currentState = request("GetState"); return true end
	return false
end
local render
local function renderSlots()
	for _, child in ipairs(slots:GetChildren()) do if child:IsA("GuiButton") then child:Destroy() end end
	for index = 1, 8 do
		local isAttack = index <= 6
		local name = isAttack and currentState.Attacks[index] or currentState.Motion[index - 6]
		local definition = name and (config.Abilities[name] or config.MotionPowers[name])
		local button = Instance.new("TextButton")
		button.LayoutOrder, button.TextWrapped = index, true
		button.Text = string.format("%s%d  %s", isAttack and "SLOT " or "SPECIAL ", isAttack and index or index - 6, definition and definition.DisplayName or "EMPTY")
		style(button, selectedSlot == index and Color3.fromRGB(62, 105, 145) or (isAttack and colors.Card or Color3.fromRGB(77, 58, 105)))
		button.Parent = slots
		button.Activated:Connect(function() selectedSlot = index; render() end)
	end
end
local function assign(entry)
	if not entry.Unlocked then info.Text = string.format("Locked until level %d / evolution %d", entry.Definition.RequiredLevel or 1, entry.Definition.RequiredEvolution or 0); return end
	local attacks, motion = table.clone(currentState.Attacks), table.clone(currentState.Motion)
	if entry.Kind == "Attack" then
		if selectedSlot > 6 then info.Text = "Select one of the six combat slots first"; return end
		local existing = table.find(attacks, entry.Name)
		local target = math.min(selectedSlot, #attacks + 1)
		if existing and existing ~= target and target <= #attacks then attacks[existing], attacks[target] = attacks[target], attacks[existing]
		elseif not existing then attacks[target] = entry.Name end
	else
		local target = entry.Kind == "Mobility" and 1 or 2
		motion[target] = entry.Name
		selectedSlot = target + 6
	end
	if save(attacks, motion) then render() end
end
render = function()
	currentState = currentState or request("GetState")
	if not currentState then return end
	filterButton.Text, sortButton.Text = "FILTER: " .. filterValues[filterIndex], "SORT: " .. sortValues[sortIndex]
	info.Text = string.format("Combat %d/6  •  Mobility: %s  •  Technique: %s", #currentState.Attacks, currentState.Motion[1] or "EMPTY", currentState.Motion[2] or "EMPTY")
	renderSlots()
	for _, child in ipairs(list:GetChildren()) do if child:IsA("GuiButton") or child:IsA("TextLabel") then child:Destroy() end end
	local entries = getDefinitions(currentState)
	table.sort(entries, function(left, right)
		local mode = sortValues[sortIndex]
		if mode == "NAME" then return left.Definition.DisplayName < right.Definition.DisplayName end
		if mode == "MASTERY" and left.Mastery ~= right.Mastery then return left.Mastery > right.Mastery end
		if mode == "ELEMENT" then
			local a, b = left.Definition.Element or left.Kind, right.Definition.Element or right.Kind
			if a ~= b then return a < b end
		end
		local a, b = left.Definition.RequiredLevel or 1, right.Definition.RequiredLevel or 1
		return a == b and left.Definition.DisplayName < right.Definition.DisplayName or a < b
	end)
	for _, entry in ipairs(entries) do if matches(entry) then
		local active = table.find(currentState.Attacks, entry.Name) or table.find(currentState.Motion, entry.Name)
		local card = Instance.new("TextButton")
		card.Size, card.TextXAlignment, card.TextYAlignment, card.TextWrapped = UDim2.fromOffset(128, 128), Enum.TextXAlignment.Center, Enum.TextYAlignment.Bottom, true
		card.Font, card.TextSize = Enum.Font.GothamBold, 12
		local definition = entry.Definition
		local details = entry.Kind == "Attack" and string.format("%s  LV%d  CD %.1fs\nRANGE %d  MASTERY %d", string.upper(definition.Element or "Arcane"), definition.RequiredLevel or 1, definition.Cooldown or 0, definition.Range or 0, entry.Mastery)
			or string.format("%s  LV%d\nCD %.1fs  COST %d", string.upper(entry.Kind), definition.RequiredLevel or 1, definition.Cooldown or 0, definition.StaminaCost or 0)
		card.Text = string.format("\n\n\n%s%s\n%s", definition.DisplayName, active and " [ON]" or "", details)
		style(card, not entry.Unlocked and colors.Locked or active and colors.Active or colors.Card)
		card.TextColor3 = entry.Unlocked and Color3.new(1, 1, 1) or Color3.fromRGB(135, 140, 155)
		card.Parent = list
		local icon = Instance.new("TextLabel")
		local iconText = {Fire = "FIRE", Ice = "ICE", Lightning = "BOLT", Earth = "ROCK", Gravity = "VOID", Poison = "TOX", Prismatic = "PRISM", Arcane = "ARC", Wind = "WIND"}
		local iconColors = {Fire = Color3.fromRGB(255, 95, 40), Ice = Color3.fromRGB(105, 220, 255), Lightning = Color3.fromRGB(255, 230, 70), Earth = Color3.fromRGB(145, 190, 95), Gravity = Color3.fromRGB(180, 90, 255), Poison = Color3.fromRGB(105, 230, 80), Prismatic = Color3.fromRGB(255, 105, 220)}
		local element = definition.Element or entry.Kind
		icon.Position, icon.Size, icon.BackgroundColor3, icon.BorderSizePixel = UDim2.new(0.5, -26, 0, 9), UDim2.fromOffset(52, 52), iconColors[element] or colors.Accent, 0
		icon.Text, icon.TextColor3, icon.Font, icon.TextSize, icon.Parent = iconText[element] or string.sub(string.upper(entry.Kind), 1, 4), Color3.new(1, 1, 1), Enum.Font.GothamBlack, 11, card
		round(icon, 12)
		card.Activated:Connect(function() assign(entry) end)
	end end
end

filterButton.Activated:Connect(function() filterIndex = filterIndex % #filterValues + 1; render() end)
sortButton.Activated:Connect(function() sortIndex = sortIndex % #sortValues + 1; render() end)
local function toggle() panel.Visible = not panel.Visible; if panel.Visible then currentState = request("GetState"); render(); GuiService.SelectedObject = close else GuiService.SelectedObject = nil end end
open.Activated:Connect(toggle) close.Activated:Connect(toggle)
UserInputService.InputBegan:Connect(function(input, processed) if not processed and input.KeyCode == Enum.KeyCode.P then toggle() end end)
