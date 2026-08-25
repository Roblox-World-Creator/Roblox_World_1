local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminService = {}

local authorized = {}
local attempts = {}
local actionReadyAt = {}
local spawnReadyAt = {}
local damageBoostTokens = {}

local function response(success, message, data)
	return {
		Success = success,
		Message = message,
		Data = data,
	}
end

local function resolveTarget(requester, query)
	if query == nil or tostring(query) == "" or string.lower(tostring(query)) == "me" then
		return requester
	end
	local numericId = tonumber(query)
	if numericId then
		return Players:GetPlayerByUserId(math.floor(numericId))
	end
	local lowered = string.lower(tostring(query))
	local partial
	for _, player in ipairs(Players:GetPlayers()) do
		if string.lower(player.Name) == lowered or string.lower(player.DisplayName) == lowered then
			return player
		end
		if string.sub(string.lower(player.Name), 1, #lowered) == lowered then
			if partial then
				return nil
			end
			partial = player
		end
	end
	return partial
end

local function setGodMode(player, enabled)
	player:SetAttribute("AdminGodMode", enabled)
	local character = player.Character
	if not character then
		return
	end
	local existing = character:FindFirstChild("AdminGodMode")
	if enabled then
		local forceField = existing or Instance.new("ForceField")
		forceField.Name = "AdminGodMode"
		forceField.Visible = false
		forceField.Parent = character
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
		end
	elseif existing then
		existing:Destroy()
	end
end

local function applyCharacterOverrides(player, character)
	if player:GetAttribute("AdminGodMode") then
		setGodMode(player, true)
	end
	local speed = player:GetAttribute("AdminSpeedOverride")
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid and speed then
		humanoid.WalkSpeed = speed
	end
end

local function authorize(player, suppliedCode, config)
	local record = attempts[player] or {Failures = 0, WindowStartedAt = os.clock(), LockedUntil = 0}
	attempts[player] = record
	local now = os.clock()
	if now < record.LockedUntil then
		return response(false, string.format("Locked for %d more seconds", math.ceil(record.LockedUntil - now)))
	end
	if now - record.WindowStartedAt > config.AttemptWindowSeconds then
		record.Failures = 0
		record.WindowStartedAt = now
	end
	if tostring(suppliedCode) ~= config.UnlockCode then
		record.Failures += 1
		if record.Failures >= config.MaximumFailedAttempts then
			record.LockedUntil = now + config.LockoutSeconds
			record.Failures = 0
		end
		return response(false, "Invalid lock code")
	end
	authorized[player] = true
	record.Failures = 0
	return response(true, "Admin controls unlocked for this server session")
end

function AdminService.Start(config, waveDefense, inventoryService, itemConfig)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remotes:FindFirstChild("AdminRemote")
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = "AdminRemote"
		remote.Parent = remotes
	end

	local function setupPlayer(player)
		player:SetAttribute("AdminAuthorized", false)
		player:SetAttribute("AdminGodMode", false)
		player:SetAttribute("AdminDamageMultiplier", 1)
		player:SetAttribute("AdminAllPowersUnlocked", false)
		player.CharacterAdded:Connect(function(character)
			applyCharacterOverrides(player, character)
		end)
	end
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	remote.OnServerInvoke = function(player, action, payload)
		if action == "Unlock" then
			local result = authorize(player, payload and payload.Code, config)
			player:SetAttribute("AdminAuthorized", result.Success)
			return result
		end
		if not authorized[player] then
			return response(false, "Admin controls are locked")
		end
		local now = os.clock()
		if now < (actionReadyAt[player] or 0) then
			return response(false, "Admin action rate limited")
		end
		actionReadyAt[player] = now + config.ActionCooldown
		payload = type(payload) == "table" and payload or {}

		if action == "GetPlayers" then
			local names = {}
			for _, target in ipairs(Players:GetPlayers()) do
				table.insert(names, {Name = target.Name, DisplayName = target.DisplayName, UserId = target.UserId})
			end
			return response(true, string.format("%d player(s) online", #names), names)
		end

		local target = resolveTarget(player, payload.Target)
		if action == "Kick" then
			if not target then
				return response(false, "Target player not found or ambiguous")
			end
			target:Kick("Removed by an authorized server administrator.")
			return response(true, "Kicked " .. target.Name)
		elseif action == "GodMode" then
			if not target then
				return response(false, "Target player not found or ambiguous")
			end
			local enabled = not target:GetAttribute("AdminGodMode")
			setGodMode(target, enabled)
			return response(true, string.format("God mode %s for %s", enabled and "enabled" or "disabled", target.Name), enabled)
		elseif action == "Heal" or action == "Refill" then
			if not target then
				return response(false, "Target player not found or ambiguous")
			end
			local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = humanoid.MaxHealth
			end
			if action == "Refill" then
				local maxMP = target:GetAttribute("MaxMP") or 100
				target:SetAttribute("MP", maxMP)
				target:SetAttribute("Energy", maxMP)
				target:SetAttribute("Stamina", target:GetAttribute("MaxStamina") or 100)
			end
			return response(true, string.format("%s restored", target.Name))
		elseif action == "SetSpeed" then
			if not target then
				return response(false, "Target player not found or ambiguous")
			end
			local requested = config.SpeedPresets[tostring(payload.Preset)]
			if not requested then
				return response(false, "Invalid speed preset")
			end
			local speed = math.min(requested, config.MaximumWalkSpeed)
			target:SetAttribute("AdminSpeedOverride", speed)
			local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = speed
			end
			return response(true, string.format("%s speed set to %d", target.Name, speed))
		elseif action == "DamageBoost" then
			if not target then
				return response(false, "Target player not found or ambiguous")
			end
			local multiplier = math.min(config.DamageBoostMultiplier, config.MaximumDamageMultiplier)
			local token = (damageBoostTokens[target] or 0) + 1
			damageBoostTokens[target] = token
			target:SetAttribute("AdminDamageMultiplier", multiplier)
			task.delay(config.DamageBoostSeconds, function()
				if target.Parent and damageBoostTokens[target] == token then
					target:SetAttribute("AdminDamageMultiplier", 1)
				end
			end)
			return response(true, string.format("%sx damage for %d seconds", multiplier, config.DamageBoostSeconds))
		elseif action == "UnlockPowers" then
			if not target then
				return response(false, "Target player not found or ambiguous")
			end
			target:SetAttribute("AdminAllPowersUnlocked", true)
			return response(true, "All current and future power gates unlocked for " .. target.Name)
		elseif action == "GrantItem" then
			if not target then
				return response(false, "Target player not found or ambiguous")
			end
			local itemId = tostring(payload.ItemId or "")
			if not itemConfig.Items[itemId] then
				return response(false, "Item is not in the server allowlist")
			end
			local success, message = inventoryService.Grant(target, itemId, payload.Quantity)
			return response(success, message)
		elseif action == "SetWave" then
			local wave = math.clamp(math.floor(tonumber(payload.Wave) or 1), 1, 50)
			workspace:SetAttribute("DebugNextWave", wave)
			return response(true, string.format("Next wave set to %d", wave))
		elseif action == "SpawnEnemy" then
			if now < (spawnReadyAt[player] or 0) then
				return response(false, "Spawn action cooling down")
			end
			local enemyType = tostring(payload.EnemyType)
			if not config.AllowedEnemyTypes[enemyType] then
				return response(false, "Enemy type is not allowed")
			end
			spawnReadyAt[player] = now + config.SpawnCooldown
			local success, message = waveDefense.SpawnAdminEnemy(enemyType, player)
			return response(success, message)
		end

		return response(false, "Unknown admin action")
	end

	Players.PlayerRemoving:Connect(function(player)
		authorized[player] = nil
		attempts[player] = nil
		actionReadyAt[player] = nil
		spawnReadyAt[player] = nil
		damageBoostTokens[player] = nil
	end)
end

return AdminService
