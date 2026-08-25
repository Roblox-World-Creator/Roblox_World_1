local Players = game:GetService("Players")

local MasteryService = {}
local config
local saveService

local function xpForLevel(level)
	return config.Mastery.XPBase * level * level
end

local function refresh(stack)
	local level = 0
	while level < config.Mastery.MaximumLevel and stack.Value >= xpForLevel(level + 1) do level += 1 end
	stack:SetAttribute("Level", level)
	stack:SetAttribute("NextXP", level < config.Mastery.MaximumLevel and xpForLevel(level + 1) or stack.Value)
end

local function setupPlayer(player)
	while player.Parent and not player:GetAttribute("DataLoaded") do player:GetAttributeChangedSignal("DataLoaded"):Wait() end
	if not player.Parent then return end
	local folder = player:FindFirstChild("PowerMastery") or Instance.new("Folder")
	folder.Name, folder.Parent = "PowerMastery", player
	local loaded = (saveService.GetLoadedData(player) or {}).Mastery or {}
	for abilityName in pairs(config.Abilities) do
		local stack = folder:FindFirstChild(abilityName) or Instance.new("NumberValue")
		stack.Name, stack.Value, stack.Parent = abilityName, math.max(0, tonumber(loaded[abilityName]) or 0), folder
		refresh(stack)
	end
	player:SetAttribute("MasteryReady", true)
end

function MasteryService.Add(player, abilityName, amount)
	local folder = player and player:FindFirstChild("PowerMastery")
	local stack = folder and folder:FindFirstChild(abilityName)
	if not stack then return end
	stack.Value += math.max(0, tonumber(amount) or 0)
	refresh(stack)
end

function MasteryService.GetLevel(player, abilityName)
	local folder = player and player:FindFirstChild("PowerMastery")
	local stack = folder and folder:FindFirstChild(abilityName)
	return stack and (stack:GetAttribute("Level") or 0) or 0
end

function MasteryService.Start(progressionConfig, saves)
	config, saveService = progressionConfig, saves
	Players.PlayerAdded:Connect(function(player) task.spawn(setupPlayer, player) end)
	for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
end

return MasteryService
