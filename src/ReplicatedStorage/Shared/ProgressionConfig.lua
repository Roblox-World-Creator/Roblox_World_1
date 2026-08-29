local config = {
	StartingLevel = 1,
	MaximumLevel = 100,
	StartingXP = 0,
	StartingCoins = 0,
	StartingAttack = 25,
	StartingMaxHealth = 100,
	XPBase = 100,
	XPExponent = 1.45,
	LevelHealthBonus = 10,
	LevelAttackBonus = 3,
	MeleeRange = 11,
	MeleeDamage = 25,
	MeleeCooldown = 0.45,
	MeleeComboReset = 1.1,
	MeleeCombo = {
		{DamageMultiplier = 1, Cooldown = 0.34, Stun = 0.12, Knockback = 5},
		{DamageMultiplier = 1.05, Cooldown = 0.34, Stun = 0.14, Knockback = 6},
		{DamageMultiplier = 1.15, Cooldown = 0.4, Stun = 0.18, Knockback = 8},
		{DamageMultiplier = 1.6, Cooldown = 0.72, Stun = 0.5, Knockback = 42},
	},
	StunImmunitySeconds = 0.3,
	PerfectBlockRearm = 0.5,
	AbilityOrder = {
		"EnergyBolt", "EnergyBurst", "EnergyBeam", "GravityPulse", "ChainLightning", "Tornado",
		"FireBolt", "FlameWave", "Meteor", "IceShard", "FrostNova", "Blizzard",
		"LightningBolt", "Thunderstorm", "RockShot", "GroundSlam", "Boulder",
		"GravityPull", "GravityWell", "BlackHole",
	},
	Abilities = {
		EnergyBolt = {
			Element = "Arcane", EffectProfile = "EnergyBolt01",
			DisplayName = "Energy Bolt",
			Description = "Launch a fast energy projectile that detonates on impact.",
			RequiredLevel = 1,
			RequiredEvolution = 0,
			CastType = "Projectile",
			Targeting = "Point",
			Cooldown = 2,
			EnergyCost = 10,
			Damage = 50,
			Range = 80,
			Radius = 4,
			LocalRadius = 10,
			ProjectileSpeed = 115,
		},
		EnergyBurst = {
			Element = "Arcane", EffectProfile = "EnergyBurst01",
			DisplayName = "Energy Burst",
			Description = "Release a radial blast that throws enemies away.",
			RequiredLevel = 3,
			RequiredEvolution = 0,
			CastType = "Radial",
			Targeting = "Self",
			Cooldown = 6,
			EnergyCost = 25,
			Damage = 70,
			Range = 60,
			Radius = 14,
			LocalRadius = 16,
			Knockback = 45,
		},
		EnergyBeam = {
			Element = "Arcane", EffectProfile = "EnergyBeam01",
			DisplayName = "Energy Beam", Description = "Fire a piercing beam through every enemy in its path.",
			CastType = "Beam", Targeting = "Point", RequiredLevel = 8, RequiredEvolution = 1,
			Cooldown = 8, EnergyCost = 30, Damage = 115, Range = 105, Radius = 4, LocalRadius = 13,
		},
		GravityPulse = {
			Element = "Gravity", EffectProfile = "GravityPulse01",
			DisplayName = "Gravity Pulse", Description = "Collapse nearby space and drag enemies toward you.",
			CastType = "Gravity", Targeting = "Self", RequiredLevel = 15, RequiredEvolution = 1,
			Cooldown = 10, EnergyCost = 35, Damage = 85, Range = 60, Radius = 20, LocalRadius = 22, PullStrength = 58,
		},
		ChainLightning = {
			Element = "Lightning", EffectProfile = "SegmentedLightning01",
			DisplayName = "Chain Lightning", Description = "Arc through a group, seeking new targets after every strike.",
			CastType = "Chain", Targeting = "Point", RequiredLevel = 25, RequiredEvolution = 2,
			Cooldown = 12, EnergyCost = 45, Damage = 100, Range = 75, Radius = 5, LocalRadius = 16, ChainRange = 24, MaximumChains = 6,
		},
		Tornado = {
			Element = "Wind", EffectProfile = "RiftTornado01",
			DisplayName = "Rift Tornado", Description = "Summon a violent vortex that lifts and spins monsters in its wake.",
			CastType = "Tornado", Targeting = "Point", RequiredLevel = 35, RequiredEvolution = 2,
			Cooldown = 16, EnergyCost = 55, Damage = 72, Range = 85, Radius = 16, LocalRadius = 19, Duration = 4,
			TickInterval = 0.5, PullStrength = 70, ProjectileSpeed = 42,
		},
		FireBolt = {DisplayName = "Fire Bolt", Description = "A burning projectile that evolves into multi-shot flame attacks.", Element = "Fire", EffectProfile = "FireBolt01", CastType = "Projectile", Targeting = "Point", RequiredLevel = 1, RequiredEvolution = 0, Cooldown = 2.2, EnergyCost = 10, Damage = 48, Range = 82, Radius = 4, LocalRadius = 10, ProjectileSpeed = 105},
		FlameWave = {DisplayName = "Flame Wave", Description = "Detonate an expanding wave of fire at range or around yourself.", Element = "Fire", EffectProfile = "FlameWave01", CastType = "Radial", Targeting = "Point", RequiredLevel = 4, RequiredEvolution = 0, Cooldown = 6, EnergyCost = 24, Damage = 72, Range = 64, Radius = 15, LocalRadius = 17, Knockback = 30},
		Meteor = {DisplayName = "Meteor", Description = "Call down a high-impact fire blast.", Element = "Fire", EffectProfile = "Meteor01", CastType = "Radial", Targeting = "Point", RequiredLevel = 10, RequiredEvolution = 1, Cooldown = 11, EnergyCost = 38, Damage = 135, Range = 95, Radius = 17, LocalRadius = 16, Knockback = 48},
		IceShard = {DisplayName = "Ice Shard", Description = "Launch a piercing shard of condensed frost.", Element = "Ice", EffectProfile = "IceShard01", CastType = "Projectile", Targeting = "Point", RequiredLevel = 1, RequiredEvolution = 0, Cooldown = 2.1, EnergyCost = 10, Damage = 46, Range = 88, Radius = 3.5, LocalRadius = 10, ProjectileSpeed = 125},
		FrostNova = {DisplayName = "Frost Nova", Description = "Freeze the battlefield with a wide frost eruption.", Element = "Ice", EffectProfile = "FrostNova01", CastType = "Radial", Targeting = "Point", RequiredLevel = 5, RequiredEvolution = 0, Cooldown = 7, EnergyCost = 26, Damage = 65, Range = 60, Radius = 17, LocalRadius = 19, Knockback = 12},
		Blizzard = {DisplayName = "Blizzard", Description = "Create a damaging storm zone that repeatedly controls enemies.", Element = "Ice", EffectProfile = "Blizzard01", CastType = "Tornado", Targeting = "Point", RequiredLevel = 12, RequiredEvolution = 1, Cooldown = 14, EnergyCost = 45, Damage = 38, Range = 85, Radius = 18, LocalRadius = 20, Duration = 4, TickInterval = 0.6, PullStrength = 12, ProjectileSpeed = 55},
		LightningBolt = {DisplayName = "Lightning Bolt", Description = "A nearly instant piercing lightning strike.", Element = "Lightning", EffectProfile = "LightningBolt01", CastType = "Beam", Targeting = "Point", RequiredLevel = 1, RequiredEvolution = 0, Cooldown = 2.6, EnergyCost = 12, Damage = 58, Range = 100, Radius = 2.5, LocalRadius = 11},
		Thunderstorm = {DisplayName = "Thunderstorm", Description = "Overload a large target zone with storm energy.", Element = "Lightning", EffectProfile = "Thunderstorm01", CastType = "Radial", Targeting = "Point", RequiredLevel = 11, RequiredEvolution = 1, Cooldown = 12, EnergyCost = 40, Damage = 108, Range = 85, Radius = 19, LocalRadius = 17, Knockback = 20},
		RockShot = {DisplayName = "Rock Shot", Description = "Fire a dense stone projectile with heavy impact.", Element = "Earth", EffectProfile = "RockShot01", CastType = "Projectile", Targeting = "Point", RequiredLevel = 1, RequiredEvolution = 0, Cooldown = 2.4, EnergyCost = 9, Damage = 55, Range = 78, Radius = 4.5, LocalRadius = 11, ProjectileSpeed = 90},
		GroundSlam = {DisplayName = "Ground Slam", Description = "Crush the ground with shockwaves, debris, and knockback.", Element = "Earth", EffectProfile = "GroundSlam01", CastType = "Radial", Targeting = "Point", RequiredLevel = 6, RequiredEvolution = 0, Cooldown = 7.5, EnergyCost = 28, Damage = 88, Range = 55, Radius = 16, LocalRadius = 20, Knockback = 65},
		Boulder = {DisplayName = "Boulder", Description = "Hurl an explosive boulder through clustered enemies.", Element = "Earth", EffectProfile = "Boulder01", CastType = "Projectile", Targeting = "Point", RequiredLevel = 13, RequiredEvolution = 1, Cooldown = 9, EnergyCost = 34, Damage = 125, Range = 82, Radius = 8, LocalRadius = 15, ProjectileSpeed = 62},
		GravityPull = {DisplayName = "Gravity Pull", Description = "Drag a group toward the chosen point.", Element = "Gravity", EffectProfile = "GravityPull01", CastType = "Gravity", Targeting = "Point", RequiredLevel = 18, RequiredEvolution = 1, Cooldown = 8, EnergyCost = 30, Damage = 62, Range = 68, Radius = 18, LocalRadius = 21, PullStrength = 58},
		GravityWell = {DisplayName = "Gravity Well", Description = "Compress enemies in a powerful gravity field.", Element = "Gravity", EffectProfile = "GravityWell01", CastType = "Gravity", Targeting = "Point", RequiredLevel = 24, RequiredEvolution = 2, Cooldown = 12, EnergyCost = 44, Damage = 105, Range = 78, Radius = 22, LocalRadius = 23, PullStrength = 82},
		BlackHole = {DisplayName = "Black Hole", Description = "Create a sustained singularity that pulls, damages, and launches on collapse.", Element = "Gravity", EffectProfile = "BlackHole01", CastType = "Tornado", Targeting = "Point", RequiredLevel = 35, RequiredEvolution = 2, Cooldown = 18, EnergyCost = 62, Damage = 64, Range = 90, Radius = 24, LocalRadius = 25, Duration = 5, TickInterval = 0.5, PullStrength = 105, ProjectileSpeed = 48},
	},
	MotionOrder = {"PowerDash", "SuperJump", "Flight", "Dodge", "PhaseGuard"},
	MotionPowers = {
		PowerDash = {DisplayName = "Power Dash", Category = "Mobility", RequiredLevel = 1, Cooldown = 1.25, StaminaCost = 18, Description = "Burst forward through danger."},
		SuperJump = {DisplayName = "Super Jump", Category = "Mobility", RequiredLevel = 4, Cooldown = 3.5, StaminaCost = 20, Description = "Launch high with forward momentum."},
		Flight = {DisplayName = "Sky Flight", Category = "Mobility", RequiredLevel = 16, Cooldown = 10, StaminaCost = 30, Description = "Fly and steer for a short duration."},
		Dodge = {DisplayName = "Phase Dodge", Category = "Technique", RequiredLevel = 1, Cooldown = 1, StaminaCost = 20, Description = "Evade with a brief invulnerability window."},
		PhaseGuard = {DisplayName = "Phase Guard", Category = "Technique", RequiredLevel = 12, Cooldown = 8, StaminaCost = 24, Description = "Become invulnerable briefly and release a pulse."},
	},
	Mastery = {
		MaximumLevel = 10,
		XPPerDamage = 0.04,
		XPPerCast = 2,
		DamagePerLevel = 0.04,
		CostReductionPerLevel = 0.015,
		XPBase = 30,
	},
}

-- Every elemental family exposes a full level 1-100 progression. Existing authored
-- powers remain; these add visually and mechanically distinct high-tier choices.
local families = {
	Fire = {"CinderLance", "PhoenixRush", "VolcanoCrown", "SolarJudgment", "InfernoDomain", "StarfallPyre", "Worldflame"},
	Ice = {"HailLance", "GlacierRush", "CrystalCage", "WinterJudgment", "FrozenDomain", "Moonfrost", "EternalWinter"},
	Lightning = {"ArcSpear", "FlashStep", "StormCage", "SkyJudgment", "TempestDomain", "Godspeed", "HeavensWrath"},
	Earth = {"StoneLance", "QuakeRush", "MountainCage", "FaultJudgment", "TectonicDomain", "TitanRise", "WorldBreaker"},
	Gravity = {"OrbitLance", "WarpRush", "EventCage", "VoidJudgment", "SingularityDomain", "StarCollapse", "ZeroHorizon"},
	Poison = {"VenomDart", "ToxicRush", "SporeCage", "PlagueJudgment", "VenomDomain", "HydraCloud", "WorldBlight", "SerpentNova", "AcidRain", "PlagueStar"},
	Prismatic = {"SpectrumBolt", "RainbowRush", "RefractionCage", "AuroraJudgment", "PrismDomain", "ChromaticNova", "SevenfoldRay", "DiamondStorm", "RadiantCrown", "PrismaticEnd"},
}
local elementColors = {Fire = "Flame", Ice = "Frost", Lightning = "Storm", Earth = "Stone", Gravity = "Void", Poison = "Venom", Prismatic = "Spectrum"}
for element, names in pairs(families) do
	for index, id in ipairs(names) do
		if not config.Abilities[id] then
			local level = math.min(100, index * 10 + (element == "Prismatic" and 0 or 10))
			local castTypes = {"Projectile", "Beam", "Radial", "Chain", "Gravity", "Tornado"}
			local castType = castTypes[(index - 1) % #castTypes + 1]
			config.Abilities[id] = {
				DisplayName = string.gsub(id, "(%l)(%u)", "%1 %2"), Element = element,
				EffectProfile = elementColors[element] .. string.format("Tier%02d", index),
				Description = string.format("Tier %d %s art with a unique %s combat pattern.", index, element, string.lower(castType)),
				CastType = castType, Targeting = castType == "Gravity" and "Point" or "Point",
				RequiredLevel = level, RequiredEvolution = math.min(2, math.floor(level / 30)),
				Cooldown = 4 + index * 0.9, EnergyCost = 14 + index * 5,
				Damage = 75 + index * index * 10, Range = 70 + index * 3,
				Radius = 5 + index * 1.5, LocalRadius = 11 + index,
				ProjectileSpeed = 80 + index * 5, Knockback = 18 + index * 4,
				PullStrength = 45 + index * 5, ChainRange = 22, MaximumChains = 3 + index,
				Duration = 2.5 + index * 0.25, TickInterval = 0.6,
				VisualVariant = index, SoundPitch = 0.82 + index * 0.055,
			}
			table.insert(config.AbilityOrder, id)
		end
	end
end

return config
