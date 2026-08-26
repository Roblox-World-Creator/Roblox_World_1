local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatService = {}
local activeMasteryService
local activeQuestService

local function getDamageMultiplier(player)
	local admin = math.clamp(tonumber(player:GetAttribute("AdminDamageMultiplier")) or 1, 1, 3)
	local consumable = math.clamp(tonumber(player:GetAttribute("ConsumableDamageMultiplier")) or 1, 1, 2)
	return admin * consumable
end

local function getOrCreateRemote(folder, name)
	local remote = folder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	return remote
end

local function isFiniteVector3(value)
	return typeof(value) == "Vector3"
		and value.X == value.X
		and value.Y == value.Y
		and value.Z == value.Z
		and math.abs(value.X) < 100000
		and math.abs(value.Y) < 100000
		and math.abs(value.Z) < 100000
end

local function getLivingEnemies()
	local folder = workspace:FindFirstChild("Enemies")
	local enemies = {}
	if not folder then
		return enemies
	end
	for _, enemy in ipairs(folder:GetChildren()) do
		local humanoid = enemy:FindFirstChildOfClass("Humanoid")
		local root = enemy:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 then
			table.insert(enemies, enemy)
		end
	end
	return enemies
end

local function getEnemiesInRadius(position, radius)
	local matches = {}
	for _, enemy in ipairs(getLivingEnemies()) do
		local root = enemy:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - position).Magnitude <= radius then
			table.insert(matches, enemy)
		end
	end
	return matches
end

local function getEnemiesInMeleeCone(root, range)
	local matches = {}
	for _, enemy in ipairs(getLivingEnemies()) do
		local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
		if enemyRoot then
			local offset = enemyRoot.Position - root.Position
			local distance = offset.Magnitude
			if distance > 0 and distance <= range and root.CFrame.LookVector:Dot(offset.Unit) >= 0.15 then
				table.insert(matches, enemy)
			end
		end
	end
	return matches
end

local function distanceToSegment(point, segmentStart, segmentEnd)
	local segment = segmentEnd - segmentStart
	local lengthSquared = segment:Dot(segment)
	if lengthSquared <= 0 then
		return (point - segmentStart).Magnitude, 0
	end
	local alpha = math.clamp((point - segmentStart):Dot(segment) / lengthSquared, 0, 1)
	local closest = segmentStart + segment * alpha
	return (point - closest).Magnitude, alpha
end

local function findProjectileIntercept(startPosition, targetPosition, radius)
	local bestEnemy
	local bestAlpha = math.huge
	for _, enemy in ipairs(getLivingEnemies()) do
		local root = enemy:FindFirstChild("HumanoidRootPart")
		if root then
			local distance, alpha = distanceToSegment(root.Position, startPosition, targetPosition)
			if distance <= radius + 1.5 and alpha < bestAlpha then
				bestEnemy = enemy
				bestAlpha = alpha
			end
		end
	end
	if bestEnemy then
		local root = bestEnemy:FindFirstChild("HumanoidRootPart")
		return root and root.Position or targetPosition
	end
	return targetPosition
end

local function applyKnockback(enemy, origin, strength)
	local root = enemy:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local offset = root.Position - origin
	local direction = offset.Magnitude > 0 and offset.Unit or Vector3.yAxis
	local resistance = math.clamp(enemy:GetAttribute("KnockbackResistance") or 0, 0, 0.95)
	root:ApplyImpulse((direction + Vector3.new(0, 0.18, 0)).Unit * strength * (1 - resistance) * root.AssemblyMass)
end

local function applyPull(enemy, origin, strength)
	local root = enemy:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local offset = origin - root.Position
	if offset.Magnitude <= 0 then return end
	local resistance = math.clamp(enemy:GetAttribute("KnockbackResistance") or 0, 0, 0.95)
	root:ApplyImpulse((offset.Unit + Vector3.new(0, 0.12, 0)).Unit * strength * (1 - resistance) * root.AssemblyMass)
end

local function applyStun(enemy, duration, config, force)
	local now = workspace:GetServerTimeNow()
	if not force and now < (enemy:GetAttribute("NextStunnableAt") or 0) then
		return
	end
	local resistance = math.clamp(enemy:GetAttribute("StunResistance") or 0, 0, 0.95)
	local actualDuration = duration * (1 - resistance)
	if actualDuration <= 0.03 then
		return
	end
	enemy:SetAttribute("StunnedUntil", now + actualDuration)
	enemy:SetAttribute("NextStunnableAt", now + actualDuration + config.StunImmunitySeconds)
end

local function damageEnemy(player, enemy, amount, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, heavy, abilityName)
	local result = damageService.ApplyEnemyDamage(player, enemy, amount)
	if not result then
		return nil
	end
	effectsRemote:FireClient(player, "DamageNumber", {
		Target = enemy,
		Amount = result.Amount,
		Critical = result.Critical,
	})
	effectsRemote:FireAllClients("EnemyDamaged", {
		Target = enemy,
		Heavy = heavy == true,
	})
	if abilityName and activeMasteryService then activeMasteryService.Add(player, abilityName, result.Amount * config.Mastery.XPPerDamage) end
	if result.Killed and not enemy:GetAttribute("BossWave") and not enemy:GetAttribute("RewardGranted") then
		enemy:SetAttribute("RewardGranted", true)
		local xp = enemy:GetAttribute("RewardXP") or 0
		local gold = enemy:GetAttribute("RewardCoins") or 0
		progression.AddXP(player, xp, config)
		progression.AddCoins(player, gold)
		feedbackRemote:FireClient(player, "Reward", xp, gold)
		inventoryService.RollLoot(player, enemy)
		if activeQuestService then
			activeQuestService.Record(player, "Kill", 1)
			if enemy:GetAttribute("IsElite") then activeQuestService.Record(player, "EliteKill", 1) end
		end
	end
	return result
end

function CombatService.Start(config, progression, damageService, inventoryService, masteryService, questService, powerService)
	activeMasteryService, activeQuestService = masteryService, questService
	workspace:SetAttribute("CombatStatus", "Starting")
	local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
	local combatRemote = getOrCreateRemote(remotes, "CombatRemote")
	local abilityRemote = getOrCreateRemote(remotes, "AbilityRemote")
	local effectsRemote = getOrCreateRemote(remotes, "AbilityEffects")
	local feedbackRemote = getOrCreateRemote(remotes, "CombatFeedback")
	local abilityCooldowns = {}
	local meleeStates = {}

	local function validCharacter(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return character and humanoid and root and humanoid.Health > 0, root
	end

	combatRemote.OnServerEvent:Connect(function(player, action, value)
		if action == "Ranged" then
			local valid, root = validCharacter(player)
			local kind = player:GetAttribute("EquippedWeaponKind")
			if not valid or (kind ~= "Bow" and kind ~= "Gun" and kind ~= "Rifle") or not isFiniteVector3(value) then return end
			local target = value
			if (target - root.Position).Magnitude > 120 then target = root.Position + (target - root.Position).Unit * 120 end
			local startPosition = root.Position + Vector3.new(0, 2, 0)
			local impact = findProjectileIntercept(startPosition, target, 3)
			local multiplier = kind == "Rifle" and 1.35 or kind == "Bow" and 1.1 or 0.9
			local damage = (player:GetAttribute("AttackPower") or config.MeleeDamage) * multiplier * getDamageMultiplier(player)
			effectsRemote:FireAllClients("EnergyBolt", {Origin = startPosition, Target = impact, Duration = 0.2, ImpactTime = workspace:GetServerTimeNow() + 0.2, Radius = 3})
			for _, enemy in ipairs(getEnemiesInRadius(impact, 3)) do
				damageEnemy(player, enemy, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, false, "RangedWeapon")
			end
			return
		end
		if action == "Block" then
			local valid = validCharacter(player)
			local blocking = valid and value == true
			player:SetAttribute("Blocking", blocking)
			if blocking then
				local now = workspace:GetServerTimeNow()
				if now - (player:GetAttribute("LastBlockStartAt") or 0) >= config.PerfectBlockRearm then
					player:SetAttribute("BlockStartedAt", now)
					player:SetAttribute("LastBlockStartAt", now)
				end
			end
			return
		elseif action ~= "Melee" then
			return
		end
		local valid, root = validCharacter(player)
		if not valid then
			return
		end
		local now = os.clock()
		local state = meleeStates[player] or {Index = 0, LastAttack = 0, ReadyAt = 0}
		if now < state.ReadyAt then
			return
		end
		if now - state.LastAttack > config.MeleeComboReset then
			state.Index = 1
		else
			state.Index = (state.Index % #config.MeleeCombo) + 1
		end
		local comboDefinition = config.MeleeCombo[state.Index]
		state.LastAttack = now
		state.ReadyAt = now + comboDefinition.Cooldown
		meleeStates[player] = state
		player:SetAttribute("Blocking", false)
		feedbackRemote:FireClient(player, "CastAccepted", "Melee", state.Index)
		effectsRemote:FireAllClients("Melee", {
			Origin = root.Position,
			Direction = root.CFrame.LookVector,
			Character = player.Character,
			Combo = state.Index,
		})
		for _, enemy in ipairs(getEnemiesInMeleeCone(root, config.MeleeRange)) do
			local damage = (player:GetAttribute("AttackPower") or config.MeleeDamage)
				* comboDefinition.DamageMultiplier
				* getDamageMultiplier(player)
			local isFinisher = state.Index == #config.MeleeCombo
			local result = damageEnemy(player, enemy, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, isFinisher)
			if result then
				applyStun(enemy, comboDefinition.Stun, config, isFinisher)
				applyKnockback(enemy, root.Position, comboDefinition.Knockback)
				if isFinisher then
					effectsRemote:FireAllClients("FinisherImpact", {Origin = enemy:GetPivot().Position})
				end
			end
		end
	end)

	abilityRemote.OnServerEvent:Connect(function(player, abilityName, requestedTarget, requestedMode)
		local ability = config.Abilities[abilityName]
		local mode = requestedMode == "Close" and "Close" or "Ranged"
		if not ability or not isFiniteVector3(requestedTarget) then
			feedbackRemote:FireClient(player, "CastRejected", "Invalid ability request")
			return
		end
		if ((player:GetAttribute("Evolution") or 0) < (ability.RequiredEvolution or 0)
			or (player:GetAttribute("Level") or 1) < (ability.RequiredLevel or 1))
			and not player:GetAttribute("AdminAllPowersUnlocked") then
			feedbackRemote:FireClient(player, "CastRejected", "Power is locked")
			return
		end
		if powerService and not powerService.IsActive(player, abilityName) then
			feedbackRemote:FireClient(player, "CastRejected", "Power is not active")
			return
		end
		local valid, root = validCharacter(player)
		if not valid then
			return
		end

		local targetPosition = ability.Targeting == "Self" and root.Position or requestedTarget
		if mode == "Close" then
			targetPosition = root.Position + root.CFrame.LookVector * math.min(ability.CloseRange or 12, ability.Range or 12)
		end
		if ability.Targeting ~= "Self" and (targetPosition - root.Position).Magnitude > ability.Range then
			feedbackRemote:FireClient(player, "CastRejected", "Out of range")
			return
		end
		abilityCooldowns[player] = abilityCooldowns[player] or {}
		if (abilityCooldowns[player][abilityName] or 0) > os.clock() then
			feedbackRemote:FireClient(player, "CastRejected", "Cooling down")
			return
		end
		local masteryLevel = masteryService.GetLevel(player, abilityName)
		local energyCost = math.max(1, math.floor(ability.EnergyCost * (1 - masteryLevel * config.Mastery.CostReductionPerLevel)))
		local masteryDamageMultiplier = 1 + masteryLevel * config.Mastery.DamagePerLevel
		local mp = player:GetAttribute("MP") or 0
		if mp < energyCost then
			feedbackRemote:FireClient(player, "CastRejected", "Need more MP")
			return
		end

		player:SetAttribute("MP", mp - energyCost)
		player:SetAttribute("Energy", mp - energyCost)
		player:SetAttribute("Blocking", false)
		abilityCooldowns[player][abilityName] = os.clock() + ability.Cooldown
		feedbackRemote:FireClient(player, "CastAccepted", abilityName)
		masteryService.Add(player, abilityName, config.Mastery.XPPerCast)

		if ability.CastType == "Projectile" then
			local startPosition = root.Position + Vector3.new(0, 2, 0)
			local raycastParameters = RaycastParams.new()
			raycastParameters.FilterType = Enum.RaycastFilterType.Exclude
			raycastParameters.FilterDescendantsInstances = {player.Character}
			raycastParameters.RespectCanCollide = true
			local obstruction = workspace:Raycast(startPosition, targetPosition - startPosition, raycastParameters)
			if obstruction then
				targetPosition = obstruction.Position
			end
			local impactPosition = findProjectileIntercept(startPosition, targetPosition, ability.Radius)
			local travelTime = math.clamp((impactPosition - startPosition).Magnitude / ability.ProjectileSpeed, 0.08, 1.5)
			effectsRemote:FireAllClients("EnergyBolt", {
				Origin = startPosition,
				Target = impactPosition,
				Duration = travelTime,
				ImpactTime = workspace:GetServerTimeNow() + travelTime,
				Radius = ability.Radius,
			})
			task.delay(travelTime, function()
				if not player.Parent then
					return
				end
				for _, enemy in ipairs(getEnemiesInRadius(impactPosition, ability.Radius)) do
					local damage = (ability.Damage + ((player:GetAttribute("AttackPower") or 0) * 0.5) + (player:GetAttribute("Power") or 0))
						* getDamageMultiplier(player) * masteryDamageMultiplier
					damageEnemy(player, enemy, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, false, abilityName)
				end
			end)
		elseif ability.CastType == "Radial" then
			effectsRemote:FireAllClients("EnergyBurst", {
				Origin = root.Position,
				Radius = ability.Radius,
			})
			for _, enemy in ipairs(getEnemiesInRadius(root.Position, ability.Radius)) do
				local damage = (ability.Damage + ((player:GetAttribute("AttackPower") or 0) * 0.35) + (player:GetAttribute("Power") or 0))
					* getDamageMultiplier(player) * masteryDamageMultiplier
				damageEnemy(player, enemy, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, false, abilityName)
				applyKnockback(enemy, root.Position, ability.Knockback)
			end
		elseif ability.CastType == "Beam" then
			local startPosition = root.Position + Vector3.new(0, 2, 0)
			local direction = targetPosition - startPosition
			if direction.Magnitude < 1 then direction = root.CFrame.LookVector * ability.Range end
			local endPosition = startPosition + direction.Unit * math.min(direction.Magnitude, ability.Range)
			local beamParameters = RaycastParams.new()
			beamParameters.FilterType = Enum.RaycastFilterType.Exclude
			beamParameters.FilterDescendantsInstances = {player.Character, workspace:FindFirstChild("Enemies")}
			beamParameters.RespectCanCollide = true
			local beamObstruction = workspace:Raycast(startPosition, endPosition - startPosition, beamParameters)
			if beamObstruction then endPosition = beamObstruction.Position end
			effectsRemote:FireAllClients("EnergyBeam", {Origin = startPosition, Target = endPosition, Radius = ability.Radius})
			for _, enemy in ipairs(getLivingEnemies()) do
				local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
				local distance = enemyRoot and distanceToSegment(enemyRoot.Position, startPosition, endPosition)
				if distance and distance <= ability.Radius + 1.5 then
					local damage = (ability.Damage + (player:GetAttribute("Power") or 0) + (player:GetAttribute("AttackPower") or 0) * 0.4) * getDamageMultiplier(player) * masteryDamageMultiplier
					damageEnemy(player, enemy, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, true, abilityName)
				end
			end
		elseif ability.CastType == "Gravity" then
			effectsRemote:FireAllClients("GravityPulse", {Origin = root.Position, Radius = ability.Radius})
			for _, enemy in ipairs(getEnemiesInRadius(root.Position, ability.Radius)) do
				local damage = (ability.Damage + (player:GetAttribute("Power") or 0) * 1.15) * getDamageMultiplier(player) * masteryDamageMultiplier
				damageEnemy(player, enemy, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, false, abilityName)
				applyPull(enemy, root.Position, ability.PullStrength)
			end
		elseif ability.CastType == "Chain" then
			local candidates = getEnemiesInRadius(targetPosition, math.max(ability.Radius, 8))
			local current = candidates[1]
			local previousPosition = root.Position + Vector3.new(0, 2, 0)
			local struck = {}
			for chainIndex = 1, ability.MaximumChains do
				if not current then break end
				struck[current] = true
				local currentRoot = current:FindFirstChild("HumanoidRootPart")
				if not currentRoot then break end
				effectsRemote:FireAllClients("ChainLightning", {Origin = previousPosition, Target = currentRoot.Position, Index = chainIndex})
				local damage = (ability.Damage * (0.88 ^ (chainIndex - 1)) + (player:GetAttribute("Power") or 0)) * getDamageMultiplier(player) * masteryDamageMultiplier
				damageEnemy(player, current, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, false, abilityName)
				previousPosition = currentRoot.Position
				local nearest, nearestDistance
				for _, candidate in ipairs(getLivingEnemies()) do
					local candidateRoot = candidate:FindFirstChild("HumanoidRootPart")
					local distance = candidateRoot and (candidateRoot.Position - previousPosition).Magnitude
					if not struck[candidate] and distance and distance <= ability.ChainRange and (not nearestDistance or distance < nearestDistance) then nearest, nearestDistance = candidate, distance end
				end
				current = nearest
			end
		elseif ability.CastType == "Tornado" then
			local startPosition = root.Position + Vector3.new(0, 2, 0)
			local distance = (targetPosition - startPosition).Magnitude
			local travelTime = math.clamp(distance / (ability.ProjectileSpeed or 42), 0.15, 1.5)
			effectsRemote:FireAllClients("TornadoTravel", {
				Origin = startPosition,
				Target = targetPosition,
				Duration = travelTime,
				ImpactTime = workspace:GetServerTimeNow() + travelTime,
			})
			task.delay(travelTime, function()
				if not player.Parent then return end
				effectsRemote:FireAllClients("TornadoStart", {
					Origin = targetPosition,
					Radius = ability.Radius,
					Duration = ability.Duration,
				})
				local endAt = os.clock() + ability.Duration
				while player.Parent and os.clock() < endAt do
					for _, enemy in ipairs(getEnemiesInRadius(targetPosition, ability.Radius)) do
						local damage = (ability.Damage + (player:GetAttribute("Power") or 0)) * getDamageMultiplier(player) * masteryDamageMultiplier
						damageEnemy(player, enemy, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, true, abilityName)
						applyPull(enemy, targetPosition, ability.PullStrength)
						local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
						if enemyRoot then enemyRoot:ApplyImpulse(Vector3.new(0, ability.PullStrength * 0.35, 0) * enemyRoot.AssemblyMass) end
					end
					task.wait(ability.TickInterval)
				end
				if player.Parent then
					effectsRemote:FireAllClients("TornadoEnd", {Origin = targetPosition, Radius = ability.Radius})
				end
			end)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		abilityCooldowns[player] = nil
		meleeStates[player] = nil
	end)
	workspace:SetAttribute("CombatStatus", "Ready")
end

return CombatService
