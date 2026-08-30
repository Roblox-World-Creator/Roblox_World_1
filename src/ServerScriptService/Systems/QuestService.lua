local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestService = {}
local config
local saveService
local progression
local progressionConfig
local inventoryService
local questEvent

local function getFolders(player)
	local progress = player:FindFirstChild("QuestProgress") or Instance.new("Folder")
	progress.Name, progress.Parent = "QuestProgress", player
	local claims = player:FindFirstChild("QuestClaims") or Instance.new("Folder")
	claims.Name, claims.Parent = "QuestClaims", player
	local active = player:FindFirstChild("QuestActive") or Instance.new("Folder")
	active.Name, active.Parent = "QuestActive", player
	local history = player:FindFirstChild("QuestHistory") or Instance.new("Folder")
	history.Name, history.Parent = "QuestHistory", player
	return progress, claims, active, history
end

local function getState(player)
	local progress, claims, active, history = getFolders(player)
	local result = {}
	for questId, definition in pairs(config) do
		local value, claimed = progress:FindFirstChild(questId), claims:FindFirstChild(questId)
		table.insert(result, {Id = questId, Progress = value and value.Value or 0, Goal = definition.Goal, Claimed = claimed and claimed.Value or false, Active = active:FindFirstChild(questId) and active[questId].Value or false, Completions = history:FindFirstChild(questId) and history[questId].Value or 0})
	end
	table.sort(result, function(left, right) return left.Id < right.Id end)
	return result
end

local function setupPlayer(player)
	while player.Parent and not player:GetAttribute("DataLoaded") do player:GetAttributeChangedSignal("DataLoaded"):Wait() end
	if not player.Parent then return end
	local progress, claims, active, history = getFolders(player)
	local data = saveService.GetLoadedData(player) or {}
	for questId, definition in pairs(config) do
		local value = progress:FindFirstChild(questId) or Instance.new("IntValue")
		value.Name, value.Value, value.Parent = questId, math.clamp(math.floor(tonumber((data.Quests or {})[questId]) or 0), 0, definition.Goal), progress
		local claimed = claims:FindFirstChild(questId) or Instance.new("BoolValue")
		claimed.Name, claimed.Value, claimed.Parent = questId, (data.QuestClaims or {})[questId] == true, claims
		local started = active:FindFirstChild(questId) or Instance.new("BoolValue")
		started.Name, started.Value, started.Parent = questId, (data.QuestActive or {})[questId] == true, active
		local completed = history:FindFirstChild(questId) or Instance.new("IntValue")
		completed.Name, completed.Value, completed.Parent = questId, math.max(0, math.floor(tonumber((data.QuestHistory or {})[questId]) or 0)), history
	end
	player:SetAttribute("QuestsReady", true)
end

function QuestService.Record(player, eventName, amount, context)
	context = type(context) == "table" and context or {}
	local progress, claims, active = getFolders(player)
	for questId, definition in pairs(config) do
		local value, claimed = progress:FindFirstChild(questId), claims:FindFirstChild(questId)
		local realmMatches = not definition.RealmId or definition.RealmId == context.RealmId
		local enemyMatches = not definition.EnemyType or definition.EnemyType == context.EnemyType
		if definition.Event == eventName and realmMatches and enemyMatches and value and claimed and active[questId] and active[questId].Value and not claimed.Value and value.Value < definition.Goal then
			value.Value = math.min(definition.Goal, value.Value + math.max(0, math.floor(tonumber(amount) or 1)))
			questEvent:FireClient(player, "Progress", {QuestId = questId, Progress = value.Value, Goal = definition.Goal, Complete = value.Value >= definition.Goal})
		end
	end
end

function QuestService.OpenRealm(player, realmId)
	if questEvent and player and player.Parent then questEvent:FireClient(player, "OpenRealm", {RealmId = realmId}) end
end

local function claim(player, questId)
	local definition = config[questId]
	local progress, claims, active, history = getFolders(player)
	local value, claimed = progress:FindFirstChild(questId), claims:FindFirstChild(questId)
	if not definition or not value or value.Value < definition.Goal then return false, "Quest is not complete" end
	if not active:FindFirstChild(questId) or not active[questId].Value then return false, "Quest is not active" end
	if claimed.Value then return false, "Quest reward already claimed" end
	claimed.Value = true
	active[questId].Value = false
	history[questId].Value += 1
	progression.AddXP(player, definition.RewardXP, progressionConfig)
	progression.AddCoins(player, definition.RewardGold)
	if definition.RewardItem then inventoryService.Grant(player, definition.RewardItem, definition.RewardQuantity or 1) end
	return true, string.format("Claimed %s: +%d XP, +%d gold", definition.DisplayName, definition.RewardXP, definition.RewardGold)
end

local function startQuest(player, questId)
	local definition = config[questId]
	local progress, claims, active = getFolders(player)
	if not definition or not active:FindFirstChild(questId) then return false, "Unknown quest" end
	if active[questId].Value then return false, "Quest is already active" end
	progress[questId].Value = 0
	claims[questId].Value = false
	active[questId].Value = true
	return true, "Started " .. definition.DisplayName
end

function QuestService.Start(questConfig, saves, progressionModule, balance, inventory)
	config, saveService, progression, progressionConfig, inventoryService = questConfig, saves, progressionModule, balance, inventory
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remotes:WaitForChild("QuestRemote")
	questEvent = remotes:WaitForChild("QuestEvent")
	remote.OnServerInvoke = function(player, action, payload)
		if not player:GetAttribute("QuestsReady") then return {Success = false, Message = "Quests are loading", Quests = {}} end
		if action == "GetState" then return {Success = true, Message = "Quest log ready", Quests = getState(player)} end
		if action == "Start" then
			local success, message = startQuest(player, tostring(type(payload) == "table" and payload.QuestId or ""))
			return {Success = success, Message = message, Quests = getState(player)}
		end
		if action == "Claim" then
			local success, message = claim(player, tostring(type(payload) == "table" and payload.QuestId or ""))
			return {Success = success, Message = message, Quests = getState(player)}
		end
		return {Success = false, Message = "Unknown quest action", Quests = getState(player)}
	end
	Players.PlayerAdded:Connect(function(player) task.spawn(setupPlayer, player) end)
	for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
	inventoryService.SetQuestService(QuestService)
end

return QuestService
