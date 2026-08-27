return {
	Order = {"Fire", "Ice", "Lightning", "Earth", "Gravity"},
	Elements = {
		Fire = {DisplayName = "Fire", Color = Color3.fromRGB(255, 85, 35), Accent = Color3.fromRGB(255, 195, 55), Status = "Burn", OpposedBy = "Ice", RequiredLevel = 1},
		Ice = {DisplayName = "Ice", Color = Color3.fromRGB(95, 215, 255), Accent = Color3.fromRGB(225, 250, 255), Status = "Freeze", OpposedBy = "Fire", RequiredLevel = 1},
		Lightning = {DisplayName = "Lightning", Color = Color3.fromRGB(255, 235, 75), Accent = Color3.fromRGB(145, 205, 255), Status = "Shock", RequiredLevel = 1},
		Earth = {DisplayName = "Earth", Color = Color3.fromRGB(155, 105, 55), Accent = Color3.fromRGB(105, 225, 125), Status = "Stun", RequiredLevel = 1},
		Gravity = {DisplayName = "Gravity", Color = Color3.fromRGB(175, 75, 255), Accent = Color3.fromRGB(80, 30, 130), Status = "Compression", RequiredLevel = 20, Advanced = true},
	},
	Interactions = {
		FrozenEarth = {Requires = {"Frozen", "Earth"}, Result = "Shatter", DamageMultiplier = 1.35},
		FrozenLightning = {Requires = {"Frozen", "Lightning"}, Result = "ConductiveShatter", DamageMultiplier = 1.2},
		BurningGravity = {Requires = {"Burning", "Gravity"}, Result = "BurnSpread", Radius = 12},
	},
}
