local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local gui = Instance.new("ScreenGui")
gui.Name = "AscendantMenuDock"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 500
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)

local dock = Instance.new("ScrollingFrame")
dock.Name = "Dock"
dock.BackgroundColor3 = Color3.fromRGB(17, 24, 36)
dock.BackgroundTransparency = 0.08
dock.BorderSizePixel = 0
dock.ScrollBarThickness = 2
dock.ScrollBarImageColor3 = Color3.fromRGB(75, 190, 255)
dock.ScrollingDirection = Enum.ScrollingDirection.X
dock.AutomaticCanvasSize = Enum.AutomaticSize.X
dock.CanvasSize = UDim2.new()
dock.ClipsDescendants = true
dock.Parent = gui
local corner = Instance.new("UICorner") corner.CornerRadius, corner.Parent = UDim.new(0, 11), dock
local stroke = Instance.new("UIStroke") stroke.Color, stroke.Transparency, stroke.Thickness, stroke.Parent = Color3.fromRGB(70, 185, 255), 0.25, 1.5, dock
local padding = Instance.new("UIPadding")
padding.PaddingLeft, padding.PaddingRight, padding.PaddingTop, padding.PaddingBottom, padding.Parent = UDim.new(0, 7), UDim.new(0, 7), UDim.new(0, 5), UDim.new(0, 5), dock
local layout = Instance.new("UIListLayout")
layout.FillDirection, layout.VerticalAlignment, layout.HorizontalAlignment, layout.Padding, layout.SortOrder, layout.Parent = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, Enum.HorizontalAlignment.Right, UDim.new(0, 6), Enum.SortOrder.LayoutOrder, dock

local menuGuiNames = {PowersUI = true, InventoryUI = true, QuestLog = true, EvolutionUI = true, AscensionUI = true, AdminControls = true, CombatSettings = true}
local menuDefinitions = {
	POWERS = {Order = 1, Label = "POWERS", Width = 70},
	SKILLS = {Order = 2, Label = "SKILLS", Width = 68},
	BAG = {Order = 3, Label = "BAG", Width = 58},
	QUEST = {Order = 4, Label = "QUESTS", Width = 72},
	FORMS = {Order = 5, Label = "FORMS", Width = 68},
	EVOLUTION = {Order = 6, Label = "EVOLVE", Width = 76},
	ADMIN = {Order = 7, Label = "ADMIN", Width = 68},
	SETTINGS = {Order = 8, Label = "SETTINGS", Width = 76},
}

local function updateLayout()
	local currentCamera = workspace.CurrentCamera
	local width = currentCamera and currentCamera.ViewportSize.X or 1280
	if width < 960 or UserInputService.TouchEnabled then
		-- Keep the system-menu clearance on the left, but size and anchor the actual
		-- menu to the right. The old full-width frame left hundreds of blank pixels
		-- after SETTINGS on iPad because its children were left-aligned.
		local availableWidth = math.max(240, width - 112)
		dock.AnchorPoint = Vector2.new(1, 0)
		dock.Position, dock.Size = UDim2.new(1, -8, 0, 4), UDim2.fromOffset(math.min(620, availableWidth), 48)
	else
		dock.AnchorPoint = Vector2.new(1, 0)
		dock.Position, dock.Size = UDim2.new(1, -8, 0, 4), UDim2.fromOffset(620, 44)
	end
end

local function closeOtherPanels(sourceName)
	for name in pairs(menuGuiNames) do
		if name ~= sourceName then
			local screen = playerGui:FindFirstChild(name)
			if screen then
				for _, child in ipairs(screen:GetChildren()) do
					if child:IsA("Frame") and (child.Name == "Panel" or string.find(child.Name, "Panel")) then child.Visible = false end
				end
			end
		end
	end
end

local function adopt(candidate)
	if not candidate:IsA("GuiButton") or candidate:IsDescendantOf(gui) then return end
	local source = candidate.Parent
	if not source or not source:IsA("ScreenGui") or not menuGuiNames[source.Name] then return end
	if candidate.Position.Y.Scale ~= 0 or candidate.Position.Y.Offset > 32 or candidate.Size.Y.Offset > 48 then return end
	local upper = string.upper((candidate.Text or "") .. " " .. candidate.Name)
	local definition
	for word, value in pairs(menuDefinitions) do if string.find(upper, word, 1, true) then definition = value break end end
	definition = definition or {Order = 99, Label = candidate.Text, Width = 88}
	candidate:SetAttribute("MenuSourceGui", source.Name)
	candidate.AnchorPoint = Vector2.zero
	candidate.Position = UDim2.new()
	candidate.Size = UDim2.fromOffset(definition.Width, 34)
	candidate.LayoutOrder = definition.Order
	candidate.Text = definition.Label
	candidate.ZIndex = 502
	candidate.TextScaled = false
	candidate.TextSize = 12
	candidate.Parent = dock
	candidate.Activated:Connect(function()
		task.defer(closeOtherPanels, candidate:GetAttribute("MenuSourceGui"))
	end)
end

for _, object in ipairs(playerGui:GetDescendants()) do adopt(object) end
playerGui.DescendantAdded:Connect(function(object) task.defer(adopt, object) end)
updateLayout()
if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayout) end
