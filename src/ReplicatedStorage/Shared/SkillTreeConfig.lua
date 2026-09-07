local config = {
	PointsPerLevel = 2,
	ElementPointsEveryLevels = 1,
	Trees = {"Universal", "Melee", "Fire", "Ice", "Lightning", "Earth", "Gravity", "Poison", "Prismatic"},
	Order = {},
	Nodes = {},
}

local prefixes = {Universal = "Ascendant", Melee = "Warrior", Fire = "Inferno", Ice = "Absolute", Lightning = "Tempest", Earth = "Tectonic", Gravity = "Singularity", Poison = "Venom", Prismatic = "Spectrum"}
local names = {"Initiation", "Focus", "Reach", "Ward", "Surge", "Mastery", "Dominion", "Overdrive", "Apotheosis", "Cataclysm"}
local universalAttributes = {"SkillDamageMultiplier", "SkillHealthMultiplier", "SkillAreaMultiplier", "AllResistance", "SkillCriticalChance", "SkillCooldownReduction", "SkillEnergyRegen", "FormPointFind", "SkillExecuteBonus", "AscendantCoreUnlocked"}
local meleeAttributes = {"MeleeDamageMultiplier", "MeleeComboWindowBonus", "MeleeRangeBonus", "MeleeDefenseBonus", "MeleeStunBonus", "MeleeCooldownReduction", "MeleeFinisherMultiplier", "MeleeDashUnlocked", "MeleeShockwaveUnlocked", "MeleeLegendUnlocked"}

for _, tree in ipairs(config.Trees) do
	local previous
	for tier = 1, 10 do
		local id = tree .. string.format("%02d", tier)
		local isUniversal = tree == "Universal"
		local isMelee = tree == "Melee"
		local attribute
		if isUniversal then attribute = universalAttributes[tier]
		elseif isMelee then attribute = meleeAttributes[tier]
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
			PerRank = isMelee and (tier == 1 and 0.06 or tier == 2 and 0.08 or tier == 3 and 0.7 or tier == 5 and 0.08 or tier == 6 and 0.035 or tier == 7 and 0.12 or 1)
				or tier == 1 and 0.06 or tier == 7 and isUniversal and 0.75 or tier == 10 and 1 or 0.04,
			Base = isMelee and (tier == 1 and 1 or tier == 7 and 1 or 0) or ((tier == 1 or (isUniversal and (tier == 2 or tier == 3))) and 1 or 0), RequiredLevel = math.max(1, (tier - 1) * 10),
			Prerequisites = previous and {{Id = previous, Rank = tier == 10 and 3 or 1}} or nil,
			Description = isMelee and ({"Stronger basic strikes.", "Longer combo timing window.", "Wider melee reach.", "Armor while attacking.", "Heavier stuns.", "Faster combo recovery.", "Devastating fourth-hit finishers.", "Unlock a forward strike dash.", "Finishers release a damaging shockwave.", "Capstone: legendary prismatic melee style."})[tier]
				or isUniversal and ({"+6% damage per rank.", "+4% maximum health per rank.", "+4% spell area per rank.", "+4% resistance per rank.", "+4% critical chance per rank.", "4% shorter spell cooldowns per rank.", "+0.75 energy regeneration per rank.", "+4% form-point drop chance per rank.", "+4% damage against enemies below 25% health per rank.", "Capstone: +5% elemental damage."})[tier]
				or ({"+6% elemental damage per rank.", "Strengthens this element's status effect by 4% per rank.", "+4% elemental spell area per rank.", "+4% resistance to this element per rank.", "+2% elemental strike damage per rank.", "4% shorter elemental cooldowns per rank.", "+4% elemental damage penetration per rank.", tree == "Fire" and "Burns deal +4% hit damage per tick per rank." or tree == "Poison" and "Poison deals +4% hit damage per tick per rank." or "Hits leave three residual damage ticks: 4% of hit damage per rank, every 0.6s.", "+4% damage against enemies below 25% health per rank.", "Capstone: +15% elemental damage."})[tier],
		}
		table.insert(config.Order, id)
		previous = id
	end
end

return config
