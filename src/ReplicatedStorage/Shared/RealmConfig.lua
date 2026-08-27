return {
	Order = {"FireWorld", "IceWorld", "StormWorld", "EarthWorld"},
	Realms = {
		FireWorld = {DisplayName = "FIRE REALM", Element = "Fire", PortalName = "EAST", RecommendedLevel = 10, Boss = "Lava Titan", RareDrop = "Inferno Core", Color = Color3.fromRGB(255, 85, 35), Destination = Vector3.new(1200, 6, 0), SizeScale = 4, Mobs = {"FireImp", "LavaGolem", "FireImp", "AshwingDrake"}, Props = {"FireAltarProp01", "FireCrystalProp01", "PortalRuinsProp01"}},
		IceWorld = {DisplayName = "ICE REALM", Element = "Ice", PortalName = "NORTH", RecommendedLevel = 30, Boss = "Frost Giant", RareDrop = "Glacial Core", Color = Color3.fromRGB(100, 220, 255), Destination = Vector3.new(0, 6, -1200), SizeScale = 4, Mobs = {"FrostWolf", "IceGolem", "LabyrinthHorror", "FrostWolf", "IceGolem"}, Props = {"IceAltarProp01", "IceCrystalProp01", "RealmTowerProp01"}},
		StormWorld = {DisplayName = "STORM REALM", Element = "Lightning", PortalName = "WEST", RecommendedLevel = 50, Boss = "Storm Colossus", RareDrop = "Tempest Core", Color = Color3.fromRGB(255, 225, 80), Destination = Vector3.new(-1200, 6, 0), SizeScale = 4, Mobs = {"StormWolf", "StormOrc", "RiftDragon", "StormWolf", "NullHunter"}, Props = {"StormAltarProp01", "StormCrystalProp01", "HeroStatueProp01"}},
		EarthWorld = {DisplayName = "EARTH REALM", Element = "Earth", PortalName = "SOUTH", RecommendedLevel = 70, Boss = "Mountain Guardian", RareDrop = "Tectonic Core", Color = Color3.fromRGB(125, 190, 95), Destination = Vector3.new(0, 6, 1200), SizeScale = 4, Mobs = {"StoneWarrior", "EarthGolem", "OrcChampion", "StoneWarrior", "EarthGolem"}, Props = {"EarthAltarProp01", "EarthCrystalProp01", "PortalRuinsProp01"}},
	},
	FutureRealms = {GravityWorld = {DisplayName = "VOID / GRAVITY REALM", Element = "Gravity", RequiredLevel = 40}},
}
