local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestConfig"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:WaitForChild("QuestRemote")
local event = remotes:WaitForChild("QuestEvent")
local quests = {}
local busy = false

local function round(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "QuestLog", false, 121
gui.Parent = player:WaitForChild("PlayerGui")
local open = Instance.new("TextButton")
open.AnchorPoint, open.Position, open.Size = Vector2.new(1, 0), UDim2.new(1, -300, 0, 14), UDim2.fromOffset(82, 36)
open.BackgroundColor3, open.BorderSizePixel = Color3.fromRGB(105, 75, 175), 0
open.Text, open.TextColor3, open.Font, open.TextSize = "QUEST [J]", Color3.new(1, 1, 1), Enum.Font.GothamBold, 12
round(open, 7)
open.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint, panel.Position, panel.Size = Vector2.new(1, 0.5), UDim2.new(1, -18, 0.55, 0), UDim2.new(0.58, 0, 0.72, 0)
panel.BackgroundColor3, panel.BorderSizePixel, panel.Visible = Color3.fromRGB(18, 22, 35), 0, false
round(panel, 12)
panel.Parent = gui
local constraint = Instance.new("UISizeConstraint")
constraint.MinSize, constraint.MaxSize = Vector2.new(310, 350), Vector2.new(600, 500)
constraint.Parent = panel
local title = Instance.new("TextLabel")
title.Position, title.Size, title.BackgroundTransparency = UDim2.fromOffset(16, 10), UDim2.new(1, -70, 0, 34), 1
title.Text, title.TextColor3, title.TextXAlignment, title.Font, title.TextSize = "ASCENDANT QUESTS", Color3.fromRGB(185, 125, 255), Enum.TextXAlignment.Left, Enum.Font.GothamBlack, 20
title.Parent = panel
local close = Instance.new("TextButton")
close.AnchorPoint, close.Position, close.Size = Vector2.new(1, 0), UDim2.new(1, -10, 0, 9), UDim2.fromOffset(34, 34)
close.BackgroundColor3, close.BorderSizePixel = Color3.fromRGB(185, 60, 75), 0
close.Text, close.TextColor3, close.Font = "X", Color3.new(1, 1, 1), Enum.Font.GothamBold
round(close, 7)
close.Parent = panel
local status = Instance.new("TextLabel")
status.Position, status.Size, status.BackgroundTransparency = UDim2.fromOffset(16, 46), UDim2.new(1, -32, 0, 28), 1
status.Text, status.TextColor3, status.TextXAlignment, status.Font, status.TextSize = "Complete objectives and claim their rewards.", Color3.fromRGB(165, 180, 205), Enum.TextXAlignment.Left, Enum.Font.Gotham, 13
status.Parent = panel
local list = Instance.new("ScrollingFrame")
list.Position, list.Size = UDim2.fromOffset(16, 78), UDim2.new(1, -32, 1, -94)
list.BackgroundTransparency, list.BorderSizePixel, list.ScrollBarThickness = 1, 0, 5
list.AutomaticCanvasSize, list.CanvasSize = Enum.AutomaticSize.Y, UDim2.new()
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding, layout.SortOrder = UDim.new(0, 8), Enum.SortOrder.LayoutOrder
layout.Parent = list

local function request(action, payload)
	if busy then return nil end
	busy = true
	local ok, result = pcall(function() return remote:InvokeServer(action, payload or {}) end)
	busy = false
	if not ok then status.Text, status.TextColor3 = "Quest server unavailable", Color3.fromRGB(255, 105, 115); return nil end
	status.Text, status.TextColor3 = result.Message or "Quest log updated", result.Success and Color3.fromRGB(110, 225, 155) or Color3.fromRGB(255, 105, 115)
	if result.Quests then quests = result.Quests end
	return result
end

local function render()
	for _, child in ipairs(list:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	local firstButton
	for order, quest in ipairs(quests) do
		local definition = config[quest.Id]
		if definition then
			local card = Instance.new("Frame")
			card.LayoutOrder, card.Size, card.BackgroundColor3, card.BorderSizePixel = order, UDim2.new(1, -6, 0, 94), Color3.fromRGB(31, 38, 57), 0
			round(card, 8)
			card.Parent = list
			local name = Instance.new("TextLabel")
			name.Position, name.Size, name.BackgroundTransparency = UDim2.fromOffset(12, 8), UDim2.new(1, -150, 0, 24), 1
			name.Text, name.TextColor3, name.TextXAlignment, name.Font, name.TextSize = definition.DisplayName, quest.Claimed and Color3.fromRGB(130, 145, 165) or Color3.fromRGB(235, 240, 255), Enum.TextXAlignment.Left, Enum.Font.GothamBold, 15
			name.Parent = card
			local detail = Instance.new("TextLabel")
			detail.Position, detail.Size, detail.BackgroundTransparency = UDim2.fromOffset(12, 34), UDim2.new(1, -150, 0, 50), 1
			detail.Text = string.format("%s\n%d / %d  •  +%d XP  •  +%d Gold", definition.Description, quest.Progress, quest.Goal, definition.RewardXP, definition.RewardGold)
			detail.TextColor3, detail.TextXAlignment, detail.TextYAlignment, detail.Font, detail.TextSize = Color3.fromRGB(170, 185, 210), Enum.TextXAlignment.Left, Enum.TextYAlignment.Top, Enum.Font.Gotham, 12
			detail.TextWrapped = true
			detail.Parent = card
			local claim = Instance.new("TextButton")
			claim.AnchorPoint, claim.Position, claim.Size = Vector2.new(1, 0.5), UDim2.new(1, -10, 0.5, 0), UDim2.fromOffset(120, 38)
			local complete = quest.Progress >= quest.Goal
			claim.BackgroundColor3 = quest.Claimed and Color3.fromRGB(52, 58, 70) or complete and Color3.fromRGB(80, 175, 115) or Color3.fromRGB(55, 65, 85)
			claim.BorderSizePixel, claim.Text = 0, quest.Claimed and "CLAIMED" or complete and "CLAIM" or "IN PROGRESS"
			claim.TextColor3, claim.Font, claim.TextSize, claim.Active = Color3.new(1, 1, 1), Enum.Font.GothamBold, 12, complete and not quest.Claimed
			round(claim, 7)
			claim.Parent = card
			if claim.Active and not firstButton then firstButton = claim end
			claim.Activated:Connect(function()
				if not claim.Active then return end
				local result = request("Claim", {QuestId = quest.Id})
				if result then render() end
			end)
		end
	end
	if panel.Visible then GuiService.SelectedObject = firstButton or close end
end

local function toggle()
	panel.Visible = not panel.Visible
	if panel.Visible then local result = request("GetState"); if result then render() end else GuiService.SelectedObject = nil end
end
open.Activated:Connect(toggle)
close.Activated:Connect(function() panel.Visible = false; GuiService.SelectedObject = nil end)
UserInputService.InputBegan:Connect(function(input, processed) if not processed and input.KeyCode == Enum.KeyCode.J then toggle() end end)
local function gamepad(actionName, inputState)
	if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	if actionName == "QuestToggle" then toggle(); return Enum.ContextActionResult.Sink end
	if actionName == "QuestClose" and panel.Visible then panel.Visible = false; GuiService.SelectedObject = nil; return Enum.ContextActionResult.Sink end
	if actionName == "QuestBlockCombat" and panel.Visible then return Enum.ContextActionResult.Sink end
	return Enum.ContextActionResult.Pass
end
ContextActionService:BindActionAtPriority("QuestToggle", gamepad, false, 3100, Enum.KeyCode.DPadUp)
ContextActionService:BindActionAtPriority("QuestClose", gamepad, false, 3100, Enum.KeyCode.ButtonB)
ContextActionService:BindActionAtPriority("QuestBlockCombat", gamepad, false, 3100, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2, Enum.KeyCode.ButtonL3, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
event.OnClientEvent:Connect(function(_, data)
	local definition = config[data.QuestId]
	if definition then status.Text = data.Complete and (definition.DisplayName .. " complete — claim your reward") or string.format("%s: %d/%d", definition.DisplayName, data.Progress, data.Goal) end
	if panel.Visible then local result = request("GetState"); if result then render() end end
end)
