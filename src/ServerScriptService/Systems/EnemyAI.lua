local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
	local defense = math.max(0, player:GetAttribute("Defense") or 0)
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
	effectsRemote:FireAllClients("EnemyHit", {
		Origin = targetRoot.Position,
		Direction = toEnemy.Magnitude > 0 and -toEnemy.Unit or enemyRoot.CFrame.LookVector,
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

			if targetRoot and distanceToGoal <= config.EnemyAttackRange then
				humanoid:MoveTo(root.Position)
				if os.clock() >= nextAttack then
					nextAttack = os.clock() + config.EnemyAttackCooldown * (enemy:GetAttribute("AttackCooldownMultiplier") or 1)
					enemy:SetAttribute("AIState", "Attacking")
					effectsRemote:FireAllClients("EnemyTelegraph", {
						Origin = root.Position,
						Duration = config.EnemyAttackWindup,
						Radius = config.EnemyAttackRange,
					})
					task.wait(config.EnemyAttackWindup)
					local _, currentHumanoid, currentRoot = getLivingCharacter(targetPlayer)
					if enemy.Parent and humanoid.Health > 0
						and workspace:GetServerTimeNow() >= (enemy:GetAttribute("StunnedUntil") or 0)
						and currentHumanoid and currentRoot
						and (currentRoot.Position - root.Position).Magnitude <= config.EnemyAttackRange + 2 then
						damagePlayer(enemy, root, targetPlayer, currentHumanoid, currentRoot, config, effectsRemote)
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
