return {
	Order = {"FireWorld", "IceWorld", "StormWorld", "EarthWorld"},
	Realms = {
		FireWorld = {DisplayName = "FIRE REALM", Element = "Fire", PortalName = "EAST", RecommendedLevel = 10, Boss = "Lava Titan", RareDrop = "Inferno Core", Color = Color3.fromRGB(255, 85, 35), Destination = Vector3.new(2200, 6, 0), SizeScale = 6, SafeRadius = 72, Population = 18, Mobs = {"FireImp", "LavaGolem", "AshwingDrake", "Basic", "NullHunter"}, Props = {"FireAltarProp01", "FireCrystalProp01", "PortalRuinsProp01"}},
		IceWorld = {DisplayName = "ICE REALM", Element = "Ice", PortalName = "NORTH", RecommendedLevel = 30, Boss = "Frost Giant", RareDrop = "Glacial Core", Color = Color3.fromRGB(100, 220, 255), Destination = Vector3.new(0, 6, -2200), SizeScale = 6, SafeRadius = 72, Population = 18, Mobs = {"FrostWolf", "IceGolem", "LabyrinthHorror", "Fast", "StormOrc"}, Props = {"IceAltarProp01", "IceCrystalProp01"}},
		StormWorld = {DisplayName = "STORM REALM", Element = "Lightning", PortalName = "WEST", RecommendedLevel = 50, Boss = "Storm Colossus", RareDrop = "Tempest Core", Color = Color3.fromRGB(255, 225, 80), Destination = Vector3.new(-2200, 6, 0), SizeScale = 6, SafeRadius = 72, Population = 20, Mobs = {"StormWolf", "StormOrc", "RiftDragon", "NullHunter", "Fast", "OrcChampion"}, Props = {"StormAltarProp01", "StormCrystalProp01", "HeroStatueProp01"}},
		EarthWorld = {DisplayName = "EARTH REALM", Element = "Earth", PortalName = "SOUTH", RecommendedLevel = 70, Boss = "Mountain Guardian", RareDrop = "Tectonic Core", Color = Color3.fromRGB(125, 190, 95), Destination = Vector3.new(0, 6, 2200), SizeScale = 6, SafeRadius = 72, Population = 20, Mobs = {"StoneWarrior", "EarthGolem", "OrcChampion", "Tank", "Basic", "LabyrinthHorror"}, Props = {"EarthAltarProp01", "EarthCrystalProp01", "PortalRuinsProp01"}},
	},
	FutureRealms = {GravityWorld = {DisplayName = "VOID / GRAVITY REALM", Element = "Gravity", RequiredLevel = 40}},
}
