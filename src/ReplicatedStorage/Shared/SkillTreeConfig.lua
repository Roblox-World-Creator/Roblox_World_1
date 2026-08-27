local config = {
	PointsPerLevel = 2,
	ElementPointsEveryLevels = 1,
	Trees = {"Universal", "Fire", "Ice", "Lightning", "Earth", "Gravity", "Poison", "Prismatic"},
	Order = {},
	Nodes = {},
}

local prefixes = {Universal = "Ascendant", Fire = "Inferno", Ice = "Absolute", Lightning = "Tempest", Earth = "Tectonic", Gravity = "Singularity", Poison = "Venom", Prismatic = "Spectrum"}
local names = {"Initiation", "Focus", "Reach", "Ward", "Surge", "Mastery", "Dominion", "Overdrive", "Apotheosis", "Cataclysm"}
local universalAttributes = {"SkillDamageMultiplier", "SkillHealthMultiplier", "SkillAreaMultiplier", "AllResistance", "SkillCriticalChance", "SkillCooldownReduction", "SkillEnergyRegen", "FormPointFind", "SkillExecuteBonus", "AscendantCoreUnlocked"}

for _, tree in ipairs(config.Trees) do
	local previous
	for tier = 1, 10 do
		local id = tree .. string.format("%02d", tier)
		local isUniversal = tree == "Universal"
		local attribute
		if isUniversal then attribute = universalAttributes[tier]
		elseif tier == 1 then attribute = tree .. "DamageMultiplier"
		elseif tier == 2 then attribute = tree .. "StatusBonus"
		elseif tier == 3 then attribute = tree .. "AreaBonus"
		elseif tier == 4 then attribute = "Skill" .. tree .. "Resistance"
		elseif tier == 5 then attribute = tree .. "CriticalBonus"
		elseif tier == 6 then attribute = tree .. "CooldownBonus"
		elseif tier == 7 then attribute = tree .. "Penetration"
		elseif tier == 8 then attribute = tree .. "DotBonus"
		elseif tier == 9 then attribute = tree .. "ExecuteBonus"
		else attribute = tree .. "UltimateUnlocked" end
		config.Nodes[id] = {
			Tree = tree, DisplayName = prefixes[tree] .. " " .. names[tier], Tier = tier,
			Column = (tier - 1) % 3 + 1, MaximumRank = tier == 10 and 1 or 5,
			Cost = tier >= 8 and 2 or 1, Attribute = attribute,
			PerRank = tier == 1 and 0.06 or tier == 7 and isUniversal and 0.75 or tier == 10 and 1 or 0.04,
			Base = (tier == 1 or (isUniversal and (tier == 2 or tier == 3))) and 1 or 0, RequiredLevel = math.max(1, (tier - 1) * 10),
			Prerequisites = previous and {{Id = previous, Rank = tier == 10 and 3 or 1}} or nil,
			Description = tier == 10 and "Capstone: unlock this tree's ultimate combat effect."
				or string.format("Ranked %s bonus. Requires level %d.", string.lower(names[tier]), math.max(1, (tier - 1) * 10)),
		}
		table.insert(config.Order, id)
		previous = id
	end
end

return config
