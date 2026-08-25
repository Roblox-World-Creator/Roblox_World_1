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
	return progress, claims
end

local function getState(player)
	local progress, claims = getFolders(player)
	local result = {}
	for questId, definition in pairs(config) do
		local value, claimed = progress:FindFirstChild(questId), claims:FindFirstChild(questId)
		table.insert(result, {Id = questId, Progress = value and value.Value or 0, Goal = definition.Goal, Claimed = claimed and claimed.Value or false})
	end
	table.sort(result, function(left, right) return left.Id < right.Id end)
	return result
end

local function setupPlayer(player)
	while player.Parent and not player:GetAttribute("DataLoaded") do player:GetAttributeChangedSignal("DataLoaded"):Wait() end
	if not player.Parent then return end
	local progress, claims = getFolders(player)
	local data = saveService.GetLoadedData(player) or {}
	for questId, definition in pairs(config) do
		local value = progress:FindFirstChild(questId) or Instance.new("IntValue")
		value.Name, value.Value, value.Parent = questId, math.clamp(math.floor(tonumber((data.Quests or {})[questId]) or 0), 0, definition.Goal), progress
		local claimed = claims:FindFirstChild(questId) or Instance.new("BoolValue")
		claimed.Name, claimed.Value, claimed.Parent = questId, (data.QuestClaims or {})[questId] == true, claims
	end
	player:SetAttribute("QuestsReady", true)
end

function QuestService.Record(player, eventName, amount)
	local progress, claims = getFolders(player)
	for questId, definition in pairs(config) do
		local value, claimed = progress:FindFirstChild(questId), claims:FindFirstChild(questId)
		if definition.Event == eventName and value and claimed and not claimed.Value and value.Value < definition.Goal then
			value.Value = math.min(definition.Goal, value.Value + math.max(0, math.floor(tonumber(amount) or 1)))
			questEvent:FireClient(player, "Progress", {QuestId = questId, Progress = value.Value, Goal = definition.Goal, Complete = value.Value >= definition.Goal})
		end
	end
end

local function claim(player, questId)
	local definition = config[questId]
	local progress, claims = getFolders(player)
	local value, claimed = progress:FindFirstChild(questId), claims:FindFirstChild(questId)
	if not definition or not value or value.Value < definition.Goal then return false, "Quest is not complete" end
	if claimed.Value then return false, "Quest reward already claimed" end
	claimed.Value = true
	progression.AddXP(player, definition.RewardXP, progressionConfig)
	progression.AddCoins(player, definition.RewardGold)
	if definition.RewardItem then inventoryService.Grant(player, definition.RewardItem, definition.RewardQuantity or 1) end
	return true, string.format("Claimed %s: +%d XP, +%d gold", definition.DisplayName, definition.RewardXP, definition.RewardGold)
end

function QuestService.Start(questConfig, saves, progressionModule, balance, inventory)
	config, saveService, progression, progressionConfig, inventoryService = questConfig, saves, progressionModule, balance, inventory
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remotes:WaitForChild("QuestRemote")
	questEvent = remotes:WaitForChild("QuestEvent")
	remote.OnServerInvoke = function(player, action, payload)
		if not player:GetAttribute("QuestsReady") then return {Success = false, Message = "Quests are loading", Quests = {}} end
		if action == "GetState" then return {Success = true, Message = "Quest log ready", Quests = getState(player)} end
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
