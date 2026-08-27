return {
	PointsPerLevel = 1,
	ElementPointsEveryLevels = 3,
	Order = {"Damage", "Vitality", "Flow", "Haste", "Critical", "Area", "FireMastery", "IceMastery", "LightningMastery", "EarthMastery", "GravityMastery"},
	Nodes = {
		Damage = {Tree = "Universal", DisplayName = "Ascendant Force", MaximumRank = 10, Cost = 1, Attribute = "SkillDamageMultiplier", PerRank = 0.04, Base = 1},
		Vitality = {Tree = "Universal", DisplayName = "Vitality", MaximumRank = 10, Cost = 1, Attribute = "SkillHealthMultiplier", PerRank = 0.04, Base = 1},
		Flow = {Tree = "Universal", DisplayName = "Energy Flow", MaximumRank = 8, Cost = 1, Attribute = "SkillEnergyRegen", PerRank = 0.75, Base = 0},
		Haste = {Tree = "Universal", DisplayName = "Cooldown Haste", MaximumRank = 8, Cost = 1, Attribute = "SkillCooldownReduction", PerRank = 0.02, Base = 0},
		Critical = {Tree = "Universal", DisplayName = "Critical Focus", MaximumRank = 8, Cost = 1, Attribute = "SkillCriticalChance", PerRank = 0.01, Base = 0},
		Area = {Tree = "Universal", DisplayName = "Expanding Power", MaximumRank = 8, Cost = 1, Attribute = "SkillAreaMultiplier", PerRank = 0.035, Base = 1},
		FireMastery = {Tree = "Fire", DisplayName = "Inferno Mastery", MaximumRank = 10, Cost = 1, Attribute = "FireDamageMultiplier", PerRank = 0.05, Base = 1},
		IceMastery = {Tree = "Ice", DisplayName = "Absolute Frost", MaximumRank = 10, Cost = 1, Attribute = "IceDamageMultiplier", PerRank = 0.05, Base = 1},
		LightningMastery = {Tree = "Lightning", DisplayName = "Storm Conductor", MaximumRank = 10, Cost = 1, Attribute = "LightningDamageMultiplier", PerRank = 0.05, Base = 1},
		EarthMastery = {Tree = "Earth", DisplayName = "Mountain Heart", MaximumRank = 10, Cost = 1, Attribute = "EarthDamageMultiplier", PerRank = 0.05, Base = 1},
		GravityMastery = {Tree = "Gravity", DisplayName = "Singularity Control", MaximumRank = 10, Cost = 1, Attribute = "GravityDamageMultiplier", PerRank = 0.05, Base = 1, RequiredLevel = 20},
	},
}
