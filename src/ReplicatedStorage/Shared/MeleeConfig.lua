local config = {
	Order = {"Chain", "Lunge", "Cleave", "Whirlwind"},
	Mastery = {XPPerHit = 1, XPPerRank = 25, MaximumRank = 20, DamagePerRank = 0.015},
	Animation = {Windup = 0.06, Strike = 0.14, Recovery = 0.14},
	Chain = {XPPerTarget = 1, XPPerRank = 20, MaximumRank = 5, LevelsPerRank = 15, BaseTargets = 2, DamagePerRank = 0.08, DashTime = 0.14, HitInterval = 0.14, Hits = 3, StandOff = 4, Stun = 0.32},
	Moves = {
		Chain = {DisplayName = "Blink Chain", Key = "H", RequiredLevel = 1, Stamina = 24, Cooldown = 9, Windup = 0.06, Duration = 5, Range = 26, DamageMultiplier = 0.42, Knockback = 26, Description = "Default attack: blink between enemies with three cuts each. Every 20 target XP and 15 player levels unlocks another target (2?7)."},
		Lunge = {DisplayName = "Flash Thrust", Key = "Z", RequiredLevel = 5, Skill = "Melee01", Stamina = 18, Cooldown = 4, Windup = 0.12, Duration = 0.48, Range = 15, DamageMultiplier = 1.4, Knockback = 22, Description = "Step into a piercing thrust. Upgrade Warrior Initiation to unlock."},
		Cleave = {DisplayName = "Skybreaker Cleave", Key = "C", RequiredLevel = 15, Skill = "Melee02", Stamina = 30, Cooldown = 7, Windup = 0.55, Duration = 0.9, Range = 17, DamageMultiplier = 2.6, Knockback = 48, Description = "Wind up an overhead power attack, then release a heavy cleave."},
		Whirlwind = {DisplayName = "Cyclone Edge", Key = "V", RequiredLevel = 35, Skill = "Melee04", Stamina = 40, Cooldown = 10, Windup = 0.18, Duration = 0.8, Range = 14, DamageMultiplier = 0.7, Hits = 3, HitInterval = 0.18, Knockback = 14, Description = "Spin through three sweeping cuts. Each cut can strike nearby enemies once."},
	},
}

-- Both mastery and player level must meet the next rank threshold.
function config.GetChainRank(xp, level)
	return math.clamp(math.min(math.floor(math.max(0, xp or 0) / config.Chain.XPPerRank), math.floor(math.max(0, (level or 1) - 1) / config.Chain.LevelsPerRank)), 0, config.Chain.MaximumRank)
end
return config
