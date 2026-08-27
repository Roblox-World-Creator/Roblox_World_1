local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PathfindingBudget = require(script.Parent.PathfindingBudget)

local EnemyAI = {}

local function getLivingCharacter(player)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return character, humanoid, root
	end
	return nil, nil, nil
end

local function choosePlayerTarget(enemyRoot, config)
	local aggroUserId = enemyRoot.Parent:GetAttribute("AggroUserId")
	if aggroUserId then
		local player = Players:GetPlayerByUserId(aggroUserId)
		local _, humanoid, root = getLivingCharacter(player)
		if humanoid and root and (root.Position - enemyRoot.Position).Magnitude <= config.EnemyLeashDistance then
			return player, humanoid, root
		end
		enemyRoot.Parent:SetAttribute("AggroUserId", nil)
	end

	local nearestPlayer
	local nearestHumanoid
	local nearestRoot
	local nearestDistance = config.EnemyAggroRange
	for _, player in ipairs(Players:GetPlayers()) do
		local _, humanoid, root = getLivingCharacter(player)
		if root then
			local distance = (root.Position - enemyRoot.Position).Magnitude
			if distance <= nearestDistance then
				nearestDistance = distance
				nearestPlayer = player
				nearestHumanoid = humanoid
				nearestRoot = root
			end
		end
	end
	return nearestPlayer, nearestHumanoid, nearestRoot
end

local function computePath(enemyRoot, goalPosition)
	return PathfindingBudget.Compute(enemyRoot.Position, goalPosition)
end

local function damagePlayer(enemy, enemyRoot, player, targetHumanoid, targetRoot, config, effectsRemote)
	local now = workspace:GetServerTimeNow()
	if player:GetAttribute("AdminGodMode") then
		return
	end
	if now < (player:GetAttribute("InvulnerableUntil") or 0) then
		effectsRemote:FireAllClients("DodgeAvoid", {Origin = targetRoot.Position})
		return
	end

	local damage = enemy:GetAttribute("AttackDamage") or 5
	local defense = math.max(0, (player:GetAttribute("Defense") or 0) + (player:GetAttribute("TransformationDefense") or 0))
	damage *= 100 / (100 + defense)
	local toEnemy = enemyRoot.Position - targetRoot.Position
	local facingEnemy = toEnemy.Magnitude > 0 and targetRoot.CFrame.LookVector:Dot(toEnemy.Unit) > 0.15
	if player:GetAttribute("Blocking") and facingEnemy then
		local blockAge = now - (player:GetAttribute("BlockStartedAt") or 0)
		if blockAge <= config.PerfectBlockWindow then
			local resistance = math.clamp(enemy:GetAttribute("StunResistance") or 0, 0, 0.95)
			enemy:SetAttribute("StunnedUntil", now + config.PerfectBlockStun * (1 - resistance))
			effectsRemote:FireAllClients("PerfectBlock", {Origin = targetRoot.Position})
			return
		end
		local stamina = player:GetAttribute("Stamina") or 0
		if stamina >= config.BlockStaminaCost then
			player:SetAttribute("Stamina", stamina - config.BlockStaminaCost)
			player:SetAttribute("LastStaminaUse", now)
			damage *= config.BlockDamageMultiplier
			effectsRemote:FireAllClients("BlockImpact", {Origin = targetRoot.Position})
		else
			player:SetAttribute("Blocking", false)
		end
	end

	targetHumanoid:TakeDamage(damage)
	local statusEffect = enemy:GetAttribute("StatusEffect")
	if statusEffect == "Burn" then
		task.delay(0.55, function()
			if targetHumanoid.Parent and targetHumanoid.Health > 0 then targetHumanoid:TakeDamage(math.max(1, damage * 0.25)) end
		end)
	elseif statusEffect == "Shock" then
		player:SetAttribute("Stamina", math.max(0, (player:GetAttribute("Stamina") or 0) - 14))
	elseif statusEffect == "Void" then
		local remaining = math.max(0, (player:GetAttribute("MP") or 0) - 12)
		player:SetAttribute("MP", remaining)
		player:SetAttribute("Energy", remaining)
	elseif statusEffect == "Crush" then
		local push = targetRoot.Position - enemyRoot.Position
		targetRoot.AssemblyLinearVelocity += (push.Magnitude > 0.1 and push.Unit or enemyRoot.CFrame.LookVector) * 24 + Vector3.new(0, 10, 0)
	elseif statusEffect == "Slow" then
		local token = (player:GetAttribute("EnemySlowToken") or 0) + 1
		player:SetAttribute("EnemySlowToken", token)
		targetHumanoid.WalkSpeed *= 0.7
		task.delay(1.5, function()
			if player.Parent and player:GetAttribute("EnemySlowToken") == token and targetHumanoid.Parent then
				local base = player:GetAttribute("AdminSpeedOverride") or (36 * (player:GetAttribute("SpeedMultiplier") or 1) + (player:GetAttribute("EquipmentSpeed") or 0))
				targetHumanoid.WalkSpeed = base * (player:GetAttribute("TransformationMoveMultiplier") or 1)
			end
		end)
	end
	effectsRemote:FireAllClients("EnemyHit", {
		Origin = targetRoot.Position,
		Direction = toEnemy.Magnitude > 0 and -toEnemy.Unit or enemyRoot.CFrame.LookVector,
		Color = enemy:GetAttribute("AbilityColor"),
		Ability = enemy:GetAttribute("AbilityName"),
		Status = statusEffect,
	})
end

function EnemyAI.Run(enemy, core, config, holdPosition)
	PathfindingBudget.Configure(config)
	task.spawn(function()
		local humanoid = enemy:FindFirstChildOfClass("Humanoid")
		local root = enemy:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then
			return
		end
		local effectsRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AbilityEffects")
		local nextAttack = 0
		local nextPathUpdate = 0
		local lastGoal
		local waypoints = {}
		local waypointIndex = 1
		local homePosition = root.Position
		local lastProgressPosition = root.Position
		local lastProgressAt = os.clock()

		while enemy.Parent and humanoid.Health > 0 and (holdPosition or (core:GetAttribute("Health") or 0) > 0) do
			local now = workspace:GetServerTimeNow()
			local slowed = now < (enemy:GetAttribute("SlowedUntil") or 0)
			humanoid.WalkSpeed = (enemy:GetAttribute("BaseWalkSpeed") or humanoid.WalkSpeed) * (slowed and (enemy:GetAttribute("SlowMultiplier") or 0.65) or 1)
			local previousState = enemy:GetAttribute("AIState")
			if previousState == "Chasing" or previousState == "Advancing" or previousState == "Recovering" then
				if (root.Position - lastProgressPosition).Magnitude >= config.EnemyStuckDistance then
					lastProgressPosition = root.Position
					lastProgressAt = os.clock()
				elseif os.clock() - lastProgressAt >= config.EnemyStuckSeconds then
					enemy:SetAttribute("AIState", "Recovering")
					humanoid.Jump = true
					waypoints = {}
					lastGoal = nil
					nextPathUpdate = 0
					lastProgressPosition = root.Position
					lastProgressAt = os.clock()
				end
			else
				lastProgressPosition = root.Position
				lastProgressAt = os.clock()
			end
			if workspace:GetServerTimeNow() < (enemy:GetAttribute("StunnedUntil") or 0) then
				enemy:SetAttribute("AIState", "Stunned")
				humanoid:MoveTo(root.Position)
				task.wait(0.1)
				continue
			end
			local targetPlayer, targetHumanoid, targetRoot = choosePlayerTarget(root, config)
			local goalPosition = targetRoot and targetRoot.Position or (holdPosition and homePosition or core.Position)
			local distanceToGoal = (goalPosition - root.Position).Magnitude
			local attackStyle = enemy:GetAttribute("AttackStyle") or "Melee"
			local attackRange = enemy:GetAttribute("AttackRange") or config.EnemyAttackRange
			local abilityRadius = enemy:GetAttribute("AbilityRadius") or attackRange

			if targetRoot and distanceToGoal <= attackRange then
				humanoid:MoveTo(root.Position)
				if os.clock() >= nextAttack then
					nextAttack = os.clock() + config.EnemyAttackCooldown * (enemy:GetAttribute("AttackCooldownMultiplier") or 1)
					enemy:SetAttribute("AIState", "Attacking")
					local flightMotor = enemy:GetAttribute("FlyingEnemy") and enemy:FindFirstChild("EnemyFlightMotor", true)
					local groundC0 = flightMotor and flightMotor:GetAttribute("GroundC0")
					if flightMotor and typeof(groundC0) == "CFrame" then
						TweenService:Create(flightMotor, TweenInfo.new(config.EnemyAttackWindup * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = groundC0}):Play()
					end
					effectsRemote:FireAllClients("EnemyTelegraph", {
						Origin = root.Position,
						Duration = config.EnemyAttackWindup,
						Radius = attackStyle == "Area" and abilityRadius or math.min(attackRange, 8),
						Target = targetRoot.Position,
						Color = enemy:GetAttribute("AbilityColor"),
						Ability = enemy:GetAttribute("AbilityName"),
						Style = attackStyle,
					})
					if attackStyle == "Lunge" and distanceToGoal > 0 then
						root.AssemblyLinearVelocity = (targetRoot.Position - root.Position).Unit * 34 + Vector3.new(0, 5, 0)
					end
					task.wait(config.EnemyAttackWindup)
					if enemy.Parent and humanoid.Health > 0 and workspace:GetServerTimeNow() >= (enemy:GetAttribute("StunnedUntil") or 0) then
						if attackStyle == "Area" then
							for _, nearbyPlayer in ipairs(Players:GetPlayers()) do
								local _, nearbyHumanoid, nearbyRoot = getLivingCharacter(nearbyPlayer)
								if nearbyRoot and (nearbyRoot.Position - root.Position).Magnitude <= abilityRadius then
									damagePlayer(enemy, root, nearbyPlayer, nearbyHumanoid, nearbyRoot, config, effectsRemote)
								end
							end
						else
							local _, currentHumanoid, currentRoot = getLivingCharacter(targetPlayer)
							if currentHumanoid and currentRoot and (currentRoot.Position - root.Position).Magnitude <= attackRange + 2 then
								damagePlayer(enemy, root, targetPlayer, currentHumanoid, currentRoot, config, effectsRemote)
							end
						end
					end
					local airC0 = flightMotor and flightMotor:GetAttribute("AirC0")
					if flightMotor and typeof(airC0) == "CFrame" then
						TweenService:Create(flightMotor, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = airC0}):Play()
					end
				end
			elseif not targetRoot and not holdPosition and distanceToGoal <= config.CoreAttackRange then
				enemy:SetAttribute("AIState", "AttackingCore")
				core:SetAttribute("Health", math.max(0, (core:GetAttribute("Health") or 0) - (enemy:GetAttribute("AttackDamage") or 5)))
				enemy:Destroy()
				break
			elseif holdPosition and not targetRoot and distanceToGoal <= 3 then
				enemy:SetAttribute("AIState", "Idle")
				humanoid:MoveTo(root.Position)
			else
				enemy:SetAttribute("AIState", targetRoot and "Chasing" or "Advancing")
				local goalMoved = not lastGoal or (goalPosition - lastGoal).Magnitude >= 8
				if os.clock() >= nextPathUpdate or goalMoved then
					waypoints = computePath(root, goalPosition)
					waypointIndex = math.min(2, #waypoints)
					lastGoal = goalPosition
					nextPathUpdate = os.clock() + config.EnemyRepathSeconds
				end

				local waypoint = waypoints[waypointIndex]
				if waypoint then
					if (waypoint.Position - root.Position).Magnitude <= 4 then
						waypointIndex += 1
						waypoint = waypoints[waypointIndex]
					end
					if waypoint then
						if waypoint.Action == Enum.PathWaypointAction.Jump then
							humanoid.Jump = true
						end
						humanoid:MoveTo(waypoint.Position)
					else
						humanoid:MoveTo(goalPosition)
					end
				else
					humanoid:MoveTo(goalPosition)
				end
			end
			task.wait(0.15)
		end
	end)
end

return EnemyAI
