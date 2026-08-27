local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local skillConfig = require(ReplicatedStorage.Shared.SkillTreeConfig)
local transformationConfig = require(ReplicatedStorage.Shared.TransformationConfig)
local skillRemote = ReplicatedStorage.Remotes:WaitForChild("SkillRemote")
local transformationRemote = ReplicatedStorage.Remotes:WaitForChild("TransformationRemote")
local movementRemote = ReplicatedStorage.Remotes:WaitForChild("MovementRemote")
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.Parent = "AscensionUI", false, 128, player:WaitForChild("PlayerGui")

local treeColors = {Universal = Color3.fromRGB(75, 145, 205), Fire = Color3.fromRGB(220, 82, 42), Ice = Color3.fromRGB(85, 185, 230), Lightning = Color3.fromRGB(215, 185, 55), Earth = Color3.fromRGB(105, 155, 78), Gravity = Color3.fromRGB(145, 80, 205)}
local function round(object, radius) local corner = Instance.new("UICorner") corner.CornerRadius, corner.Parent = UDim.new(0, radius), object end
local function styleButton(button, color)
	button.BackgroundColor3, button.BorderSizePixel, button.TextColor3 = color, 0, Color3.new(1, 1, 1)
	button.Font, button.TextSize = Enum.Font.GothamBold, 12
	round(button, 7)
end
local function openButton(text, position, color)
	local value = Instance.new("TextButton") value.Size, value.Position, value.Text, value.Parent = UDim2.fromOffset(124, 36), position, text, gui styleButton(value, color) return value
end
local skillOpen = openButton("SKILLS [K]", UDim2.new(1, -525, 0, 14), Color3.fromRGB(75, 125, 180))
local formOpen = openButton("FORMS [T]", UDim2.new(1, -255, 0, 14), Color3.fromRGB(145, 80, 170))

local function makePanel(name, titleText)
	local panel = Instance.new("Frame")
	panel.Name, panel.AnchorPoint, panel.Position, panel.Size = name, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.53), UDim2.fromOffset(760, 590)
	panel.BackgroundColor3, panel.BorderSizePixel, panel.Visible, panel.Parent = Color3.fromRGB(17, 23, 35), 0, false, gui
	round(panel, 12)
	local constraint = Instance.new("UISizeConstraint") constraint.MinSize, constraint.MaxSize, constraint.Parent = Vector2.new(560, 480), Vector2.new(760, 590), panel
	local title = Instance.new("TextLabel")
	title.Position, title.Size, title.BackgroundTransparency, title.Text = UDim2.fromOffset(18, 9), UDim2.new(1, -75, 0, 36), 1, titleText
	title.TextColor3, title.TextXAlignment, title.Font, title.TextSize, title.Parent = Color3.fromRGB(115, 220, 255), Enum.TextXAlignment.Left, Enum.Font.GothamBlack, 19, panel
	local close = Instance.new("TextButton") close.Position, close.Size, close.Text, close.Parent = UDim2.new(1, -48, 0, 9), UDim2.fromOffset(36, 36), "X", panel styleButton(close, Color3.fromRGB(188, 58, 73))
	close.Activated:Connect(function() panel.Visible = false end)
	return panel
end

local skillPanel = makePanel("SkillPanel", "ASCENDANT SKILL TREE")
local skillStatus = Instance.new("TextLabel")
skillStatus.Position, skillStatus.Size, skillStatus.BackgroundTransparency = UDim2.fromOffset(18, 48), UDim2.new(1, -36, 0, 32), 1
skillStatus.TextColor3, skillStatus.Font, skillStatus.TextSize, skillStatus.TextXAlignment, skillStatus.Parent = Color3.fromRGB(185, 200, 220), Enum.Font.Gotham, 12, Enum.TextXAlignment.Left, skillPanel
local tabs = Instance.new("Frame") tabs.Position, tabs.Size, tabs.BackgroundTransparency, tabs.Parent = UDim2.fromOffset(18, 82), UDim2.new(1, -36, 0, 38), 1, skillPanel
local tabLayout = Instance.new("UIListLayout") tabLayout.FillDirection, tabLayout.Padding, tabLayout.Parent = Enum.FillDirection.Horizontal, UDim.new(0, 6), tabs
local treeCanvas = Instance.new("ScrollingFrame")
treeCanvas.Position, treeCanvas.Size, treeCanvas.BackgroundColor3, treeCanvas.BorderSizePixel = UDim2.fromOffset(18, 128), UDim2.new(1, -36, 1, -146), Color3.fromRGB(24, 31, 47), 0
treeCanvas.CanvasSize, treeCanvas.ScrollBarThickness, treeCanvas.Parent = UDim2.fromOffset(704, 430), 5, skillPanel
round(treeCanvas, 9)

local selectedTree = "Universal"
local renderSkills
local function nodePosition(definition)
	return Vector2.new(32 + (definition.Column - 1) * 220, 28 + (definition.Tier - 1) * 125)
end
local function connector(parentDefinition, childDefinition, color)
	local a, b = nodePosition(parentDefinition), nodePosition(childDefinition)
	local x1, y1, x2, y2 = a.X + 90, a.Y + 72, b.X + 90, b.Y
	local middle = (y1 + y2) / 2
	for _, segment in ipairs({{x1 - 2, y1, 4, middle - y1}, {math.min(x1, x2), middle - 2, math.abs(x2 - x1) + 4, 4}, {x2 - 2, middle, 4, y2 - middle}}) do
		local line = Instance.new("Frame") line.Position, line.Size, line.BorderSizePixel, line.BackgroundColor3, line.ZIndex, line.Parent = UDim2.fromOffset(segment[1], segment[2]), UDim2.fromOffset(math.max(2, segment[3]), math.max(2, segment[4])), 0, color, 1, treeCanvas
	end
end

for _, tree in ipairs(skillConfig.Trees) do
	local tab = Instance.new("TextButton") tab.Name, tab.Size, tab.Text, tab.Parent = tree, UDim2.new(1 / #skillConfig.Trees, -5, 1, 0), string.upper(tree), tabs styleButton(tab, treeColors[tree])
	tab.Activated:Connect(function() selectedTree = tree; renderSkills() end)
end

renderSkills = function()
	local result = skillRemote:InvokeServer("GetState")
	if not result or not result.State then return end
	local state = result.State
	skillStatus.Text = string.format("Skill Points: %d     Element Points: %d     Tree: %s", state.SkillPoints, state.ElementPoints, selectedTree)
	for _, child in ipairs(treeCanvas:GetChildren()) do child:Destroy() end
	for _, id in ipairs(skillConfig.Order) do
		local definition = skillConfig.Nodes[id]
		if definition.Tree == selectedTree then
			for _, requirement in ipairs(definition.Prerequisites or {}) do
				local parentDefinition = skillConfig.Nodes[requirement.Id]
				if parentDefinition and parentDefinition.Tree == selectedTree then connector(parentDefinition, definition, treeColors[selectedTree]:Lerp(Color3.new(1, 1, 1), 0.25)) end
			end
		end
	end
	for _, id in ipairs(skillConfig.Order) do
		local definition, rank = skillConfig.Nodes[id], state.Ranks[id] or 0
		if definition.Tree == selectedTree then
			local nodeState = state.Nodes[id]
			local available, maximum = nodeState and nodeState.Available, rank >= definition.MaximumRank
			local value = Instance.new("TextButton")
			local position = nodePosition(definition)
			value.Name, value.Position, value.Size, value.ZIndex = id, UDim2.fromOffset(position.X, position.Y), UDim2.fromOffset(180, 72), 3
			value.TextWrapped, value.TextXAlignment, value.TextYAlignment = true, Enum.TextXAlignment.Left, Enum.TextYAlignment.Center
			local stateText = maximum and "MAXED" or available and "AVAILABLE" or (nodeState and nodeState.Reason or "LOCKED")
			value.Text = string.format("  %s  %d/%d\n  %s\n  %s", definition.DisplayName, rank, definition.MaximumRank, stateText, definition.Description or "")
			value.Font, value.TextSize, value.TextColor3 = Enum.Font.GothamBold, 11, Color3.new(1, 1, 1)
			value.BackgroundColor3 = maximum and Color3.fromRGB(45, 145, 105) or available and treeColors[selectedTree]:Lerp(Color3.fromRGB(28, 36, 52), 0.45) or Color3.fromRGB(43, 46, 57)
			value.BorderSizePixel, value.AutoButtonColor, value.Parent = 0, available and not maximum, treeCanvas
			round(value, 9)
			value.Activated:Connect(function()
				if maximum then return end
				local purchase = skillRemote:InvokeServer("Purchase", {SkillId = id})
				skillStatus.Text = purchase.Message or "Skill request complete"
				renderSkills()
			end)
		end
	end
end

local formPanel = makePanel("FormPanel", "ANIMAL TRANSFORMATIONS")
local formStatus = Instance.new("TextLabel")
formStatus.Position, formStatus.Size, formStatus.BackgroundTransparency = UDim2.fromOffset(18, 50), UDim2.new(1, -36, 0, 42), 1
formStatus.TextColor3, formStatus.TextWrapped, formStatus.Font, formStatus.TextSize, formStatus.Parent = Color3.fromRGB(185, 200, 220), true, Enum.Font.Gotham, 12, formPanel
local formList = Instance.new("ScrollingFrame")
formList.Position, formList.Size, formList.BackgroundColor3, formList.BorderSizePixel = UDim2.fromOffset(18, 100), UDim2.new(1, -36, 1, -170), Color3.fromRGB(24, 31, 47), 0
formList.AutomaticCanvasSize, formList.CanvasSize, formList.ScrollBarThickness, formList.Parent = Enum.AutomaticSize.Y, UDim2.new(), 5, formPanel
local formLayout = Instance.new("UIListLayout") formLayout.Padding, formLayout.Parent = UDim.new(0, 8), formList
local formPadding = Instance.new("UIPadding") formPadding.PaddingTop, formPadding.PaddingLeft, formPadding.PaddingRight, formPadding.Parent = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8), formList
local eagleFlightButton = Instance.new("TextButton")
eagleFlightButton.Position, eagleFlightButton.Size, eagleFlightButton.Text, eagleFlightButton.Visible, eagleFlightButton.Parent = UDim2.new(0, 18, 1, -58), UDim2.new(1, -36, 0, 42), "EAGLE SKY FLIGHT  [G]", false, formPanel
styleButton(eagleFlightButton, Color3.fromRGB(165, 115, 50))
eagleFlightButton.Activated:Connect(function() movementRemote:FireServer("EagleFlight") end)
local flightHudButton = Instance.new("TextButton")
flightHudButton.Name, flightHudButton.AnchorPoint = "EagleFlightControl", Vector2.new(1, 1)
flightHudButton.Position, flightHudButton.Size = UDim2.new(1, -24, 1, -112), UDim2.fromOffset(158, 46)
flightHudButton.Visible, flightHudButton.Parent = false, gui
styleButton(flightHudButton, Color3.fromRGB(164, 111, 43))
flightHudButton.Activated:Connect(function() movementRemote:FireServer("EagleFlight") end)
local function updateFlightControl()
	local isEagle = player:GetAttribute("ActiveTransformation") == "Eagle"
	local flying = player:GetAttribute("EagleFlightActive") == true
	flightHudButton.Visible = isEagle
	flightHudButton.Text = flying and "LAND  [G]" or "TAKE FLIGHT  [G]"
	flightHudButton.BackgroundColor3 = flying and Color3.fromRGB(50, 155, 190) or Color3.fromRGB(164, 111, 43)
	eagleFlightButton.Text = flying and "LAND EAGLE  [G]" or "EAGLE SKY FLIGHT  [G]"
end
player:GetAttributeChangedSignal("ActiveTransformation"):Connect(updateFlightControl)
player:GetAttributeChangedSignal("EagleFlightActive"):Connect(updateFlightControl)
updateFlightControl()
local function renderForms()
	local result = transformationRemote:InvokeServer("GetState")
	if not result or not result.State then return end
	for _, child in ipairs(formList:GetChildren()) do if child:IsA("GuiButton") then child:Destroy() end end
	local state = result.State
	eagleFlightButton.Visible = state.Active == "Eagle"
	formStatus.Text = state.Active ~= "" and ("Active: " .. state.Active .. "  •  click again to return") or "Active: Ascendant  •  choose an unlocked spirit form"
	for _, id in ipairs(transformationConfig.Order) do
		local definition, unlocked = transformationConfig.Forms[id], state.Unlocked[id]
		local value = Instance.new("TextButton")
		value.Size, value.TextWrapped, value.TextXAlignment = UDim2.new(1, -4, 0, 72), true, Enum.TextXAlignment.Left
		value.Text = string.format("  %s  •  Level %d%s\n  %s\n  Speed %.2fx  Defense +%d", definition.DisplayName, definition.RequiredLevel, state.Active == id and "  [ACTIVE]" or "", table.concat(definition.Abilities, " / "), definition.StatModifiers.MoveSpeed or 1, definition.StatModifiers.Defense or 0)
		styleButton(value, unlocked and definition.Color:Lerp(Color3.fromRGB(28, 35, 50), 0.62) or Color3.fromRGB(44, 46, 55))
		value.TextColor3, value.AutoButtonColor, value.Parent = unlocked and Color3.new(1, 1, 1) or Color3.fromRGB(130, 135, 150), unlocked, formList
		value.Activated:Connect(function()
			if not unlocked then formStatus.Text = "Locked until level " .. definition.RequiredLevel; return end
			local response = transformationRemote:InvokeServer("Toggle", {FormId = id})
			formStatus.Text = response.Message or "Transformation updated"
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
	if input.KeyCode == Enum.KeyCode.K then
		toggle(skillPanel, renderSkills)
	elseif input.KeyCode == Enum.KeyCode.T then
		toggle(formPanel, renderForms)
	elseif input.KeyCode == Enum.KeyCode.G and player:GetAttribute("ActiveTransformation") == "Eagle" then
		movementRemote:FireServer("EagleFlight")
	end
end)
