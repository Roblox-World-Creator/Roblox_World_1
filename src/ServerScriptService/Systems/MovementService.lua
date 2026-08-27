local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementService = {}

local function addDashTrail(root)
	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(-1, 0, 0)
	attachment0.Parent = root
	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(1, 0, 0)
	attachment1.Parent = root
	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(Color3.fromRGB(90, 225, 255), Color3.fromRGB(110, 120, 255))
	trail.LightEmission = 1
	trail.Lifetime = 0.18
	trail.Parent = root
	Debris:AddItem(attachment0, 0.35)
	Debris:AddItem(attachment1, 0.35)
end

function MovementService.Start(resourceConfig, powerService)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local dashRemote = remotes:FindFirstChild("DashRemote") or Instance.new("RemoteEvent")
	dashRemote.Name = "DashRemote"
	dashRemote.Parent = remotes
	local dodgeRemote = remotes:FindFirstChild("DodgeRemote") or Instance.new("RemoteEvent")
	dodgeRemote.Name = "DodgeRemote"
	dodgeRemote.Parent = remotes
	local movementRemote = remotes:FindFirstChild("MovementRemote") or Instance.new("RemoteEvent")
	movementRemote.Name, movementRemote.Parent = "MovementRemote", remotes
	local feedbackRemote = remotes:WaitForChild("CombatFeedback")
	local effectsRemote = remotes:WaitForChild("AbilityEffects")
	local cooldowns = {}
	local dodgeCooldowns = {}
	local specialCooldowns = {}
	local flightStates = {}

	local function stopEagleFlight(player)
		local state = flightStates[player]
		flightStates[player] = nil
		player:SetAttribute("EagleFlightActive", false)
		if not state then return end
		state.Running = false
		for _, mover in ipairs({state.Velocity, state.Gyro}) do if mover and mover.Parent then mover:Destroy() end end
		if state.Humanoid and state.Humanoid.Parent then state.Humanoid.AutoRotate = state.AutoRotate end
		for _, joint in ipairs(state.Wings or {}) do if joint.Parent then joint.Transform = CFrame.identity end end
	end

	movementRemote.OnServerEvent:Connect(function(player, powerName)
		if powerName == "EagleFlight" and flightStates[player] then
			stopEagleFlight(player)
			feedbackRemote:FireClient(player, "CastAccepted", "EagleFlight", nil, 0)
			return
		end
		local eagleFlight = powerName == "EagleFlight" and player:GetAttribute("ActiveTransformation") == "Eagle"
		local definition = eagleFlight and {Cooldown = 4, StaminaCost = 18}
			or (powerService and powerService.GetMotionDefinition and powerService.GetMotionDefinition(powerName))
		if not definition or (not eagleFlight and not powerService.IsMotionActive(player, powerName)) then return end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root or humanoid.Health <= 0 or (specialCooldowns[player] and (specialCooldowns[player][powerName] or 0) > os.clock()) then return end
		local stamina = player:GetAttribute("Stamina") or 0
		local cost = definition.StaminaCost or 20
		if stamina < cost then feedbackRemote:FireClient(player, "CastRejected", "Need more stamina"); return end
		player:SetAttribute("Stamina", stamina - cost)
		player:SetAttribute("LastStaminaUse", workspace:GetServerTimeNow())
		specialCooldowns[player] = specialCooldowns[player] or {}
		specialCooldowns[player][powerName] = os.clock() + (definition.Cooldown or 3)
		if powerName == "SuperJump" then
			root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 82, root.AssemblyLinearVelocity.Z) + root.CFrame.LookVector * 24
			effectsRemote:FireAllClients("PowerLocal", {Ability = "SuperJump", Origin = root.Position, Radius = 10})
		elseif powerName == "EagleFlight" then
			local velocity = Instance.new("BodyVelocity")
			velocity.Name, velocity.MaxForce, velocity.P = "EagleFlightVelocity", Vector3.new(900000, 900000, 900000), 22000
			velocity.Velocity, velocity.Parent = Vector3.new(0, 42, 0), root
			local gyro = Instance.new("BodyGyro")
			gyro.Name, gyro.MaxTorque, gyro.P, gyro.D = "EagleFlightGyro", Vector3.new(0, 700000, 0), 16000, 800
			gyro.CFrame, gyro.Parent = root.CFrame, root
			local wings = {}
			for _, descendant in ipairs(character:GetDescendants()) do
				if descendant:IsA("Motor6D") and string.find(descendant.Name, "EagleFeather", 1, true) then table.insert(wings, descendant) end
			end
			flightStates[player] = {Running = true, Velocity = velocity, Gyro = gyro, Humanoid = humanoid, AutoRotate = humanoid.AutoRotate, Wings = wings}
			humanoid.AutoRotate = false
			player:SetAttribute("EagleFlightActive", true)
			task.spawn(function()
				local state = flightStates[player]
				local started = os.clock()
				while state and state.Running and flightStates[player] == state and root.Parent and humanoid.Health > 0 and player:GetAttribute("ActiveTransformation") == "Eagle" do
					local elapsed = os.clock() - started
					local direction = humanoid.MoveDirection
					local horizontal = direction.Magnitude > 0.1 and Vector3.new(direction.X, 0, direction.Z).Unit or Vector3.zero
					local lift = elapsed < 1.15 and 38 - elapsed * 18 or (horizontal.Magnitude > 0 and 4 or 1.5)
					velocity.Velocity = horizontal * 58 + Vector3.new(0, lift, 0)
					if horizontal.Magnitude > 0.1 then gyro.CFrame = CFrame.lookAt(root.Position, root.Position + horizontal) end
					local flap = math.sin(elapsed * 11) * math.rad(13)
					for _, joint in ipairs(wings) do
						local side = string.find(joint.Name, "Left", 1, true) and -1 or 1
						joint.Transform = CFrame.Angles(0, 0, side * flap)
					end
					task.wait(0.05)
				end
				if flightStates[player] == state then stopEagleFlight(player) end
			end)
			effectsRemote:FireAllClients("PowerCast", {Ability = powerName, Origin = root.Position, Target = root.Position + root.CFrame.LookVector * 36, Duration = 2.5})
		elseif powerName == "Flight" then
			task.spawn(function()
				local started = os.clock()
				local duration = 3.5
				local finish = started + duration
				while os.clock() < finish and root.Parent and humanoid.Health > 0 do
					local direction = humanoid.MoveDirection.Magnitude > 0.1 and humanoid.MoveDirection or root.CFrame.LookVector
					root.AssemblyLinearVelocity = direction * 58 + Vector3.new(0, 8, 0)
					task.wait(0.08)
				end
			end)
			effectsRemote:FireAllClients("PowerCast", {Ability = powerName, Origin = root.Position, Target = root.Position + root.CFrame.LookVector * 36, Duration = 3.5})
		elseif powerName == "PhaseGuard" then
			player:SetAttribute("InvulnerableUntil", workspace:GetServerTimeNow() + 1.4)
			effectsRemote:FireAllClients("PowerLocal", {Ability = "PhaseGuard", Origin = root.Position, Radius = 12})
		else
			return
		end
		feedbackRemote:FireClient(player, "CastAccepted", powerName, nil, definition.Cooldown or 3)
	end)

	dashRemote.OnServerEvent:Connect(function(player)
		if powerService and not powerService.IsMotionActive(player, "PowerDash") then return end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root or humanoid.Health <= 0 then
			return
		end
		if (cooldowns[player] or 0) > os.clock() then
			feedbackRemote:FireClient(player, "CastRejected", "Dash cooling down")
			return
		end
		local stamina = player:GetAttribute("Stamina") or 0
		if stamina < resourceConfig.DashCost then
			feedbackRemote:FireClient(player, "CastRejected", "Need more stamina")
			return
		end

		local direction = root.CFrame.LookVector
		local parameters = RaycastParams.new()
		parameters.FilterType = Enum.RaycastFilterType.Exclude
		parameters.FilterDescendantsInstances = {character}
		parameters.RespectCanCollide = true
		local result = workspace:Raycast(root.Position, direction * resourceConfig.DashDistance, parameters)
		local distance = result and math.max(0, result.Distance - 3) or resourceConfig.DashDistance
		local destination = root.Position + direction * distance
		player:SetAttribute("Stamina", stamina - resourceConfig.DashCost)
		player:SetAttribute("LastStaminaUse", workspace:GetServerTimeNow())
		player:SetAttribute("Blocking", false)
		cooldowns[player] = os.clock() + resourceConfig.DashCooldown
		character:PivotTo(CFrame.lookAt(destination, destination + direction))
		addDashTrail(root)
		feedbackRemote:FireClient(player, "CastAccepted", "PowerDash", resourceConfig.DashCooldown)
	end)

	dodgeRemote.OnServerEvent:Connect(function(player, requestedDirection)
		if powerService and not powerService.IsMotionActive(player, "Dodge") then return end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root or humanoid.Health <= 0 or typeof(requestedDirection) ~= "Vector3"
			or requestedDirection.X ~= requestedDirection.X
			or requestedDirection.Y ~= requestedDirection.Y
			or requestedDirection.Z ~= requestedDirection.Z then
			return
		end
		if (dodgeCooldowns[player] or 0) > os.clock() then
			return
		end
		local stamina = player:GetAttribute("Stamina") or 0
		if stamina < resourceConfig.DodgeCost then
			feedbackRemote:FireClient(player, "CastRejected", "Need more stamina")
			return
		end
		local horizontal = Vector3.new(requestedDirection.X, 0, requestedDirection.Z)
		if horizontal.Magnitude < 0.1 then
			horizontal = -root.CFrame.LookVector
		end
		local direction = horizontal.Unit
		local parameters = RaycastParams.new()
		parameters.FilterType = Enum.RaycastFilterType.Exclude
		parameters.FilterDescendantsInstances = {character}
		parameters.RespectCanCollide = true
		local result = workspace:Raycast(root.Position, direction * resourceConfig.DodgeDistance, parameters)
		local distance = result and math.max(0, result.Distance - 2.5) or resourceConfig.DodgeDistance
		local destination = root.Position + direction * distance
		local startPosition = root.Position
		local now = workspace:GetServerTimeNow()
		player:SetAttribute("Stamina", stamina - resourceConfig.DodgeCost)
		player:SetAttribute("LastStaminaUse", now)
		player:SetAttribute("InvulnerableUntil", now + resourceConfig.DodgeInvulnerability)
		player:SetAttribute("Blocking", false)
		dodgeCooldowns[player] = os.clock() + resourceConfig.DodgeCooldown
		character:PivotTo(CFrame.lookAt(destination, destination + root.CFrame.LookVector))
		effectsRemote:FireAllClients("Dodge", {
			Origin = startPosition,
			Direction = direction,
			Character = character,
		})
		feedbackRemote:FireClient(player, "CastAccepted", "Dodge", resourceConfig.DodgeCooldown)
	end)

	Players.PlayerRemoving:Connect(function(player)
		stopEagleFlight(player)
		cooldowns[player] = nil
		dodgeCooldowns[player] = nil
		specialCooldowns[player] = nil
	end)
end

return MovementService
