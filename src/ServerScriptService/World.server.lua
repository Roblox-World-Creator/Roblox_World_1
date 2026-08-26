local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage.Shared.WorldConfig)
local FlameBoosterConfig = require(ReplicatedStorage.Shared.FlameBoosterConfig)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local EnemyConfig = require(ReplicatedStorage.Shared.EnemyConfig)
local ProgressionConfig = require(ReplicatedStorage.Shared.ProgressionConfig)
local EvolutionConfig = require(ReplicatedStorage.Shared.EvolutionConfig)
local ResourceConfig = require(ReplicatedStorage.Shared.ResourceConfig)
local SaveConfig = require(ReplicatedStorage.Shared.SaveConfig)
local DebugConfig = require(ReplicatedStorage.Shared.DebugConfig)
local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)
local ItemConfig = require(ReplicatedStorage.Shared.ItemConfig)
local QuestConfig = require(ReplicatedStorage.Shared.QuestConfig)
local AdminConfig = require(script.Parent.Config.AdminConfig)
local FlameBooster = require(script.Parent.Systems.FlameBooster)
local WaveDefense = require(script.Parent.Systems.WaveDefense)
local PlayerProgression = require(script.Parent.Systems.PlayerProgression)
local CombatService = require(script.Parent.Systems.CombatService)
local EvolutionService = require(script.Parent.Systems.EvolutionService)
local DamageService = require(script.Parent.Systems.DamageService)
local SaveService = require(script.Parent.Systems.SaveService)
local MovementService = require(script.Parent.Systems.MovementService)
local WeaponService = require(script.Parent.Systems.WeaponService)
local DebugService = require(script.Parent.Systems.DebugService)
local AdminService = require(script.Parent.Systems.AdminService)
local InventoryService = require(script.Parent.Systems.InventoryService)
local StoreService = require(script.Parent.Systems.StoreService)
local MasteryService = require(script.Parent.Systems.MasteryService)
local QuestService = require(script.Parent.Systems.QuestService)
local SettingsService = require(script.Parent.Systems.SettingsService)
local PowerService = require(script.Parent.Systems.PowerService)

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
local remoteDefinitions = {
	CombatRemote = "RemoteEvent", AbilityRemote = "RemoteEvent", AbilityEffects = "RemoteEvent",
	CombatFeedback = "RemoteEvent", EvolutionRemote = "RemoteEvent", DashRemote = "RemoteEvent",
	DodgeRemote = "RemoteEvent", InventoryEvent = "RemoteEvent", QuestEvent = "RemoteEvent",
	SettingsRemote = "RemoteEvent", AdminRemote = "RemoteFunction", InventoryRemote = "RemoteFunction",
	StoreRemote = "RemoteFunction", QuestRemote = "RemoteFunction",
}
for name, className in pairs(remoteDefinitions) do
	local remote = remotes:FindFirstChild(name)
	if remote and remote.ClassName ~= className then
		remote:Destroy()
		remote = nil
	end
	if not remote then
		remote = Instance.new(className)
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
print("Evolution Ascendant server bootstrap reached Studio")

startSystem("SaveService", function()
	SaveService.Start(SaveConfig)
end)
startSystem("PlayerProgression", function()
	PlayerProgression.Start(ProgressionConfig, ResourceConfig, EvolutionConfig, SaveService)
end)
startSystem("Inventory", function()
	InventoryService.Start(ItemConfig, SaveService, PlayerProgression, ProgressionConfig)
end)
startSystem("Mastery", function()
	MasteryService.Start(ProgressionConfig, SaveService)
end)
startSystem("Quests", function()
	QuestService.Start(QuestConfig, SaveService, PlayerProgression, ProgressionConfig, InventoryService)
end)
startSystem("Settings", function()
	SettingsService.Start(SaveService)
end)
startSystem("Powers", function()
	PowerService.Start(ProgressionConfig)
end)
startSystem("Combat", function()
	CombatService.Start(ProgressionConfig, PlayerProgression, DamageService, InventoryService, MasteryService, QuestService, PowerService)
end)
startSystem("WaveDefense", function()
	WaveDefense.Start(GameConfig, EnemyConfig, WaveConfig, ProgressionConfig, PlayerProgression, InventoryService, QuestService)
end)
startSystem("Admin", function()
	AdminService.Start(AdminConfig, WaveDefense, InventoryService, ItemConfig, EvolutionService, PlayerProgression, ProgressionConfig)
end)
startSystem("Store", function()
	StoreService.Start(ItemConfig, InventoryService)
end)
startSystem("Movement", function()
	MovementService.Start(ResourceConfig, PowerService)
end)
startSystem("Weapons", function()
	WeaponService.Start(ItemConfig)
end)
startSystem("Debug", function()
	DebugService.Start(DebugConfig, ProgressionConfig, PlayerProgression)
end)
startSystem("FlameBooster", function()
	FlameBooster.Start(FlameBoosterConfig)
end)
startSystem("Evolution", function()
	EvolutionService.Start(EvolutionConfig, ProgressionConfig, PlayerProgression, ResourceConfig)
end)
if workspace:GetAttribute("WorldError") == "" then
	workspace:SetAttribute("WorldStatus", "Ready")
end
