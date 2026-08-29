local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CrowdControlService = require(script.Parent.CrowdControlService)
local ElementConfig = require(ReplicatedStorage.Shared.ElementConfig)

local CombatService = {}
local activeAbilityCooldowns
local activeMasteryService
local activeQuestService

local function getDamageMultiplier(player)
	local admin = math.clamp(tonumber(player:GetAttribute("AdminDamageMultiplier")) or 1, 1, 3)
	local consumable = math.clamp(tonumber(player:GetAttribute("ConsumableDamageMultiplier")) or 1, 1, 2)
	local skill = math.clamp(tonumber(player:GetAttribute("SkillDamageMultiplier")) or 1, 1, 2)
	local form = math.clamp(tonumber(player:GetAttribute("FormDamageMultiplier")) or 1, 1, 2)
	return admin * consumable * skill * form
end

local function getElementMultiplier(player, element)
	if not element or element == "Arcane" or element == "Wind" then return 1 end
	local mastery = tonumber(player:GetAttribute(element .. "DamageMultiplier")) or 1
	local capstone = (tonumber(player:GetAttribute(element .. "UltimateUnlocked")) or 0) > 0 and 0.15 or 0
	local ascendant = (tonumber(player:GetAttribute("AscendantCoreUnlocked")) or 0) > 0 and 0.05 or 0
	local prismatic = element == "Prismatic" and ElementConfig.PrismaticDamageMultiplier or 1
	return math.clamp((mastery + capstone + ascendant) * prismatic, 1, 3)
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
	local folder = workspace:FindFirstChild("Enemies")
	if not folder then return matches end
	local parameters = OverlapParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = {folder}
	parameters.MaxParts = 400
	local seen = {}
	for _, part in ipairs(workspace:GetPartBoundsInRadius(position, radius, parameters)) do
		local enemy = part:FindFirstAncestorOfClass("Model")
		local humanoid = enemy and enemy.Parent == folder and enemy:FindFirstChildOfClass("Humanoid")
		if enemy and humanoid and humanoid.Health > 0 and not seen[enemy] then
			seen[enemy] = true
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
	CrowdControlService.Push(enemy, origin, strength, 0.18)
end

local function applyPull(enemy, origin, strength)
	CrowdControlService.Pull(enemy, origin, strength)
end

local function applyStun(enemy, duration, config, force)
	CrowdControlService.Stun(enemy, duration, config.StunImmunitySeconds, force)
end

local function damageEnemy(player, enemy, amount, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, heavy, abilityName)
	local ability = abilityName and config.Abilities[abilityName]
	local element = ability and ability.Element or player:GetAttribute("EquippedWeaponElement")
	local enemyElement = enemy:GetAttribute("Element")
	local elementDefinition = element and ElementConfig.Elements[element]
	if elementDefinition and enemyElement == elementDefinition.OpposedBy then
		amount *= 1 + (ElementConfig.OppositionDamageBonus or 0.25)
	end
	local execute = tonumber(player:GetAttribute((element or "") .. "ExecuteBonus")) or 0
	local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid")
	if enemyHumanoid and enemyHumanoid.Health / math.max(1, enemyHumanoid.MaxHealth) <= 0.25 then amount *= 1 + execute + (tonumber(player:GetAttribute("SkillExecuteBonus")) or 0) end
	amount *= 1 + (tonumber(player:GetAttribute((element or "") .. "CriticalBonus")) or 0) * 0.5
	amount *= 1 + (tonumber(player:GetAttribute((element or "") .. "Penetration")) or 0)
	local result = damageService.ApplyEnemyDamage(player, enemy, amount)
	if not result then
		return nil
	end
	local statusBonus = element and (tonumber(player:GetAttribute(element .. "StatusBonus")) or 0) or 0
	if element == "Fire" then
		enemy:SetAttribute("BurningUntil", workspace:GetServerTimeNow() + 3 * (1 + statusBonus))
	elseif element == "Ice" then
		CrowdControlService.Slow(enemy, math.max(0.3, 0.55 - statusBonus * 0.15), 2.5 * (1 + statusBonus))
	elseif element == "Lightning" and math.random() < 0.22 + statusBonus * 0.2 then
		CrowdControlService.Stun(enemy, 0.35, config.StunImmunitySeconds, false)
	elseif element == "Earth" and heavy then
		CrowdControlService.Stun(enemy, 0.45 * (1 + statusBonus), config.StunImmunitySeconds, false)
	elseif element == "Gravity" then
		enemy:SetAttribute("CompressedUntil", workspace:GetServerTimeNow() + 1.5)
	elseif element == "Poison" then
		local token = (enemy:GetAttribute("PoisonToken") or 0) + 1
		enemy:SetAttribute("PoisonToken", token)
		task.spawn(function()
			for _ = 1, 5 do
				task.wait(0.75)
				if not enemy.Parent or enemy:GetAttribute("PoisonToken") ~= token then break end
				local dot = math.max(1, amount * (0.08 + (tonumber(player:GetAttribute("PoisonDotBonus")) or 0)))
				damageService.ApplyEnemyDamage(player, enemy, dot)
			end
		end)
	elseif element == "Prismatic" then
		enemy:SetAttribute("DamageTakenMultiplier", math.max(enemy:GetAttribute("DamageTakenMultiplier") or 1, 1.12))
	end
	effectsRemote:FireClient(player, "DamageNumber", {
		Target = enemy,
		Amount = result.Amount,
		Critical = result.Critical,
		Element = element,
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
		if math.random() <= math.clamp(0.35 + (player:GetAttribute("FormPointFind") or 0), 0, 0.9) then
			player:SetAttribute("FormPoints", (player:GetAttribute("FormPoints") or 0) + (enemy:GetAttribute("IsElite") and 2 or 1))
		end
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
	activeAbilityCooldowns = abilityCooldowns
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
				local weaponAbility = player:GetAttribute("EquippedRangedAbility")
				damageEnemy(player, enemy, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, false, config.Abilities[weaponAbility] and weaponAbility or nil)
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
			local weaponAbility = player:GetAttribute("EquippedWeaponAbility")
			local result = damageEnemy(player, enemy, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, isFinisher, config.Abilities[weaponAbility] and weaponAbility or nil)
			if result then
				applyStun(enemy, comboDefinition.Stun, config, isFinisher)
				applyKnockback(enemy, root.Position, comboDefinition.Knockback)
				local form = player:GetAttribute("ActiveTransformation")
				local formSkills = player:GetAttribute("ActiveFormSkillCount") or 0
				if formSkills >= 2 and form == "Wolf" then
					effectsRemote:FireAllClients("PowerLocal", {Ability = "RendingClaw", Element = "Poison", Origin = enemy:GetPivot().Position, Radius = 6, Tier = formSkills})
					local token = (enemy:GetAttribute("BleedToken") or 0) + 1
					enemy:SetAttribute("BleedToken", token)
					task.spawn(function()
						for _ = 1, math.min(6, 2 + math.floor(formSkills / 2)) do
							task.wait(0.55)
							if not enemy.Parent or enemy:GetAttribute("BleedToken") ~= token then break end
							damageEnemy(player, enemy, damage * 0.07, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, false, nil)
						end
					end)
				elseif formSkills >= 2 and form == "Bear" and isFinisher then
					effectsRemote:FireAllClients("GroundSlam", {Ability = "TitanClaw", Element = "Earth", Origin = root.Position, Radius = 14 + formSkills})
					for _, nearby in ipairs(getEnemiesInRadius(root.Position, 14 + formSkills)) do applyStun(nearby, 0.5 + formSkills * 0.06, config, true); applyKnockback(nearby, root.Position, 55 + formSkills * 4) end
				elseif formSkills >= 2 and form == "Eagle" and isFinisher then
					effectsRemote:FireAllClients("PowerLocal", {Ability = "GaleTalon", Element = "Lightning", Origin = root.Position, Radius = 16 + formSkills, Tier = formSkills})
					for _, nearby in ipairs(getEnemiesInRadius(root.Position, 16 + formSkills)) do if nearby ~= enemy then damageEnemy(player, nearby, damage * 0.45, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, true, "LightningBolt") end end
				end
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

		local targetPosition = requestedTarget
		if mode == "Close" then
			-- LT is always the local form: it originates on the caster and cannot be redirected by the client.
			targetPosition = root.Position
		end
		if ability.Range and ability.Range > 0 and (targetPosition - root.Position).Magnitude > ability.Range then
			feedbackRemote:FireClient(player, "CastRejected", "Out of range")
			return
		end
		abilityCooldowns[player] = abilityCooldowns[player] or {}
		if (abilityCooldowns[player][abilityName] or 0) > os.clock() then
			feedbackRemote:FireClient(player, "CastRejected", "Cooling down")
			return
		end
		local masteryLevel = masteryService.GetLevel(player, abilityName)
		ability = table.clone(ability)
		local elementArea = tonumber(player:GetAttribute((ability.Element or "") .. "AreaBonus")) or 0
		local areaScale = (player:GetAttribute("SkillAreaMultiplier") or 1) * (1 + masteryLevel * 0.03) * (1 + elementArea)
		ability.Radius = (ability.Radius or 0) * areaScale
		ability.LocalRadius = (ability.LocalRadius or ability.Radius) * areaScale
		if ability.CastType == "Chain" then
			ability.MaximumChains = (ability.MaximumChains or 3)
				+ (masteryLevel >= 3 and 2 or 0) + (masteryLevel >= 5 and 3 or 0)
				+ (masteryLevel >= 8 and 4 or 0) + (masteryLevel >= 10 and 5 or 0)
		end
		if ability.CastType == "Gravity" or ability.CastType == "Tornado" then
			ability.PullStrength = (ability.PullStrength or 45) * (1 + (tonumber(player:GetAttribute((ability.Element or "") .. "StatusBonus")) or 0))
		end
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
		local cooldownReduction = (player:GetAttribute("SkillCooldownReduction") or 0) + (player:GetAttribute((ability.Element or "") .. "CooldownBonus") or 0)
		local cooldown = ability.Cooldown * (1 - math.clamp(cooldownReduction, 0, 0.55))
		local elementMultiplier = getElementMultiplier(player, ability.Element)
		player:SetAttribute("CurrentElement", ability.Element or "Arcane")
		abilityCooldowns[player][abilityName] = os.clock() + cooldown
		feedbackRemote:FireClient(player, "CastAccepted", abilityName, nil, cooldown)
		masteryService.Add(player, abilityName, config.Mastery.XPPerCast)
		effectsRemote:FireAllClients("PowerCast", {
			Ability = abilityName,
			Element = ability.Element,
			CastType = ability.CastType,
			EffectProfile = ability.EffectProfile,
			VisualVariant = ability.VisualVariant,
			SoundPitch = ability.SoundPitch,
			Tier = math.max(1, math.floor((ability.RequiredLevel or 1) / 10) + 1),
			Mode = mode,
			Origin = root.Position + Vector3.new(0, 2, 0),
			Target = targetPosition,
			Duration = mode == "Ranged" and 0.24 or 0.12,
		})

		if mode == "Close" then
			local areaOrigin = root.Position
			local localRadius = ability.LocalRadius or math.max(ability.Radius or 8, 10)
			effectsRemote:FireAllClients("PowerLocal", {
				Ability = abilityName,
				Element = ability.Element,
				Tier = math.max(1, math.floor((ability.RequiredLevel or 1) / 10) + 1),
				Origin = areaOrigin,
				Radius = localRadius,
			})
			for _, enemy in ipairs(getEnemiesInRadius(areaOrigin, localRadius)) do
				local damage = (ability.Damage + (player:GetAttribute("Power") or 0) * 0.65)
					* getDamageMultiplier(player) * elementMultiplier * masteryDamageMultiplier
				damageEnemy(player, enemy, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, false, abilityName)
				if ability.CastType == "Gravity" or ability.CastType == "Tornado" then
					applyPull(enemy, areaOrigin, ability.PullStrength or 45)
				else
					applyKnockback(enemy, areaOrigin, ability.Knockback or 22)
				end
			end
		elseif ability.CastType == "Projectile" then
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
				Ability = abilityName,
				Element = ability.Element,
				Tier = math.max(1, math.floor((ability.RequiredLevel or 1) / 10) + 1),
				VisualVariant = ability.VisualVariant,
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
						* getDamageMultiplier(player) * elementMultiplier * masteryDamageMultiplier
					damageEnemy(player, enemy, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, false, abilityName)
				end
			end)
		elseif ability.CastType == "Radial" then
			effectsRemote:FireAllClients(abilityName == "GroundSlam" and "GroundSlam" or "EnergyBurst", {
				Ability = abilityName,
				Element = ability.Element,
				Tier = math.max(1, math.floor((ability.RequiredLevel or 1) / 10) + 1),
				VisualVariant = ability.VisualVariant,
				Origin = ability.Targeting == "Self" and targetPosition or targetPosition,
				Radius = ability.Radius,
			})
			for _, enemy in ipairs(getEnemiesInRadius(targetPosition, ability.Radius)) do
				local damage = (ability.Damage + ((player:GetAttribute("AttackPower") or 0) * 0.35) + (player:GetAttribute("Power") or 0))
					* getDamageMultiplier(player) * elementMultiplier * masteryDamageMultiplier
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
			effectsRemote:FireAllClients("EnergyBeam", {Ability = abilityName, Element = ability.Element, Origin = startPosition, Target = endPosition, Radius = ability.Radius, Tier = math.max(1, math.floor((ability.RequiredLevel or 1) / 10) + 1), VisualVariant = ability.VisualVariant})
			for _, enemy in ipairs(getLivingEnemies()) do
				local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
				local distance = enemyRoot and distanceToSegment(enemyRoot.Position, startPosition, endPosition)
				if distance and distance <= ability.Radius + 1.5 then
					local damage = (ability.Damage + (player:GetAttribute("Power") or 0) + (player:GetAttribute("AttackPower") or 0) * 0.4) * getDamageMultiplier(player) * elementMultiplier * masteryDamageMultiplier
					damageEnemy(player, enemy, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, true, abilityName)
				end
			end
		elseif ability.CastType == "Gravity" then
			effectsRemote:FireAllClients("GravityPulse", {Ability = abilityName, Element = ability.Element, Origin = targetPosition, Radius = ability.Radius, Tier = math.max(1, math.floor((ability.RequiredLevel or 1) / 10) + 1), VisualVariant = ability.VisualVariant})
			for _, enemy in ipairs(getEnemiesInRadius(targetPosition, ability.Radius)) do
				local damage = (ability.Damage + (player:GetAttribute("Power") or 0) * 1.15) * getDamageMultiplier(player) * elementMultiplier * masteryDamageMultiplier
				damageEnemy(player, enemy, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, false, abilityName)
				applyPull(enemy, targetPosition, ability.PullStrength)
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
				effectsRemote:FireAllClients("ChainLightning", {Ability = abilityName, Element = ability.Element, Origin = previousPosition, Target = currentRoot.Position, Index = chainIndex, Tier = math.max(1, math.floor((ability.RequiredLevel or 1) / 10) + 1), VisualVariant = ability.VisualVariant})
				local damage = (ability.Damage * (0.88 ^ (chainIndex - 1)) + (player:GetAttribute("Power") or 0)) * getDamageMultiplier(player) * elementMultiplier * masteryDamageMultiplier
				damageEnemy(player, current, damage, config, progression, feedbackRemote, damageService, effectsRemote, inventoryService, false, abilityName)
				previousPosition = currentRoot.Position
				local nearest, nearestDistance
				for _, candidate in ipairs(getEnemiesInRadius(previousPosition, ability.ChainRange)) do
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
				Ability = abilityName,
				Element = ability.Element,
				Tier = math.max(1, math.floor((ability.RequiredLevel or 1) / 10) + 1),
				VisualVariant = ability.VisualVariant,
				Origin = startPosition,
				Target = targetPosition,
				Duration = travelTime,
				ImpactTime = workspace:GetServerTimeNow() + travelTime,
			})
			task.delay(travelTime, function()
				if not player.Parent then return end
				effectsRemote:FireAllClients("TornadoStart", {
					Ability = abilityName,
					Element = ability.Element,
					Tier = math.max(1, math.floor((ability.RequiredLevel or 1) / 10) + 1),
					VisualVariant = ability.VisualVariant,
					Origin = targetPosition,
					Radius = ability.Radius,
					Duration = ability.Duration,
				})
				local endAt = os.clock() + ability.Duration
				while player.Parent and os.clock() < endAt do
					for _, enemy in ipairs(getEnemiesInRadius(targetPosition, ability.Radius)) do
						local damage = (ability.Damage + (player:GetAttribute("Power") or 0)) * getDamageMultiplier(player) * elementMultiplier * masteryDamageMultiplier
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

function CombatService.ResetCooldowns(player)
	if activeAbilityCooldowns then activeAbilityCooldowns[player] = {} end
	return true, "Combat power cooldowns reset"
end

return CombatService
