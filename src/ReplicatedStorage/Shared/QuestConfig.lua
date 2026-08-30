local RealmConfig = require(script.Parent.RealmConfig)

local config = {
	IntroCull = {DisplayName = "Rift Cull", Description = "Defeat 15 Rift enemies.", Event = "Kill", Goal = 15, RewardXP = 300, RewardGold = 180, RewardItem = "HealthPotion", RewardQuantity = 3},
	EliteTrial = {DisplayName = "Elite Trial", Description = "Defeat 3 elite enemies.", Event = "EliteKill", Goal = 3, RewardXP = 700, RewardGold = 450, RewardItem = "RiftCrystal", RewardQuantity = 2},
	WaveGuard = {DisplayName = "Hold the Fort", Description = "Complete 3 defense waves.", Event = "Wave", Goal = 3, RewardXP = 900, RewardGold = 600, RewardItem = "BattleSerum", RewardQuantity = 2},
	BossHunter = {DisplayName = "Break the Colossus", Description = "Earn participation credit on a boss defeat.", Event = "Boss", Goal = 1, RewardXP = 1800, RewardGold = 1200, RewardItem = "BossCore", RewardQuantity = 1},
	Collector = {DisplayName = "Evolution Research", Description = "Collect 12 crafting materials.", Event = "Material", Goal = 12, RewardXP = 1000, RewardGold = 750, RewardItem = "EvolutionShard", RewardQuantity = 6},
}

local typeNames = {"Realm Sweep", "Wanted Monster", "Elite Breaker", "Treasure Hunt", "Shard Search", "Critical Carnival", "Blade Dancer", "Power Showcase", "Realm Champion", "Grand Expedition"}
for realmIndex, realmId in ipairs(RealmConfig.Order) do
	local realm = RealmConfig.Realms[realmId]
	local enemyType = realm.Mobs[(realmIndex * 2 - 1) % #realm.Mobs + 1]
	local rewardItem = realmIndex >= 3 and "RiftCrystal" or "EvolutionShard"
	local definitions = {
		{Event = "RealmKill", Goal = 8 + realmIndex * 2, Description = "Defeat enemies anywhere in this realm."},
		{Event = "EnemyKill", Goal = 5 + realmIndex, EnemyType = enemyType, Description = "Hunt the realm's featured monster type."},
		{Event = "EliteKill", Goal = 2 + math.floor(realmIndex / 2), Description = "Bring down elite monsters."},
		{Event = "Collect", Goal = 4 + realmIndex, Description = "Pick up dropped equipment or supplies."},
		{Event = "Material", Goal = 6 + realmIndex * 2, Description = "Recover crafting materials from the wilds."},
		{Event = "CriticalHit", Goal = 10 + realmIndex * 3, Description = "Land bright, cartoony critical hits."},
		{Event = "MeleeKill", Goal = 5 + realmIndex, Description = "Finish monsters with melee combo attacks."},
		{Event = "PowerKill", Goal = 5 + realmIndex, Description = "Finish monsters with powers or spells."},
		{Event = "Boss", Goal = 1, Description = "Help defeat a realm or wave boss."},
		{Event = "RealmKill", Goal = 22 + realmIndex * 4, Description = "Complete a grand monster-clearing expedition."},
	}
	for slot, generated in ipairs(definitions) do
		local id = realmId .. string.format("_%02d", slot)
		generated.DisplayName = realm.DisplayName .. ": " .. typeNames[slot]
		generated.RealmId = realmId
		generated.RewardXP = 220 * realmIndex + generated.Goal * 28
		generated.RewardGold = 120 * realmIndex + generated.Goal * 18
		generated.RewardItem = slot == 9 and "BossCore" or rewardItem
		generated.RewardQuantity = slot == 9 and 1 or math.max(1, math.floor(realmIndex / 2) + 1)
		config[id] = generated
	end
end

return config
