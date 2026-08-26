local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PowerService = {}
local config
local loadouts = {}

local defaultAttacks = {"EnergyBolt", "EnergyBurst", "EnergyBeam", "GravityPulse", "ChainLightning", "Tornado"}
local defaultMotion = {"PowerDash", "Dodge"}

local function unlocked(player, ability)
	return player:GetAttribute("AdminAllPowersUnlocked") or ((player:GetAttribute("Level") or 1) >= (ability.RequiredLevel or 1) and (player:GetAttribute("Evolution") or 0) >= (ability.RequiredEvolution or 0))
end

local function copy(values)
	local result = {}
	for _, value in ipairs(values) do table.insert(result, value) end
	return result
end

local function setAttributes(player, loadout)
	player:SetAttribute("ActiveAttacks", table.concat(loadout.Attacks, ","))
	player:SetAttribute("ActiveMotion", table.concat(loadout.Motion, ","))
end

local function validList(player, values, maximum, definitions)
	if type(values) ~= "table" or #values > maximum then return false end
	local seen = {}
	for _, name in ipairs(values) do
		if type(name) ~= "string" or seen[name] or not definitions[name] or not unlocked(player, definitions[name]) then return false end
		seen[name] = true
	end
	return true
end

function PowerService.IsActive(player, abilityName)
	local loadout = loadouts[player]
	if not loadout then return true end
	return table.find(loadout.Attacks, abilityName) ~= nil
end

function PowerService.IsMotionActive(player, powerName)
	local loadout = loadouts[player]
	return not loadout or table.find(loadout.Motion, powerName) ~= nil
end

function PowerService.Start(progressionConfig)
	config = progressionConfig
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remotes:FindFirstChild("PowerRemote") or Instance.new("RemoteFunction")
	remote.Name = "PowerRemote"
	remote.Parent = remotes

	local function setup(player)
		local loadout = {Attacks = copy(defaultAttacks), Motion = copy(defaultMotion)}
		loadouts[player] = loadout
		setAttributes(player, loadout)
	end
	Players.PlayerAdded:Connect(setup)
	for _, player in ipairs(Players:GetPlayers()) do setup(player) end

	remote.OnServerInvoke = function(player, action, payload)
		if action == "GetState" then
			local loadout = loadouts[player]
			local unlockedPowers = {}
			for name, ability in pairs(config.Abilities) do unlockedPowers[name] = unlocked(player, ability) end
			return {Success = true, Attacks = copy(loadout.Attacks), Motion = copy(loadout.Motion), Unlocked = unlockedPowers}
		end
		if action ~= "SetLoadout" or type(payload) ~= "table" then return {Success = false, Message = "Invalid loadout"} end
		if not validList(player, payload.Attacks, 6, config.Abilities) or not validList(player, payload.Motion, 2, {PowerDash = {}, Dodge = {}}) then
			return {Success = false, Message = "Choose unlocked powers only"}
		end
		local loadout = {Attacks = copy(payload.Attacks), Motion = copy(payload.Motion)}
		loadouts[player] = loadout
		setAttributes(player, loadout)
		return {Success = true, Message = "Power loadout updated", Attacks = copy(loadout.Attacks), Motion = copy(loadout.Motion)}
	end

	Players.PlayerRemoving:Connect(function(player) loadouts[player] = nil end)
end

return PowerService
