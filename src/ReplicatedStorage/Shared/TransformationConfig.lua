local function skills(prefix, names)
	local result = {}
	for index, name in ipairs(names) do
		table.insert(result, {
			Id = prefix .. string.format("%02d", index), DisplayName = name,
			RequiredLevel = math.max(1, index * 10 - 5), Cost = index >= 8 and 2 or 1,
			Description = index == 3 and "Unlocks the form's travel technique."
				or index == 10 and "Ultimate form attack; massively empowers combat."
				or "Improves this form's attacks and passive bonuses.",
		})
	end
	return result
end

return {
	Order = {"Wolf", "Bear", "Eagle"},
	DropChance = 0.35,
	Forms = {
		Wolf = {
			DisplayName = "Wolf Form", RequiredLevel = 5, Color = Color3.fromRGB(125, 190, 255),
			StatModifiers = {MoveSpeed = 1.25, CriticalChance = 0.08, Defense = 0},
			Abilities = {"Rending Claw", "Moon Pounce", "Alpha Howl"},
			Skills = skills("Wolf", {"Keen Scent", "Rending Claw", "Moon Pounce", "Pack Rush", "Bleeding Fang", "Lunar Howl", "Phantom Hunt", "Dire Frenzy", "Alpha Dominion", "Moon Devourer"}),
		},
		Bear = {
			DisplayName = "Bear Form", RequiredLevel = 10, Color = Color3.fromRGB(190, 125, 70),
			StatModifiers = {MoveSpeed = 0.9, Health = 1.45, Defense = 18},
			Abilities = {"Titan Claw", "Boulder Charge", "World Roar"},
			Skills = skills("Bear", {"Thick Hide", "Titan Claw", "Boulder Charge", "Iron Guard", "Seismic Paw", "World Roar", "Mountain Blood", "Unbroken Rage", "Colossus Heart", "World Mauler"}),
		},
		Eagle = {
			DisplayName = "Eagle Form", RequiredLevel = 15, Color = Color3.fromRGB(205, 165, 70),
			StatModifiers = {MoveSpeed = 1.35, CriticalChance = 0.12, Defense = -5},
			Abilities = {"Gale Talon", "Sky Flight [G]", "Thunder Dive"},
			Skills = skills("Eagle", {"Far Sight", "Gale Talon", "Sky Flight", "Wing Burst", "Razor Feather", "Thunder Dive", "Jetstream", "Storm Hunt", "Sky Sovereign", "Heavenfall"}),
		},
	},
}
