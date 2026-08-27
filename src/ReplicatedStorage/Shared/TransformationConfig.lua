return {
	Order = {"Wolf", "Bear", "Eagle"},
	Forms = {
		Wolf = {DisplayName = "Wolf Form", ModelProfile = "WolfModel01", RequiredLevel = 5, Color = Color3.fromRGB(125, 190, 255), StatModifiers = {MoveSpeed = 1.25, CriticalChance = 0.08, Defense = 0}, Abilities = {"WolfClaw", "WolfPounce", "WolfHowl"}, Evolutions = {{Level = 5, Name = "Dire Wolf"}, {Level = 10, Name = "Alpha Wolf"}}},
		Bear = {DisplayName = "Bear Form", ModelProfile = "BearModel01", RequiredLevel = 10, Color = Color3.fromRGB(190, 125, 70), StatModifiers = {MoveSpeed = 0.9, Health = 1.45, Defense = 18}, Abilities = {"BearClaw", "GroundPound", "BearRoar"}, Evolutions = {{Level = 5, Name = "Dire Bear"}, {Level = 10, Name = "Titan Bear"}}},
		Eagle = {DisplayName = "Eagle Form", ModelProfile = "EagleModel01", RequiredLevel = 15, Color = Color3.fromRGB(255, 225, 125), StatModifiers = {MoveSpeed = 1.35, CriticalChance = 0.12, Defense = -5}, Abilities = {"WingSlash", "DiveBomb", "WindBurst"}, Evolutions = {{Level = 5, Name = "Sky Hunter"}, {Level = 10, Name = "Storm Eagle"}}},
	},
}
