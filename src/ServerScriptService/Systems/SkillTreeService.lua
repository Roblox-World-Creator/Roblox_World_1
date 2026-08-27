local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkillTreeService = {}
local config
local progression
local progressionConfig

local function refresh(player)
	local folder = player:FindFirstChild("Skills")
	if not folder then return end
	for id, definition in pairs(config.Nodes) do
		local rank = folder:FindFirstChild(id) and folder[id].Value or 0
		player:SetAttribute(definition.Attribute, (definition.Base or 0) + rank * definition.PerRank)
	end
	if progression and progressionConfig then progression.RefreshStats(player, progressionConfig) end
end

local function requirementStatus(player, definition, ranks)
	local level = player:GetAttribute("Level") or 1
	if level < (definition.RequiredLevel or 1) then return false, "LEVEL " .. tostring(definition.RequiredLevel) end
	for _, requirement in ipairs(definition.Prerequisites or {}) do
		if (ranks[requirement.Id] or 0) < (requirement.Rank or 1) then
			local requiredNode = config.Nodes[requirement.Id]
			return false, string.format("%s %d", requiredNode and requiredNode.DisplayName or requirement.Id, requirement.Rank or 1)
		end
	end
	return true, "AVAILABLE"
end

local function state(player)
	local ranks = {}
	local folder = player:FindFirstChild("Skills")
	for _, value in ipairs(folder and folder:GetChildren() or {}) do ranks[value.Name] = value.Value end
	local nodes = {}
	for id, definition in pairs(config.Nodes) do
		local available, reason = requirementStatus(player, definition, ranks)
		nodes[id] = {Available = available, Reason = reason}
	end
	return {SkillPoints = player:GetAttribute("SkillPoints") or 0, ElementPoints = player:GetAttribute("ElementPoints") or 0, Ranks = ranks, Nodes = nodes}
end

local function purchase(player, id)
	local definition = config.Nodes[id]
	local folder = player:FindFirstChild("Skills")
	local rank = folder and folder:FindFirstChild(id)
	if not definition or not rank then return false, "Unknown skill" end
	local ranks = {}
	for _, value in ipairs(folder:GetChildren()) do ranks[value.Name] = value.Value end
	local available, reason = requirementStatus(player, definition, ranks)
	if not available then return false, "Locked: " .. reason end
	if rank.Value >= definition.MaximumRank then return false, "Skill is already max rank" end
	local currency = definition.Tree == "Universal" and "SkillPoints" or "ElementPoints"
	local cost = definition.Cost or 1
	if (player:GetAttribute(currency) or 0) < cost then return false, "Not enough " .. currency end
	player:SetAttribute(currency, (player:GetAttribute(currency) or 0) - cost)
	rank.Value += 1
	refresh(player)
	return true, string.format("%s rank %d", definition.DisplayName, rank.Value)
end

local function setup(player, saveService)
	while player.Parent and not player:GetAttribute("DataLoaded") do player:GetAttributeChangedSignal("DataLoaded"):Wait() end
	if not player.Parent then return end
	local data = saveService.GetLoadedData(player) or {}
	local loaded = type(data.Skills) == "table" and data.Skills or {}
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Skills", player
	local spentUniversal, spentElement = 0, 0
	for id, definition in pairs(config.Nodes) do
		local value = Instance.new("IntValue")
		value.Name = id
		value.Value = math.clamp(math.floor(tonumber(loaded[id]) or 0), 0, definition.MaximumRank)
		value.Parent = folder
		if definition.Tree == "Universal" then spentUniversal += value.Value * (definition.Cost or 1) else spentElement += value.Value * (definition.Cost or 1) end
	end
	local level = player:GetAttribute("Level") or 1
	local legacy = (tonumber(data.SchemaVersion) or 1) < 4
	player:SetAttribute("SkillPoints", math.max(0, legacy and ((level - 1) * config.PointsPerLevel - spentUniversal) or (tonumber(data.SkillPoints) or 0)))
	player:SetAttribute("ElementPoints", math.max(0, legacy and (math.floor((level - 1) / config.ElementPointsEveryLevels) - spentElement) or (tonumber(data.ElementPoints) or 0)))
	player:SetAttribute("SkillPointsGrantedLevel", level)
	player:GetAttributeChangedSignal("Level"):Connect(function()
		local newLevel = player:GetAttribute("Level") or level
		local previous = player:GetAttribute("SkillPointsGrantedLevel") or newLevel
		if newLevel > previous then
			player:SetAttribute("SkillPoints", (player:GetAttribute("SkillPoints") or 0) + (newLevel - previous) * config.PointsPerLevel)
			player:SetAttribute("ElementPoints", (player:GetAttribute("ElementPoints") or 0) + math.floor(newLevel / config.ElementPointsEveryLevels) - math.floor(previous / config.ElementPointsEveryLevels))
		end
		player:SetAttribute("SkillPointsGrantedLevel", newLevel)
	end)
	refresh(player)
end

function SkillTreeService.Grant(player, amount, elementAmount)
	player:SetAttribute("SkillPoints", (player:GetAttribute("SkillPoints") or 0) + math.max(0, math.floor(tonumber(amount) or 0)))
	player:SetAttribute("ElementPoints", (player:GetAttribute("ElementPoints") or 0) + math.max(0, math.floor(tonumber(elementAmount) or 0)))
end

function SkillTreeService.UnlockAll(player)
	local folder, count = player:FindFirstChild("Skills"), 0
	if not folder then return count end
	for id, definition in pairs(config.Nodes) do
		local value = folder:FindFirstChild(id)
		if value then count += math.max(0, definition.MaximumRank - value.Value); value.Value = definition.MaximumRank end
	end
	refresh(player)
	return count
end

function SkillTreeService.Start(skillConfig, saveService, progressionService, playerProgressionConfig)
	config, progression, progressionConfig = skillConfig, progressionService, playerProgressionConfig
	local remote = ReplicatedStorage.Remotes:WaitForChild("SkillRemote")
	remote.OnServerInvoke = function(player, action, payload)
		if action == "GetState" then return {Success = true, State = state(player)} end
		if action == "Purchase" then local ok, message = purchase(player, tostring(payload and payload.SkillId)); return {Success = ok, Message = message, State = state(player)} end
		return {Success = false, Message = "Unknown skill action", State = state(player)}
	end
	Players.PlayerAdded:Connect(function(player) task.spawn(setup, player, saveService) end)
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(setup, player, saveService) end
end

return SkillTreeService
