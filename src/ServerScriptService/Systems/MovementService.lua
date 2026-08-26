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
	local feedbackRemote = remotes:WaitForChild("CombatFeedback")
	local effectsRemote = remotes:WaitForChild("AbilityEffects")
	local cooldowns = {}
	local dodgeCooldowns = {}

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
		cooldowns[player] = nil
		dodgeCooldowns[player] = nil
	end)
end

return MovementService
