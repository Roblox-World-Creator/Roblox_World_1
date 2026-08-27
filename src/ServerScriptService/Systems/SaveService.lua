local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SaveService = {}

local store
local config
local sessions = {}
local saving = {}
local persistentStorageEnabled = false

local SAVED_ATTRIBUTES = {
	"Level",
	"XP",
	"Coins",
	"Evolution",
	"SkillPoints",
	"ElementPoints",
	"FormPoints",
}

local function copyDefaults(defaults)
	local result = {}
	for key, value in pairs(defaults) do
		result[key] = type(value) == "table" and copyDefaults(value) or value
	end
	return result
end

local function serializeInventory(player)
	local result = {}
	local inventory = player:FindFirstChild("Inventory")
	if inventory then
		for _, stack in ipairs(inventory:GetChildren()) do
			if stack:IsA("IntValue") and stack.Value > 0 then
				result[stack.Name] = {
					Count = stack.Value,
					Favorite = stack:GetAttribute("Favorite") == true,
					Locked = stack:GetAttribute("Locked") == true,
				}
			end
		end
	end
	return result
end

local function serializeEquipment(player)
	local result = {}
	local equipment = player:FindFirstChild("Equipment")
	if equipment then
		for _, slot in ipairs(equipment:GetChildren()) do
			if slot:IsA("StringValue") then
				result[slot.Name] = slot.Value
			end
		end
	end
	return result
end

local function serializeValueFolder(player, folderName)
	local result = {}
	local folder = player:FindFirstChild(folderName)
	if folder then
		for _, value in ipairs(folder:GetChildren()) do
			if value:IsA("NumberValue") or value:IsA("IntValue") or value:IsA("BoolValue") then result[value.Name] = value.Value end
		end
	end
	return result
end

function SaveService.GetLoadedData(player)
	return sessions[player]
end

local function retry(label, callback)
	local lastError
	for attempt = 1, config.RetryCount do
		local success, result = pcall(callback)
		if success then
			return true, result
		end
		lastError = result
		warn(string.format("%s failed (%d/%d): %s", label, attempt, config.RetryCount, tostring(result)))
		if attempt < config.RetryCount then
			task.wait(config.RetryDelaySeconds * attempt)
		end
	end
	return false, lastError
end

function SaveService.Load(player, defaults)
	local data = copyDefaults(defaults)
	if not persistentStorageEnabled then
		sessions[player] = data
		return data
	end

	local success, saved = retry("Player data load", function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	if success and type(saved) == "table" then
		for key, defaultValue in pairs(defaults) do
			if typeof(saved[key]) == typeof(defaultValue) then
				data[key] = saved[key]
			end
		end
		data.SchemaVersion = math.max(1, tonumber(saved.SchemaVersion) or 1)
	end
	sessions[player] = data
	return data
end

function SaveService.Save(player)
	if not sessions[player] or saving[player] then
		return false
	end

	local payload = {
		SchemaVersion = config.SchemaVersion,
	}
	for _, attribute in ipairs(SAVED_ATTRIBUTES) do
		payload[attribute] = player:GetAttribute(attribute)
	end
	payload.Inventory = serializeInventory(player)
	payload.Equipment = serializeEquipment(player)
	payload.Mastery = serializeValueFolder(player, "PowerMastery")
	payload.Quests = serializeValueFolder(player, "QuestProgress")
	payload.QuestClaims = serializeValueFolder(player, "QuestClaims")
	payload.Skills = serializeValueFolder(player, "Skills")
	payload.Transformations = serializeValueFolder(player, "Transformations")
	payload.FormSkills = serializeValueFolder(player, "FormSkills")
	payload.QuestActive = serializeValueFolder(player, "QuestActive")
	payload.QuestHistory = serializeValueFolder(player, "QuestHistory")
	local function attributeList(name)
		local result = {}
		for _, value in ipairs(string.split(player:GetAttribute(name) or "", ",")) do if value ~= "" then table.insert(result, value) end end
		return result
	end
	payload.PowerLoadout = {Attacks = attributeList("ActiveAttacks"), Motion = attributeList("ActiveMotion")}
	for _, key in ipairs({"UnlockedWorlds", "UnlockedElements", "WeaponMastery", "BossKills"}) do
		payload[key] = type(sessions[player][key]) == "table" and sessions[player][key] or {}
	end
	payload.Settings = {
		EffectQuality = player:GetAttribute("EffectQuality") or "HIGH",
		CameraShakeEnabled = player:GetAttribute("CameraShakeEnabled") ~= false,
		DamageNumbersEnabled = player:GetAttribute("DamageNumbersEnabled") ~= false,
	}
	sessions[player] = payload

	if not persistentStorageEnabled then
		return true
	end

	saving[player] = true
	local success = retry("Player data save", function()
		store:UpdateAsync("Player_" .. player.UserId, function()
			return payload
		end)
	end)
	saving[player] = nil
	return success
end

function SaveService.Start(saveConfig)
	config = saveConfig
	persistentStorageEnabled = game.GameId ~= 0 and (not RunService:IsStudio() or config.EnableInStudio)
	workspace:SetAttribute("SaveMode", persistentStorageEnabled and "DataStore" or "StudioMemory")
	if persistentStorageEnabled then
		store = DataStoreService:GetDataStore(config.DataStoreName)
	end

	Players.PlayerRemoving:Connect(function(player)
		SaveService.Save(player)
		sessions[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(config.AutoSaveSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(SaveService.Save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for _, player in ipairs(Players:GetPlayers()) do
			pending += 1
			task.spawn(function()
				SaveService.Save(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 8
		repeat
			task.wait(0.1)
		until pending == 0 or os.clock() >= deadline
	end)
end

return SaveService
