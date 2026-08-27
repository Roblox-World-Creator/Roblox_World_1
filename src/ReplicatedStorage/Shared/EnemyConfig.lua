local function enemy(displayName, health, damage, speed, xp, coins, color, modelProfile, resistance, options)
	local definition = {
		DisplayName = displayName, Health = health, Damage = damage, Speed = speed,
		RewardXP = xp, RewardCoins = coins, Color = color, ModelProfile = modelProfile,
		KnockbackResistance = resistance or 0, StunResistance = (resistance or 0) * 0.8,
	}
	for key, value in pairs(options or {}) do definition[key] = value end
	return definition
end

return {
	Basic = enemy("Rift Runner", 100, 12, 10, 10, 5, Color3.fromRGB(80, 190, 255), "OrcModel01", 0, {Ability = "Rift Cleave", LootTier = "Basic"}),
	Fast = enemy("Gale Stalker", 60, 8, 17, 15, 8, Color3.fromRGB(120, 255, 180), "ThunderWolfModel01", 0.1, {Ability = "Volt Pounce", AttackStyle = "Lunge", AttackRange = 8, LootTier = "Fast"}),
	Tank = enemy("Ironback", 350, 28, 6, 40, 20, Color3.fromRGB(255, 160, 70), "IronGolemModel01", 0.5, {Ability = "Iron Quake", AttackStyle = "Area", AbilityRadius = 10, StatusEffect = "Crush", LootTier = "Tank"}),
	Boss = enemy("Stone Destroyer", 2500, 60, 5, 1000, 500, Color3.fromRGB(255, 80, 110), "MountainGuardianModel01", 0.85, {Ability = "Worldbreaker Slam", AttackStyle = "Area", AbilityRadius = 18, StatusEffect = "Crush", LootTier = "Boss"}),
	FireImp = enemy("Emberfang", 125, 15, 13, 18, 9, Color3.fromRGB(255, 90, 40), "FireImpModel01", 0.08, {Ability = "Cinder Pounce", AttackStyle = "Lunge", AttackRange = 8, StatusEffect = "Burn", LootTier = "Fast"}),
	LavaGolem = enemy("Magmaheart Colossus", 620, 36, 5, 70, 34, Color3.fromRGB(255, 65, 25), "LavaGolemModel01", 0.65, {Ability = "Magma Rupture", AttackStyle = "Area", AbilityRadius = 12, StatusEffect = "Burn", LootTier = "Tank"}),
	FrostWolf = enemy("Whiteglass Howler", 145, 14, 15, 20, 10, Color3.fromRGB(115, 225, 255), "FrostWolfModel01", 0.12, {Ability = "Frostbite Rush", AttackStyle = "Lunge", AttackRange = 9, StatusEffect = "Slow", LootTier = "Fast"}),
	IceGolem = enemy("Glacial Bastion", 540, 31, 6, 65, 30, Color3.fromRGB(120, 195, 255), "IronGolemModel01", 0.62, {Ability = "Permafrost Quake", AttackStyle = "Area", AbilityRadius = 11, StatusEffect = "Slow", LootTier = "Tank"}),
	StormWolf = enemy("Thunderspine Alpha", 175, 18, 17, 25, 13, Color3.fromRGB(255, 225, 75), "ThunderWolfModel01", 0.18, {Ability = "Arc Pounce", AttackStyle = "Lunge", AttackRange = 9, StatusEffect = "Shock", LootTier = "Fast"}),
	StormOrc = enemy("Tempest Longshot", 210, 23, 10, 30, 16, Color3.fromRGB(165, 125, 255), "OrcArcherModel01", 0.22, {Ability = "Chain Volley", AttackStyle = "Ranged", AttackRange = 34, StatusEffect = "Shock", LootTier = "Elite"}),
	StoneWarrior = enemy("Mossguard Marauder", 260, 25, 8, 34, 18, Color3.fromRGB(135, 175, 95), "OrcModel01", 0.35, {Ability = "Stonecleaver", StatusEffect = "Crush", LootTier = "Tank"}),
	EarthGolem = enemy("Tectonic Smasher", 700, 40, 5, 80, 40, Color3.fromRGB(110, 145, 75), "OrcSmasherModel01", 0.72, {Ability = "Faultline Crash", AttackStyle = "Area", AbilityRadius = 13, StatusEffect = "Crush", LootTier = "Elite"}),
	AshwingDrake = enemy("Ashwing Wyrmling", 320, 29, 12, 48, 24, Color3.fromRGB(255, 115, 55), "AshwingDrakeModel01", 0.28, {Ability = "Scorch Breath", AttackStyle = "Ranged", AttackRange = 30, StatusEffect = "Burn", LootTier = "Elite", VisualHeight = 4.6, HoverHeight = 6, Flying = true}),
	RiftDragon = enemy("Parallax Sky-Tyrant", 920, 46, 11, 110, 58, Color3.fromRGB(165, 80, 255), "RiftDragonModel01", 0.58, {Ability = "Void Breath", AttackStyle = "Ranged", AttackRange = 38, StatusEffect = "Void", LootTier = "Elite", VisualHeight = 6.2, HoverHeight = 9, Flying = true}),
	NullHunter = enemy("Null Corridor Hunter", 390, 34, 15, 58, 29, Color3.fromRGB(225, 65, 120), "NullHunterModel01", 0.3, {Ability = "Phase Rend", AttackStyle = "Lunge", AttackRange = 11, StatusEffect = "Void", LootTier = "Elite"}),
	LabyrinthHorror = enemy("Endless Hall Horror", 760, 41, 9, 92, 46, Color3.fromRGB(205, 205, 175), "LabyrinthHorrorModel01", 0.52, {Ability = "Dread Pulse", AttackStyle = "Area", AbilityRadius = 15, StatusEffect = "Void", LootTier = "Elite"}),
	OrcChampion = enemy("Runebound Orc Champion", 480, 38, 9, 62, 31, Color3.fromRGB(110, 205, 105), "OrcWarriorModel01", 0.48, {Ability = "Runic Warcry", AttackStyle = "Area", AbilityRadius = 9, StatusEffect = "Crush", LootTier = "Elite"}),
}
