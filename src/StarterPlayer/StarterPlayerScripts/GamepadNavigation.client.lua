local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local names = {MeleeUI = true, PowersUI = true, InventoryUI = true, QuestLog = true, EvolutionUI = true, AscensionUI = true, AdminControls = true, CombatSettings = true}
local panels = {}
local controller = false
local switching = false
local dock
local previousSelectionName

local function visible(object)
	local node = object
	while node and node ~= playerGui do
		if node:IsA("GuiObject") and not node.Visible then return false end
		if node:IsA("ScreenGui") and not node.Enabled then return false end
		node = node.Parent
	end
	return node == playerGui
end
local function focus(container)
	if not container or not container.Parent then return end
	local choices = {}
	for _, object in ipairs(container:GetDescendants()) do
		if (object:IsA("GuiButton") or object:IsA("TextBox")) and object.Selectable and visible(object) then table.insert(choices, object) end
	end
	table.sort(choices, function(a, b)
		if math.abs(a.AbsolutePosition.Y - b.AbsolutePosition.Y) > 4 then return a.AbsolutePosition.Y < b.AbsolutePosition.Y end
		return a.AbsolutePosition.X < b.AbsolutePosition.X
	end)
	GuiService.SelectedObject = choices[1]
end
local function currentPanel()
	for panel in pairs(panels) do if panel.Parent and visible(panel) then return panel end end
end
local function watch(object)
	if object:IsA("TextBox") then object.Selectable = true end
	if object.Name == "Dock" and object.Parent and object.Parent.Name == "AscendantMenuDock" then dock = object end
	if not object:IsA("GuiObject") or not string.find(object.Name, "Panel", 1, true) then return end
	local screen = object.Parent
	if not screen or not screen:IsA("ScreenGui") or not names[screen.Name] or panels[object] then return end
	panels[object] = true
	object:GetPropertyChangedSignal("Visible"):Connect(function()
		if switching then return end
		if object.Visible then
			switching = true
			for other in pairs(panels) do if other ~= object and other.Parent then other.Visible = false end end
			switching = false
			-- Release a held block when a menu takes control.
			game:GetService("ReplicatedStorage").Remotes.CombatRemote:FireServer("Block", false)
			if controller then task.defer(focus, object) end
		elseif controller then task.defer(focus, dock) else GuiService.SelectedObject = nil end
	end)
	object.Destroying:Connect(function() panels[object] = nil end)
end
for _, object in ipairs(playerGui:GetDescendants()) do watch(object) end
playerGui.DescendantAdded:Connect(function(object) task.defer(watch, object) end)

local hud = Instance.new("ScreenGui")
hud.Name, hud.ResetOnSpawn, hud.DisplayOrder, hud.Parent = "ControllerHints", false, 510, playerGui
local hint = Instance.new("TextLabel")
hint.AnchorPoint, hint.Position, hint.Size = Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -5), UDim2.new(0.92, 0, 0, 38)
hint.BackgroundColor3, hint.BackgroundTransparency, hint.TextColor3 = Color3.fromRGB(18, 25, 38), 0.2, Color3.fromRGB(230, 240, 255)
hint.Font, hint.TextSize, hint.TextWrapped, hint.Parent = Enum.Font.GothamMedium, 12, true, hud
local function hints()
	hud.Enabled = controller
	hint.Text = GuiService.SelectedObject and "A select  |  B back  |  D-pad / left stick navigate  |  BACK exit menus"
		or "BACK menus | X melee | Y sword art | RT / LT spells | LB / RB select | A jump | B dodge | LS travel | RS ultimate\nD-pad: UP hold block | RIGHT ranged weapon | LEFT health | DOWN mana"
end
local function inputChanged(input)
	controller = string.find(input.Name, "Gamepad", 1, true) ~= nil
	if controller and currentPanel() then focus(currentPanel()) end
	hints()
end
UserInputService.LastInputTypeChanged:Connect(inputChanged)
UserInputService.GamepadConnected:Connect(function() controller = true; hints() end)
UserInputService.GamepadDisconnected:Connect(function()
	game:GetService("ReplicatedStorage").Remotes.CombatRemote:FireServer("Block", false)
	controller = #UserInputService:GetConnectedGamepads() > 0
	if not controller then GuiService.SelectedObject = nil end
	hints()
end)
inputChanged(UserInputService:GetLastInputType())
GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
	hints()
	local selected = GuiService.SelectedObject
	if selected then
		previousSelectionName = selected.Name
		local parent = selected.Parent
		while parent and parent ~= playerGui do
			if parent:IsA("ScrollingFrame") then
				local delta = selected.AbsolutePosition - parent.AbsolutePosition
				local x, y = parent.CanvasPosition.X, parent.CanvasPosition.Y
				if delta.Y < 0 then y += delta.Y elseif delta.Y + selected.AbsoluteSize.Y > parent.AbsoluteWindowSize.Y then y += delta.Y + selected.AbsoluteSize.Y - parent.AbsoluteWindowSize.Y end
				if delta.X < 0 then x += delta.X elseif delta.X + selected.AbsoluteSize.X > parent.AbsoluteWindowSize.X then x += delta.X + selected.AbsoluteSize.X - parent.AbsoluteWindowSize.X end
				parent.CanvasPosition = Vector2.new(math.max(0, x), math.max(0, y))
			end
			parent = parent.Parent
		end
	elseif controller and currentPanel() then
		task.defer(function()
			if GuiService.SelectedObject then return end
			local panel = currentPanel()
			local replacement = panel and previousSelectionName and panel:FindFirstChild(previousSelectionName, true)
			if replacement and replacement:IsA("GuiObject") and replacement.Selectable and visible(replacement) then GuiService.SelectedObject = replacement
			else focus(panel) end
		end)
	end
end)

ContextActionService:BindActionAtPriority("ControllerMenus", function(_, state)
	if state ~= Enum.UserInputState.Begin or GuiService.MenuIsOpen then return Enum.ContextActionResult.Pass end
	controller = true
	if currentPanel() or GuiService.SelectedObject then
		switching = true
		for panel in pairs(panels) do if panel.Parent then panel.Visible = false end end
		switching = false
		GuiService.SelectedObject = nil
	else focus(dock) end
	hints()
	return Enum.ContextActionResult.Sink
end, false, 5000, Enum.KeyCode.ButtonSelect)
ContextActionService:BindActionAtPriority("ControllerBack", function(_, state)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	local panel = currentPanel()
	if panel then panel.Visible = false; return Enum.ContextActionResult.Sink end
	if GuiService.SelectedObject then GuiService.SelectedObject = nil; return Enum.ContextActionResult.Sink end
	return Enum.ContextActionResult.Pass
end, false, 5000, Enum.KeyCode.ButtonB)

GuiService.GuiNavigationEnabled = true

ContextActionService:BindActionAtPriority("ControllerTextEntry", function(_, state)
	local selected = GuiService.SelectedObject
	if state == Enum.UserInputState.Begin and selected and selected:IsA("TextBox") and visible(selected) then
		selected:CaptureFocus()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, 5000, Enum.KeyCode.ButtonA)
