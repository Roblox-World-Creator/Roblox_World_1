local DamageService = {}

function DamageService.ApplyEnemyDamage(player, enemy, amount)
	if not player or not player.Parent or not enemy or not enemy.Parent then
		return nil
	end

	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end

	local critical = math.random() < math.clamp(player:GetAttribute("CriticalChance") or 0.05, 0, 0.75)
	local criticalMultiplier = critical and math.max(1, player:GetAttribute("CriticalDamage") or 1.5) or 1
	local finalDamage = math.max(0, tonumber(amount) or 0) * criticalMultiplier * (enemy:GetAttribute("DamageTakenMultiplier") or 1)
	if finalDamage <= 0 then
		return nil
	end

	local healthBefore = humanoid.Health
	local appliedDamage = math.min(finalDamage, healthBefore)
	enemy:SetAttribute("LastDamagerUserId", player.UserId)
	enemy:SetAttribute("AggroUserId", player.UserId)
	enemy:SetAttribute("Damage_" .. player.UserId, (enemy:GetAttribute("Damage_" .. player.UserId) or 0) + appliedDamage)
	humanoid:TakeDamage(finalDamage)

	return {
		Amount = appliedDamage,
		Killed = healthBefore > 0 and humanoid.Health <= 0,
		Critical = critical,
	}
end

return DamageService
