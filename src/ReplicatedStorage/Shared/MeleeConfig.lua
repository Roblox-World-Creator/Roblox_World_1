return {
	Order = {"Lunge", "Cleave", "Whirlwind"},
	Mastery = {XPPerHit = 1, XPPerRank = 25, MaximumRank = 20, DamagePerRank = 0.015},
	Animation = {Windup = 0.06, Strike = 0.14, Recovery = 0.14},
	Moves = {
		Lunge = {DisplayName = "Flash Thrust", Key = "Z", RequiredLevel = 5, Skill = "Melee01", Stamina = 18, Cooldown = 4, Windup = 0.12, Duration = 0.48, Range = 15, DamageMultiplier = 1.4, Knockback = 22, Description = "Step into a piercing thrust. Upgrade Warrior Initiation to unlock."},
		Cleave = {DisplayName = "Skybreaker Cleave", Key = "C", RequiredLevel = 15, Skill = "Melee02", Stamina = 30, Cooldown = 7, Windup = 0.55, Duration = 0.9, Range = 17, DamageMultiplier = 2.6, Knockback = 48, Description = "Wind up an overhead power attack, then release a heavy cleave."},
		Whirlwind = {DisplayName = "Cyclone Edge", Key = "V", RequiredLevel = 35, Skill = "Melee04", Stamina = 40, Cooldown = 10, Windup = 0.18, Duration = 0.8, Range = 14, DamageMultiplier = 0.7, Hits = 3, HitInterval = 0.18, Knockback = 14, Description = "Spin through three sweeping cuts. Each cut can strike nearby enemies once."},
	},
}
