local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PowerService = {}
local config
local loadouts = {}

local function unlocked(player, definition)
	return player:GetAttribute("AdminAllPowersUnlocked") or ((player:GetAttribute("Level") or 1) >= (definition.RequiredLevel or 1) and (player:GetAttribute("Evolution") or 0) >= (definition.RequiredEvolution or 0))
end

local function copy(values)
	local result = {}
	for _, value in ipairs(values or {}) do table.insert(result, value) end
	return result
end

local function setAttributes(player, loadout)
	player:SetAttribute("ActiveAttacks", table.concat(loadout.Attacks, ","))
	player:SetAttribute("ActiveMotion", table.concat(loadout.Motion, ","))
	player:SetAttribute("ActiveUltimate", loadout.Ultimate or "")
end

local function validAttacks(player, values)
	if type(values) ~= "table" or #values > 6 then return false end
	local seen = {}
	for _, name in ipairs(values) do
		local definition = config.Abilities[name]
		if type(name) ~= "string" or seen[name] or not definition or not unlocked(player, definition) then return false end
		seen[name] = true
	end
	return true
end

local function validMotion(player, values)
	if type(values) ~= "table" or #values ~= 2 then return false end
	local first, second = config.MotionPowers[values[1]], config.MotionPowers[values[2]]
	return first and second and first.Category == "Mobility" and second.Category == "Technique"
		and unlocked(player, first) and unlocked(player, second)
end

local function validUltimate(player, value)
	if value == nil or value == "" then return true end
	local definition = type(value) == "string" and config.Abilities[value]
	return definition ~= nil and unlocked(player, definition)
end

local function defaultLoadout(player)
	local attacks = {}
	for _, name in ipairs(config.AbilityOrder or {}) do
		if unlocked(player, config.Abilities[name]) and #attacks < 6 then table.insert(attacks, name) end
	end
	return {Attacks = attacks, Motion = {"PowerDash", "Dodge"}, Ultimate = attacks[#attacks] or ""}
end

local function setup(player, saveService)
	while player.Parent and not player:GetAttribute("DataLoaded") do player:GetAttributeChangedSignal("DataLoaded"):Wait() end
	if not player.Parent then return end
	local loadout = defaultLoadout(player)
	local data = saveService and saveService.GetLoadedData(player) or nil
	local saved = data and data.PowerLoadout
	if type(saved) == "table" then
		if type(saved.Attacks) == "table" and #saved.Attacks > 0 and validAttacks(player, saved.Attacks) then loadout.Attacks = copy(saved.Attacks) end
		if validMotion(player, saved.Motion) then loadout.Motion = copy(saved.Motion) end
		if saved.Ultimate ~= nil and validUltimate(player, saved.Ultimate) then loadout.Ultimate = saved.Ultimate or "" end
	end
	loadouts[player] = loadout
	setAttributes(player, loadout)
end

function PowerService.IsActive(player, abilityName)
	local loadout = loadouts[player]
	return loadout ~= nil and (table.find(loadout.Attacks, abilityName) ~= nil or loadout.Ultimate == abilityName)
end

function PowerService.IsMotionActive(player, powerName)
	local loadout = loadouts[player]
	return loadout ~= nil and table.find(loadout.Motion, powerName) ~= nil
end

function PowerService.GetMotionDefinition(powerName)
	return config and config.MotionPowers and config.MotionPowers[powerName]
end

function PowerService.Start(progressionConfig, saveService)
	config = progressionConfig
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remotes:FindFirstChild("PowerRemote") or Instance.new("RemoteFunction")
	remote.Name, remote.Parent = "PowerRemote", remotes

	Players.PlayerAdded:Connect(function(player) task.spawn(setup, player, saveService) end)
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(setup, player, saveService) end

	remote.OnServerInvoke = function(player, action, payload)
		local loadout = loadouts[player] or defaultLoadout(player)
		loadouts[player] = loadout
		if action == "GetState" then
			local unlockedPowers, unlockedMotion = {}, {}
			for name, ability in pairs(config.Abilities) do unlockedPowers[name] = unlocked(player, ability) end
			for name, definition in pairs(config.MotionPowers or {}) do unlockedMotion[name] = unlocked(player, definition) end
			return {Success = true, Attacks = copy(loadout.Attacks), Motion = copy(loadout.Motion), Ultimate = loadout.Ultimate or "", Unlocked = unlockedPowers, MotionUnlocked = unlockedMotion}
		end
		if action ~= "SetLoadout" or type(payload) ~= "table" then return {Success = false, Message = "Invalid loadout"} end
		if not validAttacks(player, payload.Attacks) then return {Success = false, Message = "Attack slots contain a locked or duplicate power"} end
		if not validMotion(player, payload.Motion) then return {Success = false, Message = "Slot 7 requires Mobility and slot 8 requires Technique"} end
		if not validUltimate(player, payload.Ultimate) then return {Success = false, Message = "Ultimate slot contains a locked power"} end
		loadout = {Attacks = copy(payload.Attacks), Motion = copy(payload.Motion), Ultimate = payload.Ultimate or ""}
		loadouts[player] = loadout
		setAttributes(player, loadout)
		return {Success = true, Message = "Power loadout saved", Attacks = copy(loadout.Attacks), Motion = copy(loadout.Motion), Ultimate = loadout.Ultimate}
	end

	Players.PlayerRemoving:Connect(function(player) loadouts[player] = nil end)
end

return PowerService
