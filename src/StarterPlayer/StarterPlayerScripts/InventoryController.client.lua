local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemConfig"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local inventoryRemote = remotes:WaitForChild("InventoryRemote")
local inventoryEvent = remotes:WaitForChild("InventoryEvent")
local storeRemote = remotes:WaitForChild("StoreRemote")

local state = {Items = {}, Equipment = {}, Capacity = config.Capacity, Used = 0}
local selectedItem
local currentTab = "Inventory"
local filter = "All"
local slotFilter
local busy = false
local symbols = {Weapon = "⚔", Armor = "◆", Artifact = "✦", Consumable = "+", Material = "◇"}
local categoryColors = {Weapon = Color3.fromRGB(90, 170, 255), Armor = Color3.fromRGB(150, 175, 205), Artifact = Color3.fromRGB(190, 100, 255), Consumable = Color3.fromRGB(80, 220, 145), Material = Color3.fromRGB(255, 185, 70)}

local function round(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function styleButton(button, color)
	button.BackgroundColor3 = color or Color3.fromRGB(42, 52, 73)
	button.BorderSizePixel = 0
	button.TextColor3 = Color3.fromRGB(240, 245, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	round(button, 7)
end

local function itemGlyph(definition)
	if definition.IconGlyph then return definition.IconGlyph end
	if definition.Consumable then return definition.Consumable.Kind == "Health" and "HP" or definition.Consumable.Kind == "MP" and "MP" or "BUF" end
	if definition.WeaponKind then return definition.WeaponKind == "Rifle" and "RFL" or definition.WeaponKind == "Bow" and "BOW" or "GUN" end
	if definition.WeaponType then
		return ({Sword = "SWD", Katana = "KTN", Greatsword = "GS", Spear = "SPR", Hammer = "HMR", Staff = "STF"})[definition.WeaponType] or "WPN"
	end
	if definition.EquipSlot then return string.upper(string.sub(definition.EquipSlot, 1, 3)) end
	if string.find(definition.DisplayName, "Core", 1, true) then return "CORE" end
	if string.find(definition.DisplayName, "Scale", 1, true) then return "SCL" end
	if string.find(definition.DisplayName, "Fang", 1, true) then return "FNG" end
	if string.find(definition.DisplayName, "Claw", 1, true) then return "CLW" end
	return ({Weapon = "WPN", Armor = "ARM", Artifact = "ART", Consumable = "USE", Material = "MAT"})[definition.Category] or "ITM"
end

local gui = Instance.new("ScreenGui")
gui.Name = "InventoryUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 120
gui.Parent = player:WaitForChild("PlayerGui")

local openButton = Instance.new("TextButton")
openButton.AnchorPoint = Vector2.new(1, 0)
openButton.Position = UDim2.new(1, -210, 0, 14)
openButton.Size = UDim2.fromOffset(112, 36)
openButton.Text = "GEAR [B]"
styleButton(openButton, Color3.fromRGB(70, 125, 190))
openButton.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "InventoryPanel"
panel.AnchorPoint = Vector2.new(1, 0.5)
panel.Position = UDim2.new(1, -18, 0.55, 0)
panel.Size = UDim2.new(0.68, 0, 0.84, 0)
panel.BackgroundColor3 = Color3.fromRGB(17, 22, 34)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
round(panel, 13)
local constraint = Instance.new("UISizeConstraint")
constraint.MinSize, constraint.MaxSize = Vector2.new(560, 560), Vector2.new(760, 700)
constraint.Parent = panel
local responsiveScale = Instance.new("UIScale")
responsiveScale.Parent = panel
local function updateResponsiveScale()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	responsiveScale.Scale = math.clamp(math.min(viewport.X / 620, viewport.Y / 620), 0.55, 1)
end
updateResponsiveScale()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale) end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateResponsiveScale)

local header = Instance.new("TextLabel")
header.Position = UDim2.fromOffset(18, 10)
header.Size = UDim2.new(1, -70, 0, 34)
header.BackgroundTransparency = 1
header.Text = "GEAR, STATS & INVENTORY"
header.TextColor3 = Color3.fromRGB(110, 205, 255)
header.TextXAlignment = Enum.TextXAlignment.Left
header.Font = Enum.Font.GothamBlack
header.TextSize = 21
header.Parent = panel

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -10, 0, 9)
close.Size = UDim2.fromOffset(34, 34)
close.Text = "X"
styleButton(close, Color3.fromRGB(190, 60, 75))
close.Parent = panel

local tabs = Instance.new("Frame")
tabs.Position = UDim2.fromOffset(16, 50)
tabs.Size = UDim2.new(1, -32, 0, 38)
tabs.BackgroundTransparency = 1
tabs.Parent = panel
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 7)
tabLayout.Parent = tabs
local tabButtons = {}

local search = Instance.new("TextBox")
search.Position = UDim2.fromOffset(16, 96)
search.Size = UDim2.new(0.46, -20, 0, 36)
search.BackgroundColor3 = Color3.fromRGB(31, 39, 57)
search.BorderSizePixel = 0
search.PlaceholderText = "Search items..."
search.Text = ""
search.TextColor3 = Color3.new(1, 1, 1)
search.PlaceholderColor3 = Color3.fromRGB(145, 158, 180)
search.Font = Enum.Font.Gotham
search.TextSize = 14
search.ClearTextOnFocus = false
round(search, 7)
search.Parent = panel

local capacity = Instance.new("TextLabel")
capacity.Position = UDim2.new(0.46, 0, 0, 96)
capacity.Size = UDim2.new(0.24, 0, 0, 36)
capacity.BackgroundTransparency = 1
capacity.TextColor3 = Color3.fromRGB(175, 190, 215)
capacity.Font = Enum.Font.GothamBold
capacity.TextSize = 13
capacity.Parent = panel

local filterButton = Instance.new("TextButton")
filterButton.AnchorPoint = Vector2.new(1, 0)
filterButton.Position = UDim2.new(1, -16, 0, 96)
filterButton.Size = UDim2.new(0.27, 0, 0, 36)
filterButton.Text = "FILTER: ALL"
styleButton(filterButton)
filterButton.Parent = panel

local storeCategoryBar = Instance.new("Frame")
storeCategoryBar.Position = UDim2.fromOffset(16, 138)
storeCategoryBar.Size = UDim2.new(1, -32, 0, 32)
storeCategoryBar.BackgroundTransparency = 1
storeCategoryBar.Visible = false
storeCategoryBar.Parent = panel
local storeCategoryLayout = Instance.new("UIListLayout")
storeCategoryLayout.FillDirection = Enum.FillDirection.Horizontal
storeCategoryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
storeCategoryLayout.Padding = UDim.new(0, 5)
storeCategoryLayout.Parent = storeCategoryBar
local storeCategoryButtons = {}
local storeCategories = {
	{Label = "ALL", Filter = "All"},
	{Label = "SWORDS", Filter = "Weapon"},
	{Label = "RANGED", Filter = "Ranged"},
	{Label = "ARMOR", Filter = "Armor"},
	{Label = "POTIONS", Filter = "Consumable"},
	{Label = "MATERIALS", Filter = "Material"},
}
for _, category in ipairs(storeCategories) do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1 / #storeCategories, -5, 0, 30)
	button.Text = category.Label
	styleButton(button)
	button.TextSize = 11
	button.Parent = storeCategoryBar
	storeCategoryButtons[category.Filter] = button
end

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(16, 140)
list.Size = UDim2.new(0.58, -22, 1, -158)
list.BackgroundColor3 = Color3.fromRGB(24, 30, 45)
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = panel
round(list, 9)
local listLayout = Instance.new("UIGridLayout")
listLayout.CellSize, listLayout.CellPadding, listLayout.FillDirectionMaxCells = UDim2.fromOffset(100, 112), UDim2.fromOffset(6, 6), 4
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = list
local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop, listPadding.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
listPadding.PaddingLeft, listPadding.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
listPadding.Parent = list

local detail = Instance.new("Frame")
detail.Position = UDim2.new(0.58, 4, 0, 140)
detail.Size = UDim2.new(0.42, -20, 1, -158)
detail.BackgroundColor3 = Color3.fromRGB(27, 34, 50)
detail.BorderSizePixel = 0
detail.Parent = panel
round(detail, 9)

local itemIcon = Instance.new("TextLabel")
itemIcon.Position = UDim2.new(0.5, -34, 0, 16)
itemIcon.Size = UDim2.fromOffset(68, 68)
itemIcon.BackgroundColor3 = Color3.fromRGB(45, 56, 78)
itemIcon.Text = "?"
itemIcon.TextColor3 = Color3.new(1, 1, 1)
itemIcon.Font = Enum.Font.GothamBlack
itemIcon.TextSize = 36
round(itemIcon, 12)
itemIcon.Parent = detail
local itemImage = Instance.new("ImageLabel")
itemImage.Size = UDim2.fromScale(1, 1)
itemImage.BackgroundTransparency = 1
itemImage.Visible = false
itemImage.Parent = itemIcon

local equippedSummaryScroll = Instance.new("ScrollingFrame")
equippedSummaryScroll.Position = UDim2.fromOffset(12, 214)
equippedSummaryScroll.Size = UDim2.new(1, -24, 1, -310)
equippedSummaryScroll.BackgroundColor3 = Color3.fromRGB(21, 28, 42)
equippedSummaryScroll.BorderSizePixel = 0
equippedSummaryScroll.ScrollBarThickness = 4
equippedSummaryScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
equippedSummaryScroll.CanvasSize = UDim2.new()
round(equippedSummaryScroll, 7)
equippedSummaryScroll.Parent = detail
local equippedSummary = Instance.new("TextLabel")
equippedSummary.Position = UDim2.fromOffset(6, 5)
equippedSummary.Size = UDim2.new(1, -14, 0, 0)
equippedSummary.AutomaticSize = Enum.AutomaticSize.Y
equippedSummary.BackgroundTransparency = 1
equippedSummary.TextColor3 = Color3.fromRGB(205, 220, 240)
equippedSummary.TextWrapped = true
equippedSummary.TextXAlignment = Enum.TextXAlignment.Left
equippedSummary.TextYAlignment = Enum.TextYAlignment.Top
equippedSummary.Font = Enum.Font.Gotham
equippedSummary.TextSize = 12
equippedSummary.Text = "EQUIPPED LOADOUT\nLoading..."
equippedSummary.Parent = equippedSummaryScroll

local itemName = Instance.new("TextLabel")
itemName.Position = UDim2.fromOffset(10, 92)
itemName.Size = UDim2.new(1, -20, 0, 30)
itemName.BackgroundTransparency = 1
itemName.Text = "Select an item"
itemName.TextColor3 = Color3.new(1, 1, 1)
itemName.Font = Enum.Font.GothamBold
itemName.TextScaled = true
itemName.Parent = detail

local descriptionScroll = Instance.new("ScrollingFrame")
descriptionScroll.Position = UDim2.fromOffset(12, 126)
descriptionScroll.Size = UDim2.new(1, -24, 0, 78)
descriptionScroll.BackgroundTransparency = 1
descriptionScroll.BorderSizePixel = 0
descriptionScroll.ScrollBarThickness = 3
descriptionScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
descriptionScroll.CanvasSize = UDim2.new()
descriptionScroll.Parent = detail
local description = Instance.new("TextLabel")
description.Position = UDim2.fromOffset(0, 0)
description.Size = UDim2.new(1, -6, 0, 0)
description.AutomaticSize = Enum.AutomaticSize.Y
description.BackgroundTransparency = 1
description.Text = "Items, recipes, and store supplies appear here."
description.TextColor3 = Color3.fromRGB(180, 195, 220)
description.TextWrapped = true
description.TextXAlignment = Enum.TextXAlignment.Left
description.TextYAlignment = Enum.TextYAlignment.Top
description.Font = Enum.Font.Gotham
description.TextSize = 13
description.Parent = descriptionScroll

local actionArea = Instance.new("Frame")
actionArea.AnchorPoint = Vector2.new(0, 1)
actionArea.Position = UDim2.new(0, 10, 1, -10)
actionArea.Size = UDim2.new(1, -20, 0, 104)
actionArea.BackgroundTransparency = 1
actionArea.Parent = detail
local actionGrid = Instance.new("UIGridLayout")
actionGrid.CellPadding = UDim2.fromOffset(6, 6)
actionGrid.CellSize = UDim2.new(0.5, -3, 0, 22)
actionGrid.Parent = actionArea
local actions = {}
for _, name in ipairs({"PRIMARY", "FAVORITE", "LOCK", "SELL", "SELL JUNK", "CRAFT", "UNEQUIP"}) do
	local button = Instance.new("TextButton")
	button.Name, button.Text = name, name
	styleButton(button, string.find(name, "SELL", 1, true) and Color3.fromRGB(135, 65, 70) or nil)
	button.Parent = actionArea
	actions[name] = button
end

local characterLoadout = Instance.new("Frame")
characterLoadout.Position = UDim2.fromOffset(16, 96)
characterLoadout.Size = UDim2.new(1, -32, 1, -114)
characterLoadout.BackgroundColor3 = Color3.fromRGB(21, 28, 42)
characterLoadout.BorderSizePixel = 0
characterLoadout.Visible = false
characterLoadout.Parent = panel
round(characterLoadout, 10)
local characterViewport = Instance.new("ViewportFrame")
characterViewport.Position, characterViewport.Size = UDim2.new(0.27, 0, 0, 12), UDim2.new(0.46, 0, 1, -78)
characterViewport.BackgroundColor3, characterViewport.Ambient = Color3.fromRGB(29, 39, 58), Color3.fromRGB(175, 185, 210)
characterViewport.LightColor, characterViewport.LightDirection = Color3.fromRGB(255, 245, 220), Vector3.new(-1, -1, -1)
characterViewport.Parent = characterLoadout
round(characterViewport, 12)
local viewportWorld = Instance.new("WorldModel")
viewportWorld.Parent = characterViewport
local viewportCamera = Instance.new("Camera")
viewportCamera.FieldOfView, viewportCamera.Parent = 34, characterViewport
characterViewport.CurrentCamera = viewportCamera
local characterStats = Instance.new("TextLabel")
characterStats.Position, characterStats.Size = UDim2.new(0.2, 0, 1, -61), UDim2.new(0.6, 0, 0, 52)
characterStats.BackgroundTransparency, characterStats.TextColor3, characterStats.TextWrapped = 1, Color3.fromRGB(210, 230, 250), true
characterStats.Font, characterStats.TextSize, characterStats.Parent = Enum.Font.GothamBold, 12, characterLoadout

local loadoutSlots = {"Weapon", "SecondaryWeapon", "Head", "Chest", "Legs", "Boots", "Gloves", "Cape", "Core", "Artifact1", "Artifact2", "Artifact3"}
local loadoutSlotButtons = {}
for index, slot in ipairs(loadoutSlots) do
	local button = Instance.new("TextButton")
	local onLeft, row = index <= 6, index <= 6 and index or index - 6
	button.Position = UDim2.new(onLeft and 0 or 0.75, onLeft and 8 or -2, 0, 10 + (row - 1) * 58)
	button.Size, button.TextWrapped, button.Text = UDim2.new(0.25, -8, 0, 52), true, slot .. "\nEMPTY"
	styleButton(button, Color3.fromRGB(37, 49, 70))
	button.TextSize, button.Parent = 10, characterLoadout
	loadoutSlotButtons[slot] = button
end

local function refreshCharacterPreview()
	viewportWorld:ClearAllChildren()
	local character = player.Character
	if character then
		local wasArchivable = character.Archivable
		character.Archivable = true
		local clone = character:Clone()
		character.Archivable = wasArchivable
		for _, object in ipairs(clone:GetDescendants()) do
			if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("Tool") then object:Destroy()
			elseif object:IsA("BasePart") then object.Anchored, object.CanCollide, object.CanTouch = true, false, false end
		end
		clone:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(18), 0))
		clone.Parent = viewportWorld
		local _, size = clone:GetBoundingBox()
		local focusY = math.max(1.5, size.Y * 0.46)
		viewportCamera.CFrame = CFrame.lookAt(Vector3.new(0, focusY, math.max(7, size.Y * 1.15)), Vector3.new(0, focusY, 0))
	end
	for slot, button in pairs(loadoutSlotButtons) do
		local itemId = state.Equipment and state.Equipment[slot]
		local definition = itemId and config.Items[itemId]
		button.Text = definition and string.format("%s [%s]\n%s", slot, itemGlyph(definition), definition.DisplayName) or (slot .. "\nEMPTY - CLICK")
		button.BackgroundColor3 = definition and (config.RarityColors[definition.Rarity] or Color3.fromRGB(52, 67, 90)):Lerp(Color3.fromRGB(28, 35, 50), 0.68) or Color3.fromRGB(37, 49, 70)
	end
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	characterStats.Text = string.format("LEVEL %d   HP %d/%d   MP %d/%d\nATTACK %d   DEFENSE %d   POWER %d   SPEED %.1f", player:GetAttribute("Level") or 1, humanoid and humanoid.Health or 0, player:GetAttribute("MaxHealth") or 0, player:GetAttribute("MP") or 0, player:GetAttribute("MaxMP") or 0, player:GetAttribute("AttackPower") or 0, player:GetAttribute("Defense") or 0, player:GetAttribute("Power") or 0, humanoid and humanoid.WalkSpeed or 0)
end

local notification = Instance.new("TextLabel")
notification.AnchorPoint = Vector2.new(0.5, 0)
notification.Position = UDim2.new(0.5, 0, 0, 65)
notification.Size = UDim2.fromOffset(360, 42)
notification.BackgroundColor3 = Color3.fromRGB(25, 34, 50)
notification.BackgroundTransparency = 0.08
notification.TextColor3 = Color3.fromRGB(255, 225, 120)
notification.Font = Enum.Font.GothamBold
notification.TextSize = 15
notification.Visible = false
notification.Parent = gui
round(notification, 9)

local function showNotification(message, color)
	notification.Text = tostring(message)
	notification.TextColor3 = color or Color3.fromRGB(255, 225, 120)
	notification.TextTransparency, notification.BackgroundTransparency = 0, 0.08
	notification.Visible = true
	local token = os.clock()
	notification:SetAttribute("Token", token)
	task.delay(2.2, function()
		if notification:GetAttribute("Token") == token then
			TweenService:Create(notification, TweenInfo.new(0.3), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
			task.wait(0.32)
			if notification:GetAttribute("Token") == token then notification.Visible = false end
		end
	end)
end

local function invoke(remote, action, payload)
	if busy then return nil end
	busy = true
	local ok, result = pcall(function() return remote:InvokeServer(action, payload or {}) end)
	busy = false
	if not ok then showNotification("Server request failed", Color3.fromRGB(255, 100, 110)) return nil end
	if result.Message then showNotification(result.Message, result.Success and Color3.fromRGB(110, 235, 155) or Color3.fromRGB(255, 110, 120)) end
	if result.State then state = result.State end
	return result
end

local function statText(stats)
	local parts = {}
	for _, name in ipairs({"Attack", "Health", "Defense", "Power", "Speed", "MP", "CriticalChance", "CriticalDamage"}) do
		local value = stats and stats[name]
		if value and value ~= 0 then
			local shown = string.find(name, "Critical") and string.format("+%d%%", math.floor(value * 100)) or ("+" .. tostring(value))
			table.insert(parts, name .. " " .. shown)
		end
	end
	return #parts > 0 and table.concat(parts, "  |  ") or "No equipment stats"
end

local function resistanceText(resistances)
	local parts = {}
	for _, element in ipairs({"Fire", "Ice", "Water", "Lightning", "Earth", "Gravity", "Poison", "Prismatic"}) do
		local value = resistances and resistances[element]
		if value and value ~= 0 then table.insert(parts, string.format("%s Resist +%d%%", element, math.floor(value * 100))) end
	end
	return table.concat(parts, " | ")
end

local function benefitText(definition)
	local parts = {statText(definition.Stats)}
	local resistances = resistanceText(definition.Resistances)
	if resistances ~= "" then table.insert(parts, resistances) end
	if definition.Passive then table.insert(parts, "Effect: " .. definition.Passive) end
	if definition.Purpose then table.insert(parts, "Purpose: " .. definition.Purpose) end
	if definition.SellValue then table.insert(parts, "Sell value: " .. definition.SellValue .. " gold") end
	return table.concat(parts, " | ")
end

local function statDeltaText(stats, equippedStats)
	local parts = {}
	for _, name in ipairs({"Attack", "Health", "Defense", "Power", "Speed", "MP", "CriticalChance", "CriticalDamage"}) do
		local delta = (stats and stats[name] or 0) - (equippedStats and equippedStats[name] or 0)
		if delta ~= 0 then
			local shown = string.find(name, "Critical") and string.format("%+.0f%%", delta * 100) or string.format("%+g", delta)
			table.insert(parts, name .. " " .. shown)
		end
	end
	return #parts > 0 and table.concat(parts, "  |  ") or "No stat change"
end

local function setIcon(icon, definition)
	local image = icon == itemIcon and itemImage or icon:FindFirstChild("IconImage")
	if image and image:IsA("ImageLabel") and definition.Icon and definition.Icon ~= "" then
		image.Image = definition.Icon
		image.Visible = true
		if icon:IsA("TextLabel") or icon:IsA("TextButton") then icon.Text = "" end
		return
	elseif image and image:IsA("ImageLabel") then
		image.Visible = false
	end
	if definition.Icon and definition.Icon ~= "" and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
		icon.Text = ""
		icon.Image = definition.Icon
		icon.BackgroundTransparency = 0.08
	elseif icon:IsA("TextLabel") or icon:IsA("TextButton") then
		icon.Text = itemGlyph(definition)
		icon.TextScaled = true
		icon.BackgroundTransparency = 0
	elseif icon:IsA("ImageLabel") or icon:IsA("ImageButton") then
		icon.Image = ""
		icon.BackgroundTransparency = 0
	end
end

local function refreshEquippedSummary()
	local totals = {}
	local totalResistances = {}
	local lines = {"EQUIPPED GEAR & BENEFITS"}
	local empty = {}
	for _, slot in ipairs({"Weapon", "SecondaryWeapon", "Head", "Chest", "Legs", "Boots", "Gloves", "Artifact1", "Artifact2", "Artifact3", "Core", "Cape"}) do
		local itemId = state.Equipment and state.Equipment[slot]
		local definition = itemId and config.Items[itemId]
		if definition then
			for name, value in pairs(definition.Stats or {}) do totals[name] = (totals[name] or 0) + value end
			for element, value in pairs(definition.Resistances or {}) do totalResistances[element] = (totalResistances[element] or 0) + value end
			table.insert(lines, string.format("%s: %s | %s", slot, definition.DisplayName, benefitText(definition)))
		else
			table.insert(empty, slot)
		end
	end
	local totalResistanceText = resistanceText(totalResistances)
	table.insert(lines, 2, "TOTAL BONUSES: " .. statText(totals) .. (totalResistanceText ~= "" and " | " .. totalResistanceText or ""))
	if #empty > 0 then table.insert(lines, "EMPTY SLOTS: " .. table.concat(empty, ", ")) end
	equippedSummary.Text = table.concat(lines, "\n")
end

local refresh
local function selectItem(itemId)
	selectedItem = itemId
	local definition = config.Items[itemId]
	if not definition then return end
	setIcon(itemIcon, definition)
	itemIcon.BackgroundColor3 = categoryColors[definition.Category] or Color3.fromRGB(45, 56, 78)
	itemName.Text, itemName.TextColor3 = definition.DisplayName, config.RarityColors[definition.Rarity]
	local equippedSlot
	for slot, equippedId in pairs(state.Equipment or {}) do if equippedId == itemId then equippedSlot = slot break end end
	local recipe = config.Recipes[itemId]
	local recipeText = ""
	local compareText = ""
	if recipe then
		local ingredients = {}
		for ingredientId, amount in pairs(recipe.Ingredients) do table.insert(ingredients, amount .. "x " .. config.Items[ingredientId].DisplayName) end
		recipeText = "\nRecipe: " .. table.concat(ingredients, ", ")
	end
	if definition.EquipSlot and not equippedSlot then
		local compareId
		if definition.EquipSlot == "Artifact" then
			for index = 1, 3 do if state.Equipment["Artifact" .. index] ~= "" then compareId = state.Equipment["Artifact" .. index] break end end
		else compareId = state.Equipment[definition.EquipSlot] end
		local compareDefinition = compareId and config.Items[compareId]
		if compareDefinition then compareText = "\nCompared with " .. compareDefinition.DisplayName .. ": " .. statDeltaText(definition.Stats, compareDefinition.Stats) end
	end
	description.Text = string.format("%s • %s%s\n%s\n\n%s%s%s", definition.Rarity, definition.Category, equippedSlot and (" • Equipped: " .. equippedSlot) or "", definition.Description, statText(definition.Stats), compareText, recipeText)
	local combatDetails = ""
	if definition.Category == "Weapon" then
		combatDetails = string.format("\n%sLevel %d | %s %s\nUnique effect: %s\nAssigned ability: %s", definition.Unique and "UNIQUE ITEM | " or "", definition.RequiredLevel or 1, definition.Element or "Physical", definition.WeaponType or definition.WeaponKind or "Weapon", definition.Passive or "Standard impact", definition.AbilityId or "Basic weapon attack")
	end
	description.Text = string.format("%s | %s%s\n%s%s\n\n%s%s%s", definition.Rarity, definition.Category, equippedSlot and (" | Equipped: " .. equippedSlot) or "", definition.Description, combatDetails, benefitText(definition), compareText, recipeText)
	if currentTab == "Store" then
		actions.PRIMARY.Text, actions.PRIMARY.Visible = "BUY " .. tostring(definition.BuyPrice or 0), definition.BuyPrice ~= nil
	else
		actions.PRIMARY.Text = definition.Consumable and "USE" or definition.EquipSlot and "EQUIP" or "DETAILS"
		actions.PRIMARY.Visible = definition.Consumable ~= nil or definition.EquipSlot ~= nil
	end
	if not selectedItem then
		for _, item in ipairs(state.Items or {}) do
			if config.Items[item.Id] then selectedItem = item.Id break end
		end
	end
	actions.FAVORITE.Visible = currentTab == "Inventory"
	actions.LOCK.Visible = currentTab == "Inventory"
	actions.CRAFT.Visible = currentTab ~= "Store" and recipe ~= nil
	actions.SELL.Visible = currentTab == "Inventory"
	actions["SELL JUNK"].Visible = currentTab == "Inventory"
	actions.UNEQUIP.Visible = currentTab == "Inventory" and equippedSlot ~= nil
	refreshEquippedSummary()
end

local function clearList()
	for _, child in ipairs(list:GetChildren()) do if child:IsA("GuiButton") or child.Name == "EmptyMessage" then child:Destroy() end end
end

local function addCard(itemId, subtitle, clickAction)
	local definition = config.Items[itemId]
	local card = Instance.new("TextButton")
	card.Name = itemId
	card.Size = UDim2.fromOffset(100, 112)
	card.BackgroundColor3 = selectedItem == itemId and Color3.fromRGB(54, 68, 94) or Color3.fromRGB(35, 43, 62)
	card.BorderSizePixel = 0
	card.Text = ""
	round(card, 7)
	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(1, 0, 0, 4)
	accent.BackgroundColor3 = config.RarityColors[definition.Rarity]
	accent.BorderSizePixel = 0
	accent.Parent = card
	local icon = Instance.new("TextLabel")
	icon.Position = UDim2.new(0.5, -24, 0, 10)
	icon.Size = UDim2.fromOffset(48, 48)
	icon.BackgroundColor3 = categoryColors[definition.Category] or Color3.fromRGB(65, 75, 95)
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.Font, icon.TextSize = Enum.Font.GothamBlack, 23
	setIcon(icon, definition)
	round(icon, 8)
	icon.Parent = card
	local iconImage = Instance.new("ImageLabel")
	iconImage.Name = "IconImage"
	iconImage.Size = UDim2.fromScale(1, 1)
	iconImage.BackgroundTransparency = 1
	iconImage.Visible = false
	iconImage.Parent = icon
	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromOffset(5, 62)
	label.Size = UDim2.new(1, -10, 0, 44)
	label.BackgroundTransparency = 1
	label.Text = definition.DisplayName .. "\n" .. subtitle
	label.TextColor3 = config.RarityColors[definition.Rarity]
	label.TextXAlignment, label.TextYAlignment = Enum.TextXAlignment.Center, Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.Font, label.TextSize = Enum.Font.GothamBold, 11
	label.Parent = card
	card.Activated:Connect(function() selectItem(itemId); if clickAction then clickAction() end; refresh() end)
	card.Parent = list
end

refresh = function()
	local showCharacter = currentTab == "Character"
	characterLoadout.Visible = showCharacter
	list.Visible, detail.Visible = not showCharacter, not showCharacter
	search.Visible, capacity.Visible, filterButton.Visible = not showCharacter, not showCharacter
	local showStoreCategories = currentTab == "Store"
	storeCategoryBar.Visible = showStoreCategories
	local contentTop = showStoreCategories and 176 or 140
	list.Position = UDim2.fromOffset(16, contentTop)
	list.Size = UDim2.new(0.58, -22, 1, -(contentTop + 18))
	detail.Position = UDim2.new(0.58, 4, 0, contentTop)
	detail.Size = UDim2.new(0.42, -20, 1, -(contentTop + 18))
	refreshEquippedSummary()
	capacity.Text = string.format("%d / %d SLOTS  •  %d GOLD%s", state.Used or 0, state.Capacity or config.Capacity, player:GetAttribute("Coins") or 0, slotFilter and ("  |  " .. slotFilter .. " ITEMS") or "")
	clearList()
	local query = string.lower(search.Text)
	if currentTab == "Inventory" then
		for _, item in ipairs(state.Items or {}) do
			local definition = config.Items[item.Id]
			local filterMatch = definition and (filter == "All" or definition.Category == filter or ((filter == "Gun" or filter == "Rifle") and definition.WeaponKind == filter))
			local normalizedSlot = slotFilter and string.match(slotFilter, "^Artifact") and "Artifact" or slotFilter
			local slotMatch = not normalizedSlot or definition and definition.EquipSlot == normalizedSlot
			if definition and filterMatch and slotMatch and (query == "" or string.find(string.lower(definition.DisplayName), query, 1, true)) then
				local flags = (item.Favorite and "★ " or "") .. (item.Locked and "🔒 " or "")
				addCard(item.Id, flags .. "x" .. item.Count .. "  •  " .. definition.Rarity)
			end
		end
	elseif currentTab == "Character" then
		refreshCharacterPreview()
		itemName.Text = player.DisplayName
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local buffs = {}
		if (player:GetAttribute("ConsumableDamageMultiplier") or 1) > 1 then table.insert(buffs, "Damage serum") end
		if (player:GetAttribute("ConsumableDefense") or 0) > 0 then table.insert(buffs, "Defense tonic") end
		if (player:GetAttribute("BonusMPRegen") or 0) > 0 then table.insert(buffs, "Energy surge") end
		if player:GetAttribute("ActiveTransformation") and player:GetAttribute("ActiveTransformation") ~= "" then table.insert(buffs, player:GetAttribute("ActiveTransformation") .. " form") end
		description.Text = string.format("LEVEL %d | HIGHEST CLEARED WAVE %d | ASCENDANT %d\nHP %d/%d  MP %d/%d  ATTACK %d  DEFENSE %d\nPOWER %d  SPEED %.1f  CRIT %.0f%%  CRIT DMG %.0f%%\nELEMENT %s | BUFFS: %s", player:GetAttribute("Level") or 1, player:GetAttribute("HighestWave") or 0, player:GetAttribute("Evolution") or 0, humanoid and humanoid.Health or 0, player:GetAttribute("MaxHealth") or 0, player:GetAttribute("MP") or 0, player:GetAttribute("MaxMP") or 0, player:GetAttribute("AttackPower") or 0, player:GetAttribute("Defense") or 0, player:GetAttribute("Power") or 0, humanoid and humanoid.WalkSpeed or 0, (player:GetAttribute("CriticalChance") or 0) * 100, (player:GetAttribute("CriticalDamage") or 1.5) * 100, player:GetAttribute("CurrentElement") or player:GetAttribute("EquippedWeaponElement") or "Physical", #buffs > 0 and table.concat(buffs, ", ") or "None")
		refreshEquippedSummary()
	elseif currentTab == "Crafting" then
		for itemId, recipe in pairs(config.Recipes) do
			local definition = config.Items[itemId]
			if query == "" or string.find(string.lower(definition.DisplayName), query, 1, true) then addCard(itemId, "CRAFT x" .. recipe.Quantity) end
		end
	else
		local storeIds = {}
		local playerLevel = player:GetAttribute("Level") or 1
		for itemId, definition in pairs(config.Items) do
			if definition.BuyPrice and (definition.RequiredLevel or 1) <= playerLevel then table.insert(storeIds, itemId) end
		end
		table.sort(storeIds, function(left, right)
			local a, b = config.Items[left], config.Items[right]
			return a.BuyPrice == b.BuyPrice and a.DisplayName < b.DisplayName or a.BuyPrice < b.BuyPrice
		end)
		for _, itemId in ipairs(storeIds) do
			local definition = config.Items[itemId]
			local filterMatch = filter == "All" or definition.Category == filter
				or (filter == "Ranged" and (definition.WeaponKind == "Gun" or definition.WeaponKind == "Rifle"))
				or ((filter == "Gun" or filter == "Rifle") and definition.WeaponKind == filter)
			if filterMatch and (query == "" or string.find(string.lower(definition.DisplayName), query, 1, true)) then addCard(itemId, definition.BuyPrice .. " GOLD | LV " .. (definition.RequiredLevel or 1)) end
		end
	end
	for name, button in pairs(tabButtons) do button.BackgroundColor3 = name == currentTab and Color3.fromRGB(65, 125, 185) or Color3.fromRGB(42, 52, 73) end
	for categoryFilter, button in pairs(storeCategoryButtons) do
		button.BackgroundColor3 = categoryFilter == filter and Color3.fromRGB(65, 125, 185) or Color3.fromRGB(42, 52, 73)
	end
end

for _, tabName in ipairs({"Inventory", "Character", "Crafting", "Store"}) do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.25, -6, 0, 36)
	button.Text = tabName == "Inventory" and "BAG" or tabName == "Character" and "EQUIPMENT & STATS" or string.upper(tabName)
	styleButton(button)
	button.Parent = tabs
	tabButtons[tabName] = button
	button.Activated:Connect(function() currentTab = tabName; filter = "All"; slotFilter = nil; filterButton.Text = "FILTER: ALL"; refresh() end)
end

for slot, button in pairs(loadoutSlotButtons) do
	button.Activated:Connect(function()
		currentTab, slotFilter, filter = "Inventory", slot, "All"
		filterButton.Text = "FILTER: ALL"
		refresh()
	end)
end

local filters = {"All", "Weapon", "Gun", "Rifle", "Armor", "Artifact", "Consumable", "Material"}
for _, category in ipairs(storeCategories) do
	storeCategoryButtons[category.Filter].Activated:Connect(function()
		filter = category.Filter
		filterButton.Text = "FILTER: " .. string.upper(filter)
		refresh()
	end)
end
filterButton.Activated:Connect(function()
	local index = table.find(filters, filter) or 1
	filter = filters[index % #filters + 1]
	filterButton.Text = "FILTER: " .. string.upper(filter)
	refresh()
end)
search:GetPropertyChangedSignal("Text"):Connect(refresh)
for _, attribute in ipairs({"Level", "HighestWave", "Evolution", "Coins", "MaxHealth", "MaxMP", "AttackPower", "Defense", "Power", "CriticalChance", "CriticalDamage", "CurrentElement"}) do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		if panel.Visible then refresh() end
	end)
end

actions.PRIMARY.Activated:Connect(function()
	if not selectedItem then return end
	if currentTab == "Store" then
		invoke(storeRemote, "Buy", {ItemId = selectedItem})
		local refreshed = invoke(inventoryRemote, "GetState")
		if refreshed then refresh(); selectItem(selectedItem) end
		return
	end
	local definition = config.Items[selectedItem]
	local action = definition.Consumable and "Use" or definition.EquipSlot and "Equip"
	if action then local result = invoke(inventoryRemote, action, {ItemId = selectedItem}); if result then refresh(); selectItem(selectedItem) end end
end)
actions.FAVORITE.Activated:Connect(function() if selectedItem then local result = invoke(inventoryRemote, "Favorite", {ItemId = selectedItem}); if result then refresh() end end end)
actions.LOCK.Activated:Connect(function() if selectedItem then local result = invoke(inventoryRemote, "Lock", {ItemId = selectedItem}); if result then refresh() end end end)
actions.SELL.Activated:Connect(function() if selectedItem then invoke(storeRemote, "Sell", {ItemId = selectedItem}); local result = invoke(inventoryRemote, "GetState"); if result then refresh() end end end)
actions["SELL JUNK"].Activated:Connect(function() local result = invoke(inventoryRemote, "SellJunk"); if result then refresh() end end)
actions.CRAFT.Activated:Connect(function() if selectedItem then local result = invoke(inventoryRemote, "Craft", {ItemId = selectedItem}); if result then refresh() end end end)
actions.UNEQUIP.Activated:Connect(function()
	if not selectedItem then return end
	for slot, itemId in pairs(state.Equipment or {}) do if itemId == selectedItem then local result = invoke(inventoryRemote, "Unequip", {Slot = slot}); if result then refresh(); selectItem(selectedItem) end break end end
end)

local function toggle()
	panel.Visible = not panel.Visible
	if panel.Visible then
		local result = invoke(inventoryRemote, "GetState")
		if result then refresh(); if selectedItem then selectItem(selectedItem) end end
		GuiService.SelectedObject = tabButtons[currentTab]
	else
		GuiService.SelectedObject = nil
	end
end
local connectedStorePrompts = {}
local function connectStorePrompt(descendant)
	if descendant:IsA("ProximityPrompt") and descendant.Name == "OpenStorePrompt" and not connectedStorePrompts[descendant] then
		connectedStorePrompts[descendant] = true
		descendant.Triggered:Connect(function()
			currentTab = "Store"
			slotFilter = nil
			if not panel.Visible then toggle() else refresh() end
		end)
	end
end
for _, descendant in ipairs(workspace:GetDescendants()) do connectStorePrompt(descendant) end
workspace.DescendantAdded:Connect(connectStorePrompt)
openButton.Activated:Connect(toggle)
close.Activated:Connect(function() panel.Visible = false end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.B then toggle()
	elseif input.KeyCode == Enum.KeyCode.Three then invoke(inventoryRemote, "Use", {ItemId = "HealthPotion"})
	elseif input.KeyCode == Enum.KeyCode.Four then invoke(inventoryRemote, "Use", {ItemId = "ManaPotion"})
	elseif input.KeyCode == Enum.KeyCode.Five then invoke(inventoryRemote, "Use", {ItemId = "BattleSerum"}) end
end)

local function gamepadMenuAction(actionName, inputState)
	if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	if actionName == "InventoryToggle" then
		toggle()
		return Enum.ContextActionResult.Sink
	elseif actionName == "InventoryClose" then
		if panel.Visible then panel.Visible = false; GuiService.SelectedObject = nil; return Enum.ContextActionResult.Sink end
	elseif actionName == "InventoryBlockCombat" and panel.Visible then
		return Enum.ContextActionResult.Sink
	elseif actionName == "InventoryNextTab" or actionName == "InventoryPreviousTab" then
		if panel.Visible then
			local names = {"Inventory", "Character", "Crafting", "Store"}
			local index = table.find(names, currentTab) or 1
			currentTab = names[(index - 1 + (actionName == "InventoryNextTab" and 1 or -1)) % #names + 1]
			filter, filterButton.Text = "All", "FILTER: ALL"
			refresh()
			GuiService.SelectedObject = tabButtons[currentTab]
			return Enum.ContextActionResult.Sink
		end
	elseif not panel.Visible then
		if actionName == "QuickHealthCore" then invoke(inventoryRemote, "Use", {ItemId = "HealthPotion"})
		elseif actionName == "QuickManaCrystal" then invoke(inventoryRemote, "Use", {ItemId = "ManaPotion"})
		elseif actionName == "QuickBattleSerum" then invoke(inventoryRemote, "Use", {ItemId = "BattleSerum"})
		else return Enum.ContextActionResult.Pass end
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindActionAtPriority("InventoryToggle", gamepadMenuAction, false, 3000, Enum.KeyCode.ButtonSelect)
ContextActionService:BindActionAtPriority("InventoryClose", gamepadMenuAction, false, 3000, Enum.KeyCode.ButtonB)
ContextActionService:BindActionAtPriority("InventoryBlockCombat", gamepadMenuAction, false, 3000, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2, Enum.KeyCode.ButtonL3)
ContextActionService:BindActionAtPriority("InventoryNextTab", gamepadMenuAction, false, 3000, Enum.KeyCode.ButtonR1)
ContextActionService:BindActionAtPriority("InventoryPreviousTab", gamepadMenuAction, false, 3000, Enum.KeyCode.ButtonL1)
ContextActionService:BindActionAtPriority("QuickHealthCore", gamepadMenuAction, false, 2500, Enum.KeyCode.DPadLeft)
ContextActionService:BindActionAtPriority("QuickManaCrystal", gamepadMenuAction, false, 2500, Enum.KeyCode.DPadDown)
ContextActionService:BindActionAtPriority("QuickBattleSerum", gamepadMenuAction, false, 2500, Enum.KeyCode.DPadRight)
inventoryEvent.OnClientEvent:Connect(function(kind, data)
	if kind == "LootWorld" and typeof(data.Origin) == "Vector3" then
		local color = config.RarityColors[data.Rarity] or Color3.new(1, 1, 1)
		local beam = Instance.new("Part")
		beam.Name = "LocalLootBeam"
		beam.Anchored, beam.CanCollide, beam.CanQuery, beam.CanTouch = true, false, false, false
		beam.Material, beam.Color, beam.Transparency = Enum.Material.Neon, color, 0.18
		beam.Size, beam.CFrame = Vector3.new(0.45, 20, 0.45), CFrame.new(data.Origin + Vector3.new(0, 10, 0))
		beam.Parent = workspace
		TweenService:Create(beam, TweenInfo.new(1.2), {Transparency = 1, Size = Vector3.new(1.4, 26, 1.4)}):Play()
		Debris:AddItem(beam, 1.3)
	end
	if data.Message then showNotification(data.Message) end
	if kind ~= "LootWorld" and panel.Visible then local result = invoke(inventoryRemote, "GetState"); if result then refresh() end end
end)
