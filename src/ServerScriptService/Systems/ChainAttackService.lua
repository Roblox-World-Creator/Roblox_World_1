local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.MeleeConfig)
local CrowdControl = require(script.Parent.CrowdControlService)
local ChainAttackService = {}

function ChainAttackService.Start(config)
	local active = {}
	local api = {}
	function api.Cancel(player)
		local state = active[player]
		if not state then return end
		active[player] = nil
		if state.Root.Parent then
			pcall(function() state.Root:SetNetworkOwnershipAuto() end)
		end
		if state.Humanoid.Parent then state.Humanoid.AutoRotate = state.AutoRotate end
		player:SetAttribute("SwordMoveBusyUntil", 0)
	end
	local function targetFrom(root, visited, parameters)
		local closest, distance = nil, Config.Moves.Chain.Range
		for _, enemy in ipairs(config.GetEnemies(root.Position, distance)) do
			local target = enemy:FindFirstChild("HumanoidRootPart")
			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			if visited[enemy] or not target or not humanoid or humanoid.Health <= 0 then continue end
			local offset = target.Position - root.Position
			if offset.Magnitude < distance and math.abs(offset.Y) < 10 and not workspace:Raycast(root.Position, offset, parameters) then
				closest, distance = enemy, offset.Magnitude
			end
		end
		return closest
	end
	function api.CanBegin(character, root)
		local parameters = RaycastParams.new()
		parameters.FilterType = Enum.RaycastFilterType.Exclude
		parameters.FilterDescendantsInstances = {character, workspace:FindFirstChild("Enemies") or character}
		parameters.RespectCanCollide = true
		return targetFrom(root, {}, parameters) ~= nil
	end
	function api.Begin(player, character, root, humanoid, weapon)
		api.Cancel(player)
		local state = {Root = root, Humanoid = humanoid, AutoRotate = humanoid.AutoRotate}
		active[player] = state
		local deadline = workspace:GetServerTimeNow() + Config.Moves.Chain.Duration
		local rank = Config.GetChainRank(player:GetAttribute("ChainMasteryXP"), player:GetAttribute("Level"))
		local chain, move = Config.Chain, Config.Moves.Chain
		player:SetAttribute("SwordMoveBusyUntil", workspace:GetServerTimeNow() + move.Duration)
		local parameters = RaycastParams.new()
		parameters.FilterType = Enum.RaycastFilterType.Exclude
		parameters.FilterDescendantsInstances = {character, workspace:FindFirstChild("Enemies") or character}
		parameters.RespectCanCollide = true
		local function valid()
			return workspace:GetServerTimeNow() < deadline and active[player] == state and player.Parent and player.Character == character and root.Parent and humanoid.Health > 0
				and player:GetAttribute("EquippedWeapon") == weapon and not player:GetAttribute("EvolutionTransforming")
		end
		task.spawn(function()
			local ok, message = pcall(function()
				if not valid() then return end
				root:SetNetworkOwner(nil)
				humanoid.AutoRotate = false
				local visited = {}
				for hop = 1, chain.BaseTargets + rank do
					if not valid() then break end
					local enemy = targetFrom(root, visited, parameters)
					if not enemy then break end
					visited[enemy] = true
					local target = enemy:FindFirstChild("HumanoidRootPart")
					local start = root.Position
					local offset = target.Position - start
					local flat = Vector3.new(offset.X, 0, offset.Z)
					local direction = flat.Magnitude > 0.1 and flat.Unit or root.CFrame.LookVector
					local destination = target.Position - direction * chain.StandOff
					-- Sweep the player's volume, not just a sight ray, before every dash.
					local displacement = destination - start
					if displacement.Magnitude > 0.1 and workspace:Blockcast(root.CFrame, Vector3.new(3, 4, 3), displacement, parameters) then break end
					config.Effects:FireAllClients("ChainDash", {Character = character, Origin = start, Target = destination, Element = player:GetAttribute("EquippedWeaponElement"), Tier = rank + 1})
					local elapsed = 0
					while elapsed < chain.DashTime and valid() do
						elapsed += task.wait()
						if not valid() then break end
						local position = start:Lerp(destination, math.min(1, elapsed / chain.DashTime))
						local step = position - root.Position
						if step.Magnitude > 0.01 and workspace:Blockcast(root.CFrame, Vector3.new(3, 4, 3), step, parameters) then return end
						root.CFrame = CFrame.lookAt(position, position + direction)
						root.AssemblyLinearVelocity = Vector3.zero
					end
					local trained = false
					for hit = 1, chain.Hits do
						if not valid() or not target.Parent or (target.Position - root.Position).Magnitude > chain.StandOff + 5 then break end
						if workspace:Raycast(root.Position, target.Position - root.Position, parameters) then break end
						local finisher = hit == chain.Hits
						local result = config.Damage(player, enemy, move.DamageMultiplier * (1 + rank * chain.DamagePerRank) * (finisher and 1.6 or 1), finisher)
						if not result then break end
						if not trained and not enemy:GetAttribute("IsPractice") then
							trained = true
							player:SetAttribute("ChainMasteryXP", math.min(chain.MaximumRank * chain.XPPerRank, (player:GetAttribute("ChainMasteryXP") or 0) + chain.XPPerTarget))
						end
						CrowdControl.Stun(enemy, chain.Stun, 0.15, false)
						config.Effects:FireAllClients("ChainStrike", {Character = character, Origin = target.Position, Direction = direction, Element = player:GetAttribute("EquippedWeaponElement"), Combo = hit, Finisher = finisher, Tier = rank + 1})
						if finisher then config.Knockback(enemy, root.Position, move.Knockback) end
						task.wait(chain.HitInterval)
					end
				end
			end)
			if active[player] == state then api.Cancel(player) end
			if not ok then warn("Chain attack stopped: " .. tostring(message)) end
		end)
	end
	function api.Destroy()
		for player in pairs(active) do api.Cancel(player) end
	end
	return api
end

return ChainAttackService
