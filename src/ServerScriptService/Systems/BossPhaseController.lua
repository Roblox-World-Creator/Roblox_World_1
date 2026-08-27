local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BossPhaseController = {}
local EnemyAI = require(script.Parent.EnemyAI)

local function damagePlayer(player, humanoid, damage)
	if player:GetAttribute("AdminGodMode") or workspace:GetServerTimeNow() < (player:GetAttribute("InvulnerableUntil") or 0) then return end
	local defense = math.max(0, (player:GetAttribute("Defense") or 0) + (player:GetAttribute("TransformationDefense") or 0))
	humanoid:TakeDamage(damage * 100 / (100 + defense))
end

local function getPhaseDefinition(config, phaseNumber)
	for _, definition in ipairs(config.BossPhases) do
		if definition.Phase == phaseNumber then
			return definition
		end
	end
	return nil
end

local function applyPhase(boss, humanoid, definition, effectsRemote)
	boss:SetAttribute("BossPhase", definition.Phase)
	boss:SetAttribute("AttackCooldownMultiplier", definition.AttackCooldownMultiplier)
	boss:SetAttribute("AttackDamage", (boss:GetAttribute("BaseAttackDamage") or 1) * definition.DamageMultiplier)
	humanoid.WalkSpeed = (boss:GetAttribute("BaseWalkSpeed") or humanoid.WalkSpeed) * definition.SpeedMultiplier

	local aura = boss:FindFirstChild("BossPhaseAura") or Instance.new("Highlight")
	aura.Name = "BossPhaseAura"
	aura.FillColor = definition.Phase >= 3 and Color3.fromRGB(255, 55, 90) or Color3.fromRGB(255, 150, 55)
	aura.OutlineColor = Color3.fromRGB(255, 235, 160)
	aura.FillTransparency = 0.55
	aura.OutlineTransparency = 0.1
	aura.Parent = boss
	effectsRemote:FireAllClients("BossPhase", {
		Boss = boss,
		Phase = definition.Phase,
	})
end

local function summonMinions(boss, gameConfig)
	local folder = workspace:FindFirstChild("Enemies")
	local core = workspace:FindFirstChild("DefenseCore")
	local root = boss:FindFirstChild("HumanoidRootPart")
	if not folder or not core or not root or not gameConfig then return end
	for index = 1, 2 do
		local minion = Instance.new("Model")
		minion.Name = "Rift Minion"
		minion:SetAttribute("EnemyType", "Fast")
		minion:SetAttribute("AttackDamage", 10)
		local body = Instance.new("Part")
		body.Name = "HumanoidRootPart"
		body.Size = Vector3.new(2, 2, 2)
		body.Position = root.Position + Vector3.new(index * 3 - 4, 1, 0)
		body.Color = Color3.fromRGB(170, 75, 255)
		body.Parent = minion
		local humanoid = Instance.new("Humanoid")
		humanoid.MaxHealth, humanoid.Health, humanoid.WalkSpeed = 80, 80, 15
		humanoid.Parent = minion
		minion.PrimaryPart = body
		minion.Parent = folder
		EnemyAI.Run(minion, core, gameConfig, false)
		humanoid.Died:Connect(function() task.delay(0.2, function() if minion.Parent then minion:Destroy() end end) end)
	end
end

function BossPhaseController.Start(boss, config, gameConfig)
	local humanoid = boss:FindFirstChildOfClass("Humanoid")
	local root = boss:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return
	end
	local effectsRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AbilityEffects")
	boss:SetAttribute("BossPhase", 1)
	boss:SetAttribute("BaseAttackDamage", boss:GetAttribute("AttackDamage") or 1)
	boss:SetAttribute("BaseWalkSpeed", humanoid.WalkSpeed)
	boss:SetAttribute("AttackCooldownMultiplier", 1)
	local currentPhase = 1

	humanoid.HealthChanged:Connect(function(health)
		local ratio = health / math.max(humanoid.MaxHealth, 1)
		for _, definition in ipairs(config.BossPhases) do
			if definition.Phase > currentPhase and ratio <= definition.HealthThreshold then
				currentPhase = definition.Phase
				applyPhase(boss, humanoid, definition, effectsRemote)
			end
		end
	end)

	task.spawn(function()
		local nextSlam = math.huge
		while boss.Parent and humanoid.Health > 0 do
			local definition = getPhaseDefinition(config, currentPhase)
			if definition then
				if nextSlam == math.huge then
					nextSlam = os.clock() + definition.SlamInterval
				end
				if os.clock() >= nextSlam then
					local origin = root.Position
					effectsRemote:FireAllClients("BossSlamTelegraph", {
						Origin = origin,
						Radius = config.BossSlamRadius,
						Duration = config.BossSlamWindup,
					})
					task.wait(config.BossSlamWindup)
					if boss.Parent and humanoid.Health > 0 then
						effectsRemote:FireAllClients("BossSlam", {
							Origin = root.Position,
							Radius = config.BossSlamRadius,
						})
						for _, player in ipairs(Players:GetPlayers()) do
							local character = player.Character
							local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
							local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
							if targetHumanoid and targetRoot and targetHumanoid.Health > 0
								and (targetRoot.Position - root.Position).Magnitude <= config.BossSlamRadius
								and not player:GetAttribute("AdminGodMode")
								and workspace:GetServerTimeNow() >= (player:GetAttribute("InvulnerableUntil") or 0) then
								damagePlayer(player, targetHumanoid, (boss:GetAttribute("AttackDamage") or 1) * config.BossSlamDamageMultiplier)
							end
						end
					end
					nextSlam = os.clock() + definition.SlamInterval
				end
			end
			task.wait(0.2)
		end
	end)

	task.spawn(function()
		local nextSpecial = os.clock() + config.BossSpecialInterval
		while boss.Parent and humanoid.Health > 0 do
			if os.clock() >= nextSpecial then
				local archetype = boss:GetAttribute("BossArchetype") or "Stone"
				local targetPlayer, targetRoot
				for _, candidate in ipairs(Players:GetPlayers()) do
					local candidateRoot = candidate.Character and candidate.Character:FindFirstChild("HumanoidRootPart")
					if candidateRoot and (not targetRoot or (candidateRoot.Position - root.Position).Magnitude < (targetRoot.Position - root.Position).Magnitude) then targetPlayer, targetRoot = candidate, candidateRoot end
				end
				if targetPlayer and targetRoot then
					local origin, target = root.Position + Vector3.new(0, 3, 0), targetRoot.Position
					effectsRemote:FireAllClients("EnergyBolt", {Origin = origin, Target = target, Duration = 0.35, ImpactTime = workspace:GetServerTimeNow() + 0.35, Radius = 5})
					task.delay(0.35, function()
						if boss.Parent and targetPlayer.Parent and targetPlayer.Character then
							local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
							local currentRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
							if targetHumanoid and currentRoot and (currentRoot.Position - target).Magnitude <= 8 then damagePlayer(targetPlayer, targetHumanoid, (boss:GetAttribute("AttackDamage") or 1) * 0.8) end
						end
					end)
				end
				if archetype == "Stone" or archetype == "Rift" then
					summonMinions(boss, gameConfig)
				end
				if archetype == "Rift" then
					local origin = root.Position
					effectsRemote:FireAllClients("BossVortexTelegraph", {Origin = origin, Radius = config.BossVortexRadius, Duration = config.BossVortexWindup})
					task.wait(config.BossVortexWindup)
					if boss.Parent and humanoid.Health > 0 then
						effectsRemote:FireAllClients("BossVortex", {Origin = root.Position, Radius = config.BossVortexRadius})
						for _, player in ipairs(Players:GetPlayers()) do
							local character = player.Character
							local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
							local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
							local offset = targetRoot and (root.Position - targetRoot.Position)
							if targetHumanoid and targetRoot and targetHumanoid.Health > 0 and offset.Magnitude > 0 and offset.Magnitude <= config.BossVortexRadius then
								targetRoot:ApplyImpulse((offset.Unit + Vector3.new(0, 0.15, 0)).Unit * targetRoot.AssemblyMass * 55)
								damagePlayer(player, targetHumanoid, (boss:GetAttribute("AttackDamage") or 1) * config.BossVortexDamageMultiplier)
							end
						end
					end
				elseif archetype == "Storm" then
					local targets = {}
					for _, player in ipairs(Players:GetPlayers()) do
						local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						if targetRoot then table.insert(targets, targetRoot.Position) end
					end
					effectsRemote:FireAllClients("BossLightningTelegraph", {Targets = targets, Radius = config.BossLightningRadius, Duration = config.BossLightningWindup})
					task.wait(config.BossLightningWindup)
					if boss.Parent and humanoid.Health > 0 then
						effectsRemote:FireAllClients("BossLightning", {Targets = targets, Radius = config.BossLightningRadius})
						local damaged = {}
						for _, position in ipairs(targets) do
							for _, player in ipairs(Players:GetPlayers()) do
								local character = player.Character
								local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
								local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
								if not damaged[player] and targetHumanoid and targetRoot and targetHumanoid.Health > 0 and (targetRoot.Position - position).Magnitude <= config.BossLightningRadius then
									damaged[player] = true
									damagePlayer(player, targetHumanoid, (boss:GetAttribute("AttackDamage") or 1) * config.BossLightningDamageMultiplier)
								end
							end
						end
					end
				end
				nextSpecial = os.clock() + config.BossSpecialInterval
			end
			task.wait(0.2)
		end
	end)
end

return BossPhaseController
