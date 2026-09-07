-- Presentation only: combat ranges, damage and cooldowns remain server-owned.
return {
	Scenery = {Outposts = 6, OutpostRadius = 0.31, TerraceWidth = 72, RampLength = 90, RampWidth = 26, Mountains = 28, AmbientRange = 240},
	Effects = {Distance = 320, MaxParts = 420, ArcSegments = 18, LowArcSegments = 9, BurstCount = 32, LowBurstCount = 10},
	Weather = {UpdateInterval = 0.2, Transition = 2, Rate = 36, LowRate = 8, StormInterval = 7},
	Elements = {
		Fire = {Rock = Color3.fromRGB(54, 43, 41), Surface = Color3.fromRGB(80, 55, 47), Accent = Color3.fromRGB(255, 102, 25), Mist = Color3.fromRGB(164, 101, 76), Tint = Color3.fromRGB(255, 228, 202), Material = Enum.Material.Basalt, Height = 18, Density = 0.32, Particle = "rbxasset://textures/particles/fire_main.dds"},
		Ice = {Rock = Color3.fromRGB(92, 139, 164), Surface = Color3.fromRGB(213, 235, 240), Accent = Color3.fromRGB(135, 231, 255), Mist = Color3.fromRGB(182, 213, 234), Tint = Color3.fromRGB(219, 240, 255), Material = Enum.Material.Glacier, Height = 24, Density = 0.36, Particle = "rbxasset://textures/particles/sparkles_main.dds"},
		Lightning = {Rock = Color3.fromRGB(58, 62, 80), Surface = Color3.fromRGB(89, 95, 115), Accent = Color3.fromRGB(181, 199, 255), Mist = Color3.fromRGB(100, 116, 150), Tint = Color3.fromRGB(222, 227, 255), Material = Enum.Material.Slate, Height = 30, Density = 0.38, Particle = "rbxasset://textures/particles/sparkles_main.dds"},
		Earth = {Rock = Color3.fromRGB(100, 86, 65), Surface = Color3.fromRGB(92, 136, 64), Accent = Color3.fromRGB(174, 228, 117), Mist = Color3.fromRGB(167, 192, 151), Tint = Color3.fromRGB(242, 255, 225), Material = Enum.Material.Rock, Height = 16, Density = 0.28, Particle = "rbxasset://textures/particles/smoke_main.dds"},
	},
}
