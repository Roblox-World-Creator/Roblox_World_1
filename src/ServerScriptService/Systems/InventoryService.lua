local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryService = {}
local itemConfig
local saveService
local progression
local progressionConfig
local inventoryEvent
local consumableReadyAt = {}
local buffTokens = {}
local questService
local EQUIPMENT_SLOTS = {"Weapon", "SecondaryWeapon", "Head", "Chest", "Legs", "Boots", "Gloves", "Artifact1", "Artifact2", "Artifact3", "Core", "Cape"}

local function response(success, message, state)
	return {Success = success, Message = message, State = state}
end

local function getFolders(player)
	local inventory = player:FindFirstChild("Inventory") or Instance.new("Folder")
	inventory.Name, inventory.Parent = "Inventory", player
	local equipment = player:FindFirstChild("Equipment") or Instance.new("Folder")
	equipment.Name, equipment.Parent = "Equipment", player
	for _, slotName in ipairs(EQUIPMENT_SLOTS) do
		local slot = equipment:FindFirstChild(slotName) or Instance.new("StringValue")
		slot.Name, slot.Parent = slotName, equipment
	end
	return inventory, equipment
end

local function getState(player)
	local inventory, equipment = getFolders(player)
	local items = {}
	for _, stack in ipairs(inventory:GetChildren()) do
		if stack:IsA("IntValue") and stack.Value > 0 and itemConfig.Items[stack.Name] then
			table.insert(items, {Id = stack.Name, Count = stack.Value, Favorite = stack:GetAttribute("Favorite") == true, Locked = stack:GetAttribute("Locked") == true})
		end
	end
	table.sort(items, function(left, right)
		local leftDefinition, rightDefinition = itemConfig.Items[left.Id], itemConfig.Items[right.Id]
		if left.Favorite ~= right.Favorite then return left.Favorite end
		local leftRarity = itemConfig.RarityOrder[leftDefinition.Rarity] or 0
		local rightRarity = itemConfig.RarityOrder[rightDefinition.Rarity] or 0
		return leftRarity == rightRarity and leftDefinition.DisplayName < rightDefinition.DisplayName or leftRarity > rightRarity
	end)
	local equipped = {}
	for _, slot in ipairs(equipment:GetChildren()) do if slot:IsA("StringValue") then equipped[slot.Name] = slot.Value end end
	return {Items = items, Equipment = equipped, Capacity = itemConfig.Capacity, Used = #items}
end

local function notify(player, kind, message, itemId, quantity)
	if inventoryEvent then inventoryEvent:FireClient(player, kind, {Message = message, ItemId = itemId, Quantity = quantity}) end
end

local function refreshEquipmentStats(player)
	local _, equipment = getFolders(player)
	local totals = {Attack = 0, Health = 0, Defense = 0, Power = 0, Speed = 0, MP = 0, CriticalChance = 0, CriticalDamage = 0}
	for _, slot in ipairs(equipment:GetChildren()) do
		local definition = slot:IsA("StringValue") and itemConfig.Items[slot.Value]
		if definition and definition.Stats then
			for stat, amount in pairs(definition.Stats) do if totals[stat] ~= nil then totals[stat] += amount end end
		end
	end
	local previousMP = player:GetAttribute("EquipmentMP") or 0
	for _, stat in ipairs({"Attack", "Health", "Speed"}) do player:SetAttribute("Equipment" .. stat, totals[stat]) end
	player:SetAttribute("EquipmentDefense", totals.Defense)
	player:SetAttribute("Defense", totals.Defense + (player:GetAttribute("ConsumableDefense") or 0))
	player:SetAttribute("Power", totals.Power)
	player:SetAttribute("CriticalChance", 0.05 + totals.CriticalChance)
	player:SetAttribute("CriticalDamage", 1.5 + totals.CriticalDamage)
	player:SetAttribute("EquipmentMP", totals.MP)
	local newMaxMP = math.max(1, (player:GetAttribute("MaxMP") or 100) - previousMP + totals.MP)
	player:SetAttribute("MaxMP", newMaxMP)
	player:SetAttribute("MaxEnergy", newMaxMP)
	player:SetAttribute("MP", math.min(player:GetAttribute("MP") or newMaxMP, newMaxMP))
	player:SetAttribute("Energy", player:GetAttribute("MP"))
	progression.RefreshStats(player, progressionConfig)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and not player:GetAttribute("AdminSpeedOverride") then humanoid.WalkSpeed = 36 * (player:GetAttribute("SpeedMultiplier") or 1) + totals.Speed end
	player:SetAttribute("EquippedWeapon", equipment.Weapon.Value)
end

local function createStack(inventory, itemId, saved)
	local stack = Instance.new("IntValue")
	stack.Name = itemId
	if type(saved) == "table" then
		stack.Value = math.max(0, math.floor(tonumber(saved.Count) or 0))
		stack:SetAttribute("Favorite", saved.Favorite == true)
		stack:SetAttribute("Locked", saved.Locked == true)
	else
		stack.Value = math.max(0, math.floor(tonumber(saved) or 0))
		stack:SetAttribute("Favorite", false)
		stack:SetAttribute("Locked", false)
	end
	stack.Parent = inventory
	return stack
end

local function setupPlayer(player)
	while player.Parent and not player:GetAttribute("DataLoaded") do player:GetAttributeChangedSignal("DataLoaded"):Wait() end
	if not player.Parent then return end
	local inventory, equipment = getFolders(player)
	local data = saveService.GetLoadedData(player) or {}
	for itemId, saved in pairs(type(data.Inventory) == "table" and data.Inventory or {}) do
		if itemConfig.Items[itemId] and not inventory:FindFirstChild(itemId) then createStack(inventory, itemId, saved) end
	end
	if #inventory:GetChildren() == 0 then
		createStack(inventory, "IronBlade", {Count = 1, Locked = true})
		createStack(inventory, "HealthPotion", {Count = 3})
		createStack(inventory, "ManaPotion", {Count = 2})
	end
	for slotName, itemId in pairs(type(data.Equipment) == "table" and data.Equipment or {}) do
		local slot = equipment:FindFirstChild(slotName)
		if slot and itemConfig.Items[itemId] and inventory:FindFirstChild(itemId) then slot.Value = itemId end
	end
	if equipment.Weapon.Value == "" and inventory:FindFirstChild("IronBlade") then equipment.Weapon.Value = "IronBlade" end
	player:SetAttribute("ConsumableDamageMultiplier", 1)
	refreshEquipmentStats(player)
	player:SetAttribute("InventoryReady", true)
end

function InventoryService.Grant(player, itemId, quantity, silent)
	local definition = itemConfig and itemConfig.Items[itemId]
	if not definition or not player or not player.Parent then return false, "Unknown item or player" end
	quantity = math.clamp(math.floor(tonumber(quantity) or 1), 1, 25)
	local inventory = getFolders(player)
	local stack = inventory:FindFirstChild(itemId)
	if not stack and #inventory:GetChildren() >= itemConfig.Capacity then return false, "Inventory is full" end
	stack = stack or createStack(inventory, itemId, 0)
	local previous = stack.Value
	stack.Value = math.min(definition.MaximumStack, stack.Value + quantity)
	local granted = stack.Value - previous
	if granted <= 0 then return false, definition.DisplayName .. " stack is full" end
	local message = string.format("Received %d x %s", granted, definition.DisplayName)
	if not silent then notify(player, "Loot", message, itemId, granted) end
	if questService and definition.Category == "Material" then questService.Record(player, "Material", granted) end
	return true, message
end

function InventoryService.SetQuestService(service)
	questService = service
end

function InventoryService.RollLoot(player, enemy)
	if enemy:GetAttribute("IsPractice") then return end
	local tables = {itemConfig.LootTables[enemy:GetAttribute("EnemyType") or "Basic"]}
	if enemy:GetAttribute("IsElite") then table.insert(tables, itemConfig.LootTables.Elite) end
	for _, lootTable in ipairs(tables) do
		for _, entry in ipairs(lootTable or {}) do
			if math.random(1, 100) <= entry.Weight then
				local success = InventoryService.Grant(player, entry.ItemId, 1)
				if success then inventoryEvent:FireClient(player, "LootWorld", {ItemId = entry.ItemId, Origin = enemy:GetPivot().Position, Rarity = itemConfig.Items[entry.ItemId].Rarity}) end
			end
		end
	end
end

function InventoryService.GrantBossLoot(player, boss)
	InventoryService.Grant(player, "BossCore", 1)
	if boss then inventoryEvent:FireClient(player, "LootWorld", {ItemId = "BossCore", Origin = boss:GetPivot().Position, Rarity = "Epic"}) end
	for _, entry in ipairs(itemConfig.LootTables.Boss) do
		if math.random(1, 100) <= entry.Weight then
			local success = InventoryService.Grant(player, entry.ItemId, 1)
			if success and boss then inventoryEvent:FireClient(player, "LootWorld", {ItemId = entry.ItemId, Origin = boss:GetPivot().Position, Rarity = itemConfig.Items[entry.ItemId].Rarity}) end
		end
	end
end

function InventoryService.Buy(player, itemId)
	local definition = itemConfig.Items[itemId]
	local price = definition and definition.BuyPrice
	if not price then return false, "That item is not sold here" end
	if (player:GetAttribute("Coins") or 0) < price then return false, "Not enough gold" end
	local success, message = InventoryService.Grant(player, itemId, 1, true)
	if not success then return false, message end
	player:SetAttribute("Coins", (player:GetAttribute("Coins") or 0) - price)
	notify(player, "Purchase", "Purchased " .. definition.DisplayName, itemId, 1)
	return true, "Purchased " .. definition.DisplayName
end

function InventoryService.Sell(player, itemId)
	local definition = itemConfig.Items[itemId]
	local inventory, equipment = getFolders(player)
	local stack = inventory:FindFirstChild(itemId)
	if not definition or not definition.BuyPrice or not stack or stack.Value <= 0 then return false, "That item cannot be sold" end
	if stack:GetAttribute("Locked") then return false, "Unlock the item before selling it" end
	for _, slot in ipairs(equipment:GetChildren()) do if slot:IsA("StringValue") and slot.Value == itemId then return false, "Unequip the item before selling it" end end
	stack.Value -= 1
	if stack.Value <= 0 then stack:Destroy() end
	local value = math.max(1, math.floor(definition.BuyPrice * 0.35))
	progression.AddCoins(player, value)
	return true, string.format("Sold %s for %d gold", definition.DisplayName, value)
end

local function equip(player, itemId)
	local inventory, equipment = getFolders(player)
	local stack, definition = inventory:FindFirstChild(itemId), itemConfig.Items[itemId]
	if not stack or stack.Value <= 0 or not definition or not definition.EquipSlot then return false, "That item cannot be equipped" end
	local slotName = definition.EquipSlot
	if slotName == "Artifact" then
		for index = 1, 3 do
			local candidate = equipment:FindFirstChild("Artifact" .. index)
			if candidate.Value == "" or candidate.Value == itemId then slotName = candidate.Name break end
		end
		if slotName == "Artifact" then slotName = "Artifact1" end
	end
	local slot = equipment:FindFirstChild(slotName)
	if not slot then return false, "No compatible equipment slot is available" end
	for _, other in ipairs(equipment:GetChildren()) do if other:IsA("StringValue") and other.Value == itemId then other.Value = "" end end
	slot.Value = itemId
	refreshEquipmentStats(player)
	return true, "Equipped " .. definition.DisplayName
end

local function unequip(player, slotName)
	local _, equipment = getFolders(player)
	local slot = equipment:FindFirstChild(tostring(slotName))
	if not slot or not slot:IsA("StringValue") or slot.Value == "" then return false, "Equipment slot is already empty" end
	local name = itemConfig.Items[slot.Value] and itemConfig.Items[slot.Value].DisplayName or slot.Value
	slot.Value = ""
	refreshEquipmentStats(player)
	return true, "Unequipped " .. name
end

local function useItem(player, itemId)
	local inventory = getFolders(player)
	local stack, definition = inventory:FindFirstChild(itemId), itemConfig.Items[itemId]
	local consumable = definition and definition.Consumable
	if not stack or stack.Value <= 0 or not consumable then return false, "Consumable is unavailable" end
	consumableReadyAt[player] = consumableReadyAt[player] or {}
	if os.clock() < (consumableReadyAt[player][itemId] or 0) then return false, "Consumable is cooling down" end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if consumable.Kind == "Health" then
		if not humanoid or humanoid.Health <= 0 or humanoid.Health >= humanoid.MaxHealth then return false, "Health is already full" end
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + consumable.Amount)
	elseif consumable.Kind == "MP" then
		local maxMP = player:GetAttribute("MaxMP") or 100
		if (player:GetAttribute("MP") or 0) >= maxMP then return false, "MP is already full" end
		player:SetAttribute("MP", math.min(maxMP, (player:GetAttribute("MP") or 0) + consumable.Amount))
		player:SetAttribute("Energy", player:GetAttribute("MP"))
	elseif consumable.Kind == "DamageBuff" then
		buffTokens[player] = buffTokens[player] or {}
		local token = (buffTokens[player].Damage or 0) + 1
		buffTokens[player].Damage = token
		player:SetAttribute("ConsumableDamageMultiplier", consumable.Multiplier)
		task.delay(consumable.Duration, function() if player.Parent and buffTokens[player] and buffTokens[player].Damage == token then player:SetAttribute("ConsumableDamageMultiplier", 1) end end)
	elseif consumable.Kind == "DefenseBuff" then
		buffTokens[player] = buffTokens[player] or {}
		local token = (buffTokens[player].Defense or 0) + 1
		buffTokens[player].Defense = token
		player:SetAttribute("ConsumableDefense", consumable.Amount)
		player:SetAttribute("Defense", (player:GetAttribute("EquipmentDefense") or 0) + consumable.Amount)
		task.delay(consumable.Duration, function()
			if player.Parent and buffTokens[player] and buffTokens[player].Defense == token then
				player:SetAttribute("ConsumableDefense", 0)
				player:SetAttribute("Defense", player:GetAttribute("EquipmentDefense") or 0)
			end
		end)
	elseif consumable.Kind == "RegenBuff" then
		buffTokens[player] = buffTokens[player] or {}
		local token = (buffTokens[player].Regen or 0) + 1
		buffTokens[player].Regen = token
		player:SetAttribute("BonusMPRegen", consumable.Amount)
		task.delay(consumable.Duration, function() if player.Parent and buffTokens[player] and buffTokens[player].Regen == token then player:SetAttribute("BonusMPRegen", 0) end end)
	end
	stack.Value -= 1
	if stack.Value <= 0 then stack:Destroy() end
	consumableReadyAt[player][itemId] = os.clock() + consumable.Cooldown
	return true, "Used " .. definition.DisplayName
end

local function craft(player, itemId)
	local recipe, definition = itemConfig.Recipes[itemId], itemConfig.Items[itemId]
	local inventory = getFolders(player)
	if not recipe or not definition then return false, "Recipe is unavailable" end
	for ingredientId, required in pairs(recipe.Ingredients) do
		local stack = inventory:FindFirstChild(ingredientId)
		if not stack or stack.Value < required then return false, "Missing crafting materials" end
	end
	local output = inventory:FindFirstChild(itemId)
	if not output and #inventory:GetChildren() >= itemConfig.Capacity then return false, "Inventory is full" end
	if output and output.Value + recipe.Quantity > definition.MaximumStack then return false, "Output stack is full" end
	for ingredientId, required in pairs(recipe.Ingredients) do
		local stack = inventory[ingredientId]
		stack.Value -= required
		if stack.Value <= 0 then stack:Destroy() end
	end
	InventoryService.Grant(player, itemId, recipe.Quantity, true)
	return true, "Crafted " .. recipe.Quantity .. " x " .. definition.DisplayName
end

function InventoryService.Start(config, saves, progressionModule, progressionBalance)
	itemConfig, saveService, progression, progressionConfig = config, saves, progressionModule, progressionBalance
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remotes:WaitForChild("InventoryRemote")
	inventoryEvent = remotes:WaitForChild("InventoryEvent")
	remote.OnServerInvoke = function(player, action, payload)
		payload = type(payload) == "table" and payload or {}
		if not player:GetAttribute("InventoryReady") then return response(false, "Inventory is still loading", getState(player)) end
		local success, message
		if action == "GetState" then return response(true, "Inventory ready", getState(player))
		elseif action == "Equip" then success, message = equip(player, tostring(payload.ItemId))
		elseif action == "Unequip" then success, message = unequip(player, payload.Slot)
		elseif action == "Use" then success, message = useItem(player, tostring(payload.ItemId))
		elseif action == "Craft" then success, message = craft(player, tostring(payload.ItemId))
		elseif action == "Favorite" or action == "Lock" then
			local inventory = getFolders(player)
			local stack = inventory:FindFirstChild(tostring(payload.ItemId))
			if stack then
				local attribute = action == "Favorite" and "Favorite" or "Locked"
				stack:SetAttribute(attribute, not stack:GetAttribute(attribute))
				success, message = true, attribute .. " updated"
			else success, message = false, "Item not found" end
		else return response(false, "Unknown inventory action", getState(player)) end
		if success then notify(player, "Inventory", message) end
		return response(success, message, getState(player))
	end
	Players.PlayerAdded:Connect(function(player) task.spawn(setupPlayer, player) end)
	for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
	Players.PlayerRemoving:Connect(function(player) consumableReadyAt[player], buffTokens[player] = nil, nil end)
end

return InventoryService
