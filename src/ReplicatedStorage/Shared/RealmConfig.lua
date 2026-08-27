return {
	Order = {"FireWorld", "IceWorld", "StormWorld", "EarthWorld"},
	Realms = {
		FireWorld = {DisplayName = "FIRE REALM", Element = "Fire", PortalName = "EAST", RecommendedLevel = 10, Boss = "Lava Titan", RareDrop = "Inferno Core", Color = Color3.fromRGB(255, 85, 35), Destination = Vector3.new(420, 6, 0)},
		IceWorld = {DisplayName = "ICE REALM", Element = "Ice", PortalName = "NORTH", RecommendedLevel = 15, Boss = "Frost Giant", RareDrop = "Glacial Core", Color = Color3.fromRGB(100, 220, 255), Destination = Vector3.new(0, 6, -420)},
		StormWorld = {DisplayName = "STORM REALM", Element = "Lightning", PortalName = "WEST", RecommendedLevel = 20, Boss = "Storm Colossus", RareDrop = "Tempest Core", Color = Color3.fromRGB(255, 225, 80), Destination = Vector3.new(-420, 6, 0)},
		EarthWorld = {DisplayName = "EARTH REALM", Element = "Earth", PortalName = "SOUTH", RecommendedLevel = 25, Boss = "Mountain Guardian", RareDrop = "Tectonic Core", Color = Color3.fromRGB(125, 190, 95), Destination = Vector3.new(0, 6, 420)},
	},
	FutureRealms = {GravityWorld = {DisplayName = "VOID / GRAVITY REALM", Element = "Gravity", RequiredLevel = 40}},
}
