local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage.Shared.MeleeConfig)
local Skills = require(ReplicatedStorage.Shared.SkillTreeConfig)
local remote = ReplicatedStorage.Remotes:WaitForChild("CombatRemote")
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder, gui.Parent = "MeleeUI", false, 128, player:WaitForChild("PlayerGui")
local function button(parent, text, position, size)
	local value = Instance.new("TextButton")
	value.Text, value.Position, value.Size, value.Parent = text, position, size, parent
	value.BackgroundColor3, value.TextColor3, value.BorderSizePixel = Color3.fromRGB(115, 65, 44), Color3.new(1, 1, 1), 0
	value.Font, value.TextSize, value.TextWrapped = Enum.Font.GothamBold, 14, true
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 8), value
	return value
end
local open = button(gui, "MELEE [M]", UDim2.fromOffset(500, 14), UDim2.fromOffset(100, 36))
local panel = Instance.new("Frame")
panel.Name, panel.AnchorPoint, panel.Position, panel.Size = "MeleePanel", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.53), UDim2.fromOffset(600, 550)
panel.BackgroundColor3, panel.Visible, panel.Parent = Color3.fromRGB(20, 26, 39), false, gui
local close = button(panel, "X", UDim2.new(1, -48, 0, 12), UDim2.fromOffset(36, 36))
local title = Instance.new("TextLabel")
title.Position, title.Size, title.BackgroundTransparency, title.Parent = UDim2.fromOffset(18, 12), UDim2.new(1, -85, 0, 36), 1, panel
title.Text, title.Font, title.TextSize, title.TextColor3 = "DEFAULT ATTACKS & SWORD ARTS", Enum.Font.GothamBlack, 20, Color3.fromRGB(255, 195, 115)
local status = Instance.new("TextLabel")
status.Position, status.Size, status.BackgroundTransparency, status.Parent = UDim2.fromOffset(18, 58), UDim2.new(1, -36, 0, 95), 1, panel
status.TextColor3, status.TextSize, status.Font, status.TextWrapped = Color3.fromRGB(220, 230, 245), 14, Enum.Font.Gotham, true
local list = Instance.new("ScrollingFrame")
list.Position, list.Size, list.BackgroundTransparency, list.Parent = UDim2.fromOffset(18, 162), UDim2.new(1, -36, 1, -180), 1, panel
list.AutomaticCanvasSize, list.CanvasSize, list.ScrollBarThickness = Enum.AutomaticSize.Y, UDim2.new(), 5
local layout = Instance.new("UIListLayout")
layout.Padding, layout.SortOrder, layout.Parent = UDim.new(0, 8), Enum.SortOrder.LayoutOrder, list
local selectedMove = "Chain"
local function render()
	local xp = player:GetAttribute("MeleeMasteryXP") or 0
	local rank = math.min(Config.Mastery.MaximumRank, math.floor(xp / Config.Mastery.XPPerRank))
	status.Text = string.format("Melee mastery %d/%d | %d XP | +%.0f%% damage\nClick / gamepad X / ATTACK: four-hit combo. Fourth hit releases a finisher.\nEarn mastery by hitting live enemies. Gamepad Y: selected sword art. Spend level-up skill points below.", rank, Config.Mastery.MaximumRank, xp, rank * Config.Mastery.DamagePerRank * 100)
	for _, object in ipairs(list:GetChildren()) do if object:IsA("GuiButton") then object:Destroy() end end
	local skills = player:FindFirstChild("Skills")
	for index, id in ipairs(Config.Order) do
		local move = Config.Moves[id]
		local skill = move.Skill and skills and skills:FindFirstChild(move.Skill)
		local unlocked = player:GetAttribute("AdminAllPowersUnlocked") or ((not move.Skill or (skill and skill.Value > 0)) and (player:GetAttribute("Level") or 1) >= move.RequiredLevel)
		local chainRank = Config.GetChainRank(player:GetAttribute("ChainMasteryXP"), player:GetAttribute("Level"))
		local description = move.Description
		if id == "Chain" then description = string.format("Rank %d/%d | %d/%d XP | %d targets | +%d%% damage. Next rank: LV %d / %d XP", chainRank, Config.Chain.MaximumRank, player:GetAttribute("ChainMasteryXP") or 0, Config.Chain.MaximumRank * Config.Chain.XPPerRank, Config.Chain.BaseTargets + chainRank, chainRank * Config.Chain.DamagePerRank * 100, math.min(Config.Chain.MaximumRank, chainRank + 1) * Config.Chain.LevelsPerRank + 1, math.min(Config.Chain.MaximumRank, chainRank + 1) * Config.Chain.XPPerRank) end
		local card = button(list, string.format("%s [%s] | LV %d | %d stamina | %.1fs cooldown\n%s\n%s", move.DisplayName, move.Key, move.RequiredLevel, move.Stamina, move.Cooldown, description, unlocked and ("READY - click to select for gamepad Y" .. (selectedMove == id and " [SELECTED]" or "")) or ("Requires " .. (move.Skill and Skills.Nodes[move.Skill].DisplayName or "player level " .. move.RequiredLevel))), UDim2.new(), UDim2.new(1, -8, 0, 105))
		card.Name = id
		card.LayoutOrder, card.AutoButtonColor = index, unlocked == true
		card.Activated:Connect(function()
			if unlocked then selectedMove = id; render() else status.Text = "Requires level " .. move.RequiredLevel .. " and " .. (move.Skill and Skills.Nodes[move.Skill].DisplayName or "player level " .. move.RequiredLevel) end
		end)
	end
	for index, id in ipairs(Skills.Order) do
		local definition = Skills.Nodes[id]
		if definition.Tree ~= "Melee" then continue end
		local value = skills and skills:FindFirstChild(id)
		local rankValue = value and value.Value or 0
		local card = button(list, string.format("%s %d/%d | LV %d | %d skill point(s)\n%s", definition.DisplayName, rankValue, definition.MaximumRank, definition.RequiredLevel, definition.Cost, definition.Description), UDim2.new(), UDim2.new(1, -8, 0, 74))
		card.Name = id
		card.LayoutOrder = 10 + index
		card.Activated:Connect(function()
			local ok, result = pcall(function() return ReplicatedStorage.Remotes.SkillRemote:InvokeServer("Purchase", {SkillId = id}) end)
			render()
			status.Text = ok and result and result.Message or "Skill service unavailable"
		end)
	end
end
open.Activated:Connect(function() panel.Visible = not panel.Visible; if panel.Visible then render() end end)
close.Activated:Connect(function() panel.Visible = false end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.M then panel.Visible = not panel.Visible; if panel.Visible then render() end end
end)
local function menusOpen()
	if GuiService.SelectedObject and GuiService.SelectedObject:GetAttribute("MenuSourceGui") then return true end
	if GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() then return true end
	for _, screen in ipairs(player.PlayerGui:GetChildren()) do
		if screen:IsA("ScreenGui") and screen.Enabled then
			for _, object in ipairs(screen:GetChildren()) do
				if object:IsA("GuiObject") and object.Visible and string.find(object.Name, "Panel", 1, true) then return true end
			end
		end
	end
	return false
end
for index, id in ipairs(Config.Order) do
	local move = Config.Moves[id]
	
	ContextActionService:BindActionAtPriority("Sword" .. id, function(_, state)
		if state ~= Enum.UserInputState.Begin or menusOpen() then return Enum.ContextActionResult.Pass end
		remote:FireServer("SwordMove", id)
		return Enum.ContextActionResult.Sink
	end, true, 2500, Enum.KeyCode[move.Key])
	ContextActionService:SetTitle("Sword" .. id, move.Key .. ": " .. move.DisplayName)
	ContextActionService:SetPosition("Sword" .. id, UDim2.new(1, -335 + (index - 1) * 75, 1, -260))
end
ContextActionService:BindActionAtPriority("SelectedSwordArt", function(_, state)
	if state ~= Enum.UserInputState.Begin or menusOpen() then return Enum.ContextActionResult.Pass end
	remote:FireServer("SwordMove", selectedMove)
	return Enum.ContextActionResult.Sink
end, false, 2500, Enum.KeyCode.ButtonY)
for _, attribute in ipairs({"Level", "SkillPoints", "MeleeMasteryXP", "ChainMasteryXP", "AdminAllPowersUnlocked"}) do
	player:GetAttributeChangedSignal(attribute):Connect(function() if panel.Visible then render() end end)
end
local scale = Instance.new("UIScale")
scale.Parent = panel
local function resize()
	local camera = workspace.CurrentCamera
	if camera then scale.Scale = math.min(1, (camera.ViewportSize.X - 24) / 600, (camera.ViewportSize.Y - 90) / 550) end
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
resize()
