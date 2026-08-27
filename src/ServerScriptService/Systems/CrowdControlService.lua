local CrowdControlService = {}

local function resistance(enemy, kind)
	if kind == "Stun" or kind == "Freeze" then return math.clamp(enemy:GetAttribute("StunResistance") or 0, 0, 0.95) end
	return math.clamp(enemy:GetAttribute("KnockbackResistance") or 0, 0, 0.95)
end

function CrowdControlService.Push(enemy, origin, strength, lift)
	local root = enemy and enemy:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local offset = root.Position - origin
	local direction = offset.Magnitude > 0 and offset.Unit or Vector3.zAxis
	local scale = 1 - resistance(enemy, "Push")
	root:ApplyImpulse((direction + Vector3.new(0, lift or 0.18, 0)).Unit * strength * scale * root.AssemblyMass)
	return true
end

function CrowdControlService.Pull(enemy, origin, strength)
	local root = enemy and enemy:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local offset = origin - root.Position
	if offset.Magnitude <= 0 then return false end
	root:ApplyImpulse((offset.Unit + Vector3.new(0, 0.1, 0)).Unit * strength * (1 - resistance(enemy, "Pull")) * root.AssemblyMass)
	return true
end

function CrowdControlService.Knockup(enemy, strength)
	local root = enemy and enemy:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	root:ApplyImpulse(Vector3.yAxis * strength * (1 - resistance(enemy, "Knockup")) * root.AssemblyMass)
	return true
end

function CrowdControlService.Stun(enemy, duration, immunitySeconds, force)
	local now = workspace:GetServerTimeNow()
	if not force and now < (enemy:GetAttribute("NextStunnableAt") or 0) then return false end
	local actual = duration * (1 - resistance(enemy, "Stun"))
	if actual <= 0.03 then return false end
	enemy:SetAttribute("StunnedUntil", math.max(enemy:GetAttribute("StunnedUntil") or 0, now + actual))
	enemy:SetAttribute("NextStunnableAt", now + actual + (immunitySeconds or 0.3))
	return true
end

function CrowdControlService.Slow(enemy, multiplier, duration)
	local now = workspace:GetServerTimeNow()
	enemy:SetAttribute("SlowMultiplier", math.clamp(multiplier, 0.2, 1))
	enemy:SetAttribute("SlowedUntil", math.max(enemy:GetAttribute("SlowedUntil") or 0, now + duration * (1 - resistance(enemy, "Stun") * 0.6)))
end

function CrowdControlService.Freeze(enemy, duration)
	local now = workspace:GetServerTimeNow()
	local actual = duration * (1 - resistance(enemy, "Freeze"))
	enemy:SetAttribute("FrozenUntil", math.max(enemy:GetAttribute("FrozenUntil") or 0, now + actual))
	return CrowdControlService.Stun(enemy, actual, 0.5, false)
end

return CrowdControlService
