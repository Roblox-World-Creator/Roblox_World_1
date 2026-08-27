-- Stable gameplay IDs resolve to optional presentation profiles. A nil AssetId intentionally uses procedural fallback art.
return {
	Version = 1,
	Weapons = {
		IronBlade = {ModelId = "BasicSwordModel01", AssetId = nil, Fallback = "Blade"},
		ThunderKatana = {ModelId = "ThunderKatanaModel01", AssetId = nil, Fallback = "Katana"},
		InfernoSword = {ModelId = "InfernoSwordModel01", AssetId = nil, Fallback = "Greatsword"},
		FrostSpear = {ModelId = "FrostSpearModel01", AssetId = nil, Fallback = "Spear"},
		Earthbreaker = {ModelId = "EarthbreakerModel01", AssetId = nil, Fallback = "Hammer"},
		GravityHammer = {ModelId = "GravityHammerModel01", AssetId = nil, Fallback = "Hammer"},
		StormRifle = {ModelId = "StormRifleModel01", AssetId = nil, Fallback = "Rifle"},
		VoidStaff = {ModelId = "VoidStaffModel01", AssetId = nil, Fallback = "Staff"},
	},
	Transformations = {
		Wolf = {ModelId = "WolfModel01", AssetId = nil, Fallback = "AvatarMorph"},
		Bear = {ModelId = "BearModel01", AssetId = nil, Fallback = "AvatarMorph"},
		Eagle = {ModelId = "EagleModel01", AssetId = nil, Fallback = "AvatarMorph"},
	},
	Effects = {
		Fire = {EffectProfile = "FireBurst01"}, Ice = {EffectProfile = "FrostBurst01"},
		Lightning = {EffectProfile = "SegmentedLightning01"}, Earth = {EffectProfile = "RockImpact01"},
		Gravity = {EffectProfile = "GravityDistortion01"},
	},
}
