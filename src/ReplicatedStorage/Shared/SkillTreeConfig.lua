local function node(tree, name, tier, column, maximumRank, attribute, perRank, base, extra)
	local value = {
		Tree = tree, DisplayName = name, Tier = tier, Column = column,
		MaximumRank = maximumRank, Cost = 1, Attribute = attribute, PerRank = perRank, Base = base,
	}
	for key, item in pairs(extra or {}) do value[key] = item end
	return value
end

return {
	PointsPerLevel = 1,
	ElementPointsEveryLevels = 3,
	Trees = {"Universal", "Fire", "Ice", "Lightning", "Earth", "Gravity"},
	Order = {
		"Damage", "Vitality", "Flow", "Critical", "Area", "Haste", "AscendantCore",
		"FireMastery", "FireBurn", "FireReach", "FireCataclysm",
		"IceMastery", "IceControl", "IceReach", "IceCataclysm",
		"LightningMastery", "LightningChain", "LightningReach", "LightningCataclysm",
		"EarthMastery", "EarthImpact", "EarthReach", "EarthCataclysm",
		"GravityMastery", "GravityControl", "GravityReach", "GravityCataclysm",
	},
	Nodes = {
		Damage = node("Universal", "Ascendant Force", 1, 1, 10, "SkillDamageMultiplier", 0.04, 1, {Description = "+4% damage per rank."}),
		Vitality = node("Universal", "Vitality", 1, 2, 10, "SkillHealthMultiplier", 0.04, 1, {Description = "+4% maximum health per rank."}),
		Flow = node("Universal", "Energy Flow", 1, 3, 8, "SkillEnergyRegen", 0.75, 0, {Description = "Faster MP recovery."}),
		Critical = node("Universal", "Critical Focus", 2, 1, 8, "SkillCriticalChance", 0.01, 0, {Prerequisites = {{Id = "Damage", Rank = 2}}, Description = "Requires Ascendant Force 2."}),
		Area = node("Universal", "Expanding Power", 2, 2, 8, "SkillAreaMultiplier", 0.035, 1, {Prerequisites = {{Id = "Vitality", Rank = 2}}, Description = "Larger local and ranged effects."}),
		Haste = node("Universal", "Cooldown Haste", 2, 3, 8, "SkillCooldownReduction", 0.02, 0, {Prerequisites = {{Id = "Flow", Rank = 2}}, Description = "Requires Energy Flow 2."}),
		AscendantCore = node("Universal", "Ascendant Core", 3, 2, 1, "AscendantCoreUnlocked", 1, 0, {RequiredLevel = 20, Prerequisites = {{Id = "Critical", Rank = 3}, {Id = "Area", Rank = 3}, {Id = "Haste", Rank = 3}}, Description = "Capstone: empowers every element."}),

		FireMastery = node("Fire", "Inferno Mastery", 1, 2, 10, "FireDamageMultiplier", 0.05, 1, {Description = "+5% Fire damage per rank."}),
		FireBurn = node("Fire", "Burning Soul", 2, 1, 5, "FireStatusBonus", 0.08, 0, {Prerequisites = {{Id = "FireMastery", Rank = 2}}, Description = "Longer, stronger burns."}),
		FireReach = node("Fire", "Wildfire Reach", 2, 3, 5, "FireAreaBonus", 0.05, 0, {Prerequisites = {{Id = "FireMastery", Rank = 2}}, Description = "Expands Fire areas."}),
		FireCataclysm = node("Fire", "Solar Cataclysm", 3, 2, 1, "FireUltimateUnlocked", 1, 0, {RequiredLevel = 18, Prerequisites = {{Id = "FireBurn", Rank = 3}, {Id = "FireReach", Rank = 3}}, Description = "Fire capstone damage surge."}),

		IceMastery = node("Ice", "Absolute Frost", 1, 2, 10, "IceDamageMultiplier", 0.05, 1, {Description = "+5% Ice damage per rank."}),
		IceControl = node("Ice", "Deep Freeze", 2, 1, 5, "IceStatusBonus", 0.08, 0, {Prerequisites = {{Id = "IceMastery", Rank = 2}}, Description = "Improves slow and freeze."}),
		IceReach = node("Ice", "Winter Reach", 2, 3, 5, "IceAreaBonus", 0.05, 0, {Prerequisites = {{Id = "IceMastery", Rank = 2}}, Description = "Expands Ice areas."}),
		IceCataclysm = node("Ice", "Absolute Zero", 3, 2, 1, "IceUltimateUnlocked", 1, 0, {RequiredLevel = 18, Prerequisites = {{Id = "IceControl", Rank = 3}, {Id = "IceReach", Rank = 3}}, Description = "Ice capstone damage surge."}),

		LightningMastery = node("Lightning", "Storm Conductor", 1, 2, 10, "LightningDamageMultiplier", 0.05, 1, {Description = "+5% Lightning damage per rank."}),
		LightningChain = node("Lightning", "Forked Current", 2, 1, 5, "LightningStatusBonus", 0.08, 0, {Prerequisites = {{Id = "LightningMastery", Rank = 2}}, Description = "Adds chain and shock power."}),
		LightningReach = node("Lightning", "Tempest Reach", 2, 3, 5, "LightningAreaBonus", 0.05, 0, {Prerequisites = {{Id = "LightningMastery", Rank = 2}}, Description = "Expands Lightning areas."}),
		LightningCataclysm = node("Lightning", "Heaven's Wrath", 3, 2, 1, "LightningUltimateUnlocked", 1, 0, {RequiredLevel = 18, Prerequisites = {{Id = "LightningChain", Rank = 3}, {Id = "LightningReach", Rank = 3}}, Description = "Lightning capstone damage surge."}),

		EarthMastery = node("Earth", "Mountain Heart", 1, 2, 10, "EarthDamageMultiplier", 0.05, 1, {Description = "+5% Earth damage per rank."}),
		EarthImpact = node("Earth", "Seismic Force", 2, 1, 5, "EarthStatusBonus", 0.08, 0, {Prerequisites = {{Id = "EarthMastery", Rank = 2}}, Description = "Improves knockback and stun."}),
		EarthReach = node("Earth", "Faultline Reach", 2, 3, 5, "EarthAreaBonus", 0.05, 0, {Prerequisites = {{Id = "EarthMastery", Rank = 2}}, Description = "Expands Earth areas."}),
		EarthCataclysm = node("Earth", "World Breaker", 3, 2, 1, "EarthUltimateUnlocked", 1, 0, {RequiredLevel = 18, Prerequisites = {{Id = "EarthImpact", Rank = 3}, {Id = "EarthReach", Rank = 3}}, Description = "Earth capstone damage surge."}),

		GravityMastery = node("Gravity", "Singularity Control", 1, 2, 10, "GravityDamageMultiplier", 0.05, 1, {RequiredLevel = 15, Description = "+5% Gravity damage per rank."}),
		GravityControl = node("Gravity", "Event Horizon", 2, 1, 5, "GravityStatusBonus", 0.08, 0, {Prerequisites = {{Id = "GravityMastery", Rank = 2}}, Description = "Improves pull strength."}),
		GravityReach = node("Gravity", "Orbital Reach", 2, 3, 5, "GravityAreaBonus", 0.05, 0, {Prerequisites = {{Id = "GravityMastery", Rank = 2}}, Description = "Expands Gravity areas."}),
		GravityCataclysm = node("Gravity", "True Singularity", 3, 2, 1, "GravityUltimateUnlocked", 1, 0, {RequiredLevel = 30, Prerequisites = {{Id = "GravityControl", Rank = 3}, {Id = "GravityReach", Rank = 3}}, Description = "Gravity capstone damage surge."}),
	},
}
