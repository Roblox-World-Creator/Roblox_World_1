return {
	Rarities = {
		Common = {Weight = 100, ModifierCount = 0}, Uncommon = {Weight = 45, ModifierCount = 1},
		Rare = {Weight = 18, ModifierCount = 2}, Epic = {Weight = 6, ModifierCount = 3},
		Legendary = {Weight = 1.5, ModifierCount = 4}, Mythic = {Weight = 0.25, ModifierCount = 5},
	},
	PickupProfiles = {
		XP = {Shape = "Crystal", Color = Color3.fromRGB(185, 100, 255)}, Health = {Shape = "Orb", Color = Color3.fromRGB(255, 75, 105)},
		Energy = {Shape = "Orb", Color = Color3.fromRGB(80, 180, 255)}, Gold = {Shape = "Coin", Color = Color3.fromRGB(255, 210, 70)},
		Skill = {Shape = "Rune", Color = Color3.fromRGB(110, 255, 200)}, Transformation = {Shape = "SpiritCrystal", Color = Color3.fromRGB(255, 150, 245)},
		BossCore = {Shape = "Core", Color = Color3.fromRGB(255, 100, 45)},
	},
	ModifierPool = {"Damage", "CriticalChance", "CriticalDamage", "AreaSize", "ChainCount", "ChainRange", "BurnDamage", "FreezeChance", "Knockback", "MovementSpeed", "EnergyRegen"},
}
