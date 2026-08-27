local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local skillConfig = require(ReplicatedStorage.Shared.SkillTreeConfig)
local transformationConfig = require(ReplicatedStorage.Shared.TransformationConfig)
local skillRemote = ReplicatedStorage.Remotes:WaitForChild("SkillRemote")
local transformationRemote = ReplicatedStorage.Remotes:WaitForChild("TransformationRemote")

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.Parent = "AscensionUI", false, 128, player:WaitForChild("PlayerGui")

local function round(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, radius), object
end

local function button(text, position, color)
	local value = Instance.new("TextButton")
	value.Size, value.Position, value.Text = UDim2.fromOffset(124, 36), position, text
	value.BackgroundColor3, value.TextColor3, value.Font, value.TextSize = color, Color3.new(1, 1, 1), Enum.Font.GothamBold, 12
	value.BorderSizePixel, value.Parent = 0, gui
	round(value, 8)
	return value
end

local skillOpen = button("SKILLS [K]", UDim2.new(1, -525, 0, 14), Color3.fromRGB(75, 125, 180))
local formOpen = button("FORMS [T]", UDim2.new(1, -255, 0, 14), Color3.fromRGB(145, 80, 170))

local function makePanel(name, titleText)
	local panel = Instance.new("Frame")
	panel.Name, panel.Size, panel.Position = name, UDim2.fromOffset(470, 540), UDim2.new(1, -488, 0, 58)
	panel.BackgroundColor3, panel.BorderSizePixel, panel.Visible, panel.Parent = Color3.fromRGB(18, 24, 38), 0, false, gui
	round(panel, 12)
	local title = Instance.new("TextLabel")
	title.Size, title.Position, title.Text = UDim2.new(1, -60, 0, 42), UDim2.fromOffset(16, 8), titleText
	title.BackgroundTransparency, title.TextColor3, title.TextXAlignment = 1, Color3.fromRGB(120, 220, 255), Enum.TextXAlignment.Left
	title.Font, title.TextSize, title.Parent = Enum.Font.GothamBlack, 18, panel
	local close = Instance.new("TextButton")
	close.Size, close.Position, close.Text = UDim2.fromOffset(34, 34), UDim2.new(1, -44, 0, 10), "X"
	close.BackgroundColor3, close.TextColor3, close.Parent = Color3.fromRGB(185, 55, 70), Color3.new(1, 1, 1), panel
	round(close, 7)
	local status = Instance.new("TextLabel")
	status.Size, status.Position = UDim2.new(1, -32, 0, 42), UDim2.fromOffset(16, 52)
	status.BackgroundTransparency, status.TextColor3, status.TextWrapped = 1, Color3.fromRGB(185, 200, 220), true
	status.Font, status.TextSize, status.Parent = Enum.Font.Gotham, 13, panel
	local list = Instance.new("ScrollingFrame")
	list.Size, list.Position = UDim2.new(1, -32, 1, -112), UDim2.fromOffset(16, 100)
	list.BackgroundColor3, list.BorderSizePixel, list.AutomaticCanvasSize, list.CanvasSize = Color3.fromRGB(26, 34, 50), 0, Enum.AutomaticSize.Y, UDim2.new()
	list.ScrollBarThickness, list.Parent = 5, panel
	local layout = Instance.new("UIListLayout")
	layout.Padding, layout.Parent = UDim.new(0, 7), list
	local padding = Instance.new("UIPadding")
	padding.PaddingTop, padding.PaddingLeft, padding.PaddingRight, padding.Parent = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8), list
	close.Activated:Connect(function() panel.Visible = false end)
	return panel, status, list
end

local skillPanel, skillStatus, skillList = makePanel("SkillPanel", "ASCENDANT SKILL TREE")
local formPanel, formStatus, formList = makePanel("FormPanel", "ANIMAL TRANSFORMATIONS")

local function clear(list)
	for _, child in ipairs(list:GetChildren()) do if child:IsA("GuiButton") or child:IsA("TextLabel") then child:Destroy() end end
end

local function row(parent, text, color)
	local value = Instance.new("TextButton")
	value.Size, value.Text, value.TextXAlignment = UDim2.new(1, -4, 0, 48), text, Enum.TextXAlignment.Left
	value.BackgroundColor3, value.TextColor3, value.Font, value.TextSize = color or Color3.fromRGB(42, 54, 76), Color3.new(1, 1, 1), Enum.Font.GothamBold, 13
	value.BorderSizePixel, value.Parent = 0, parent
	local pad = Instance.new("UIPadding") pad.PaddingLeft, pad.Parent = UDim.new(0, 12), value
	round(value, 7)
	return value
end

local function renderSkills()
	local result = skillRemote:InvokeServer("GetState")
	if not result or not result.State then return end
	clear(skillList)
	local state = result.State
	skillStatus.Text = string.format("Skill Points: %d     Element Points: %d\nClick a node to purchase its next rank.", state.SkillPoints, state.ElementPoints)
	for _, id in ipairs(skillConfig.Order) do
		local definition, rank = skillConfig.Nodes[id], state.Ranks[id] or 0
		local value = row(skillList, string.format("%s  [%s]   Rank %d/%d", definition.DisplayName, definition.Tree, rank, definition.MaximumRank), definition.Tree == "Universal" and Color3.fromRGB(45, 65, 90) or Color3.fromRGB(65, 48, 85))
		value.Activated:Connect(function()
			local purchase = skillRemote:InvokeServer("Purchase", {SkillId = id})
			skillStatus.Text = purchase.Message or "Skill request complete"
			renderSkills()
		end)
	end
end

local function renderForms()
	local result = transformationRemote:InvokeServer("GetState")
	if not result or not result.State then return end
	clear(formList)
	local state = result.State
	formStatus.Text = state.Active ~= "" and ("Active Form: " .. state.Active .. "\nClick it again to return to normal.") or "Active Form: Ascendant\nForms change stats, aura, and combat identity."
	for _, id in ipairs(transformationConfig.Order) do
		local definition = transformationConfig.Forms[id]
		local unlocked = state.Unlocked[id]
		local value = row(formList, string.format("%s   •   Level %d%s\n%s", definition.DisplayName, definition.RequiredLevel, state.Active == id and "   ACTIVE" or "", table.concat(definition.Abilities, " / ")), unlocked and definition.Color:Lerp(Color3.fromRGB(28, 34, 48), 0.55) or Color3.fromRGB(45, 45, 50))
		value.AutoButtonColor = unlocked
		value.Activated:Connect(function()
			if not unlocked then formStatus.Text = "Reach level " .. definition.RequiredLevel .. " to unlock this form." return end
			local toggle = transformationRemote:InvokeServer("Toggle", {FormId = id})
			formStatus.Text = toggle.Message or "Transformation request complete"
			renderForms()
		end)
	end
end

local function toggle(panel, render)
	panel.Visible = not panel.Visible
	if panel.Visible then skillPanel.Visible = panel == skillPanel; formPanel.Visible = panel == formPanel; render() end
end

skillOpen.Activated:Connect(function() toggle(skillPanel, renderSkills) end)
formOpen.Activated:Connect(function() toggle(formPanel, renderForms) end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.K then toggle(skillPanel, renderSkills)
	elseif input.KeyCode == Enum.KeyCode.T then toggle(formPanel, renderForms) end
end)
