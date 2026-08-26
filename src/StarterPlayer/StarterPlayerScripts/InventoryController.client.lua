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

local gui = Instance.new("ScreenGui")
gui.Name = "InventoryUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 120
gui.Parent = player:WaitForChild("PlayerGui")

local openButton = Instance.new("TextButton")
openButton.AnchorPoint = Vector2.new(1, 0)
openButton.Position = UDim2.new(1, -210, 0, 14)
openButton.Size = UDim2.fromOffset(82, 36)
openButton.Text = "BAG [B]"
styleButton(openButton, Color3.fromRGB(70, 125, 190))
openButton.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "InventoryPanel"
panel.AnchorPoint = Vector2.new(1, 0.5)
panel.Position = UDim2.new(1, -18, 0.55, 0)
panel.Size = UDim2.new(0.68, 0, 0.78, 0)
panel.BackgroundColor3 = Color3.fromRGB(17, 22, 34)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
round(panel, 13)
local constraint = Instance.new("UISizeConstraint")
constraint.MinSize, constraint.MaxSize = Vector2.new(330, 680), Vector2.new(760, 760)
constraint.Parent = panel

local header = Instance.new("TextLabel")
header.Position = UDim2.fromOffset(18, 10)
header.Size = UDim2.new(1, -70, 0, 34)
header.BackgroundTransparency = 1
header.Text = "ASCENDANT INVENTORY"
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
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
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

local equippedSummary = Instance.new("TextLabel")
equippedSummary.Position = UDim2.fromOffset(12, 266)
equippedSummary.Size = UDim2.new(1, -24, 0, 90)
equippedSummary.BackgroundColor3 = Color3.fromRGB(21, 28, 42)
equippedSummary.TextColor3 = Color3.fromRGB(205, 220, 240)
equippedSummary.TextWrapped = true
equippedSummary.TextXAlignment = Enum.TextXAlignment.Left
equippedSummary.TextYAlignment = Enum.TextYAlignment.Top
equippedSummary.Font = Enum.Font.Gotham
equippedSummary.TextSize = 12
equippedSummary.Text = "EQUIPPED LOADOUT\nLoading..."
round(equippedSummary, 7)
equippedSummary.Parent = detail

local itemName = Instance.new("TextLabel")
itemName.Position = UDim2.fromOffset(10, 92)
itemName.Size = UDim2.new(1, -20, 0, 30)
itemName.BackgroundTransparency = 1
itemName.Text = "Select an item"
itemName.TextColor3 = Color3.new(1, 1, 1)
itemName.Font = Enum.Font.GothamBold
itemName.TextScaled = true
itemName.Parent = detail

local description = Instance.new("TextLabel")
description.Position = UDim2.fromOffset(12, 126)
description.Size = UDim2.new(1, -24, 0, 128)
description.BackgroundTransparency = 1
description.Text = "Items, recipes, and store supplies appear here."
description.TextColor3 = Color3.fromRGB(180, 195, 220)
description.TextWrapped = true
description.TextXAlignment = Enum.TextXAlignment.Left
description.TextYAlignment = Enum.TextYAlignment.Top
description.Font = Enum.Font.Gotham
description.TextSize = 13
description.Parent = detail

local actionArea = Instance.new("Frame")
actionArea.AnchorPoint = Vector2.new(0, 1)
actionArea.Position = UDim2.new(0, 10, 1, -10)
actionArea.Size = UDim2.new(1, -20, 0, 112)
actionArea.BackgroundTransparency = 1
actionArea.Parent = detail
local actionGrid = Instance.new("UIGridLayout")
actionGrid.CellPadding = UDim2.fromOffset(6, 6)
actionGrid.CellSize = UDim2.new(0.5, -3, 0, 34)
actionGrid.Parent = actionArea
local actions = {}
for _, name in ipairs({"PRIMARY", "FAVORITE", "LOCK", "SELL", "CRAFT", "UNEQUIP"}) do
	local button = Instance.new("TextButton")
	button.Name, button.Text = name, name
	styleButton(button, name == "SELL" and Color3.fromRGB(135, 65, 70) or nil)
	button.Parent = actionArea
	actions[name] = button
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
		icon.Text = symbols[definition.Category] or "◇"
		icon.BackgroundTransparency = 0
	elseif icon:IsA("ImageLabel") or icon:IsA("ImageButton") then
		icon.Image = ""
		icon.BackgroundTransparency = 0
	end
end

local function refreshEquippedSummary()
	local lines = {"EQUIPPED LOADOUT"}
	for _, slot in ipairs({"Weapon", "SecondaryWeapon", "Head", "Chest", "Legs", "Boots", "Gloves", "Artifact1", "Artifact2", "Artifact3", "Core", "Cape"}) do
		local itemId = state.Equipment and state.Equipment[slot]
		local definition = itemId and config.Items[itemId]
		if definition then
			table.insert(lines, string.format("%s: %s  [%s]", slot, definition.DisplayName, statText(definition.Stats)))
		else
			table.insert(lines, slot .. ": Empty")
		end
	end
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
	actions.SELL.Visible = currentTab == "Inventory" and definition.BuyPrice ~= nil
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
	card.Size = UDim2.new(1, -2, 0, 58)
	card.BackgroundColor3 = selectedItem == itemId and Color3.fromRGB(54, 68, 94) or Color3.fromRGB(35, 43, 62)
	card.BorderSizePixel = 0
	card.Text = ""
	round(card, 7)
	local accent = Instance.new("Frame")
	accent.Size = UDim2.fromOffset(5, 58)
	accent.BackgroundColor3 = config.RarityColors[definition.Rarity]
	accent.BorderSizePixel = 0
	accent.Parent = card
	local icon = Instance.new("TextLabel")
	icon.Position = UDim2.fromOffset(13, 7)
	icon.Size = UDim2.fromOffset(42, 42)
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
	label.Position = UDim2.fromOffset(64, 7)
	label.Size = UDim2.new(1, -70, 0, 44)
	label.BackgroundTransparency = 1
	label.Text = definition.DisplayName .. "\n" .. subtitle
	label.TextColor3 = config.RarityColors[definition.Rarity]
	label.TextXAlignment, label.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Center
	label.Font, label.TextSize = Enum.Font.GothamBold, 13
	label.Parent = card
	card.Activated:Connect(function() selectItem(itemId); if clickAction then clickAction() end; refresh() end)
	card.Parent = list
end

refresh = function()
	capacity.Text = string.format("%d / %d SLOTS  •  %d GOLD", state.Used or 0, state.Capacity or config.Capacity, player:GetAttribute("Coins") or 0)
	clearList()
	local query = string.lower(search.Text)
	if currentTab == "Inventory" then
		for _, item in ipairs(state.Items or {}) do
			local definition = config.Items[item.Id]
			if definition and (filter == "All" or definition.Category == filter) and (query == "" or string.find(string.lower(definition.DisplayName), query, 1, true)) then
				local flags = (item.Favorite and "★ " or "") .. (item.Locked and "🔒 " or "")
				addCard(item.Id, flags .. "x" .. item.Count .. "  •  " .. definition.Rarity)
			end
		end
	elseif currentTab == "Crafting" then
		for itemId, recipe in pairs(config.Recipes) do
			local definition = config.Items[itemId]
			if query == "" or string.find(string.lower(definition.DisplayName), query, 1, true) then addCard(itemId, "CRAFT x" .. recipe.Quantity) end
		end
	else
		for itemId, definition in pairs(config.Items) do
			if definition.BuyPrice and (query == "" or string.find(string.lower(definition.DisplayName), query, 1, true)) then addCard(itemId, definition.BuyPrice .. " GOLD") end
		end
	end
	for name, button in pairs(tabButtons) do button.BackgroundColor3 = name == currentTab and Color3.fromRGB(65, 125, 185) or Color3.fromRGB(42, 52, 73) end
end

for _, tabName in ipairs({"Inventory", "Crafting", "Store"}) do
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(118, 36)
	button.Text = string.upper(tabName)
	styleButton(button)
	button.Parent = tabs
	tabButtons[tabName] = button
	button.Activated:Connect(function() currentTab = tabName; filter = "All"; filterButton.Text = "FILTER: ALL"; refresh() end)
end

local filters = {"All", "Weapon", "Armor", "Artifact", "Consumable", "Material"}
filterButton.Activated:Connect(function()
	local index = table.find(filters, filter) or 1
	filter = filters[index % #filters + 1]
	filterButton.Text = "FILTER: " .. string.upper(filter)
	refresh()
end)
search:GetPropertyChangedSignal("Text"):Connect(refresh)

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
			local names = {"Inventory", "Crafting", "Store"}
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
		local orb = Instance.new("Part")
		orb.Shape, orb.Size, orb.Anchored, orb.CanCollide, orb.CanQuery, orb.CanTouch = Enum.PartType.Ball, Vector3.new(2.2, 2.2, 2.2), true, false, false, false
		orb.Material, orb.Color, orb.CFrame = Enum.Material.Neon, color, CFrame.new(data.Origin + Vector3.new(0, 1.2, 0))
		orb.Parent = workspace
		TweenService:Create(beam, TweenInfo.new(1.2), {Transparency = 1, Size = Vector3.new(1.4, 26, 1.4)}):Play()
		TweenService:Create(orb, TweenInfo.new(1.2), {Transparency = 1, Size = Vector3.new(5, 5, 5)}):Play()
		Debris:AddItem(beam, 1.3)
		Debris:AddItem(orb, 1.3)
	end
	if data.Message then showNotification(data.Message) end
	if kind ~= "LootWorld" and panel.Visible then local result = invoke(inventoryRemote, "GetState"); if result then refresh() end end
end)
