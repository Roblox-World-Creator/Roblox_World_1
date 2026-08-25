local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage.Shared.WorldConfig)
local FlameBoosterConfig = require(ReplicatedStorage.Shared.FlameBoosterConfig)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local EnemyConfig = require(ReplicatedStorage.Shared.EnemyConfig)
local ProgressionConfig = require(ReplicatedStorage.Shared.ProgressionConfig)
local EvolutionConfig = require(ReplicatedStorage.Shared.EvolutionConfig)
local FlameBooster = require(script.Parent.Systems.FlameBooster)
local WaveDefense = require(script.Parent.Systems.WaveDefense)
local PlayerProgression = require(script.Parent.Systems.PlayerProgression)
local CombatService = require(script.Parent.Systems.CombatService)
local EvolutionService = require(script.Parent.Systems.EvolutionService)

local marker = workspace:FindFirstChild("LiveSyncMarker")
if not marker then
	marker = Instance.new("Part")
	marker.Name = "LiveSyncMarker"
	marker.Anchored = true
	marker.Size = Vector3.new(4, 1, 4)
	marker.Position = Vector3.new(0, 2, 0)
	marker.Parent = workspace
end

marker.Color = WorldConfig.SpawnColor
workspace:SetAttribute("WorldVersion", WorldConfig.Version)
workspace:SetAttribute("WorldStatus", "Booting")
workspace:SetAttribute("WorldError", "")

local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
for _, name in ipairs({"CombatRemote", "AbilityRemote", "CombatFeedback", "EvolutionRemote"}) do
	if not remotes:FindFirstChild(name) then
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotes
	end
end

local function startSystem(name, callback)
	local success, errorMessage = pcall(callback)
	if not success then
		workspace:SetAttribute("WorldError", name .. ": " .. tostring(errorMessage))
		warn(string.format("%s failed to start: %s", name, tostring(errorMessage)))
		return false
	end
	return true
end

print(string.format("%s loaded through Rojo", WorldConfig.WorldName))
print("Live sync test reached Studio")

startSystem("Combat", function()
	CombatService.Start(ProgressionConfig, PlayerProgression)
end)
startSystem("WaveDefense", function()
	WaveDefense.Start(GameConfig, EnemyConfig)
end)
startSystem("PlayerProgression", function()
	PlayerProgression.Start(ProgressionConfig)
end)
startSystem("FlameBooster", function()
	FlameBooster.Start(FlameBoosterConfig)
end)
startSystem("Evolution", function()
	EvolutionService.Start(EvolutionConfig)
end)
	if workspace:GetAttribute("WorldError") == "" then
	workspace:SetAttribute("WorldStatus", "Ready")
end