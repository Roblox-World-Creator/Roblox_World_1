# Balance

All values below are configurable in `ReplicatedStorage/Shared`.

## Progression

```text
XP required = floor(100 * Level ^ 1.45)
Max HP = (100 + 10 * (Level - 1)) * evolution health multiplier
Attack = (25 + 3 * (Level - 1)) * evolution attack multiplier
```

## Resources and actions

- Base WalkSpeed: 36 (Roblox default 16 plus the requested 20).
- MP: 100 base, regenerates 4 per second.
- Stamina: 100 base, regenerates 24 per second after 0.8 seconds without use.
- Melee: 0.45 second server cooldown and 11-stud query range.
- Energy Bolt: 50 base damage, 10 MP, 2 second cooldown, 80-stud cast range, 4-stud impact radius, and 115-stud/second projectile speed.
- Energy Burst: 70 base damage, 25 MP, 6 second cooldown, 14-stud radius, and 45 base knockback strength.
- Power Dash: 22 studs, 25 stamina, 1.25 second cooldown; obstacle clearance stops it three studs before a hit.
- Dodge: 14 studs, 20 stamina, 1 second cooldown, and 0.32 seconds of server-authoritative invulnerability.

## Sword and defense

- Combo recovery: 0.34 / 0.34 / 0.40 / 0.72 seconds.
- Combo damage multipliers: 1.00 / 1.05 / 1.15 / 1.60.
- Finisher knockback: 42 before enemy resistance.
- Normal block: 65% damage reduction and 12 stamina per absorbed strike.
- Perfect-block window: 0.18 seconds, with a 0.5-second rearm requirement.
- Perfect-block enemy stun: 0.8 seconds before enemy resistance.
- Ordinary melee stuns apply temporary stun immunity; finishers can override the current immunity once.

Wave health/damage/speed growth and multiplayer health scaling are defined in `GameConfig.lua`.

## Enemy engagement

- Automatic player acquisition: 48 studs.
- Engaged target leash: 90 studs.
- Attack range: 6.5 studs.
- Attack windup: 0.4 seconds.
- Attack cooldown: 1.35 seconds.
- Path recalculation interval: 0.9 seconds or immediately after a meaningful goal-position change.
- Global path budget: 12 requests per second and 3 concurrent computations.
- Stuck recovery: less than 2 studs of progress over 2.5 seconds while advancing/chasing.

## Waves, elites, and bosses

- Wave completion XP: `25 + 12 × wave`.
- Wave completion gold: `15 + 6 × wave`.
- Elites begin at wave 3 with an 8% base chance, growing by 1.5 percentage points per wave to a 32% cap.
- Giant: 1.8× health, 1.3× damage, 1.28× visual scale, and 2× rewards.
- Haste: 1.15× health, 1.42× speed, and 1.75× rewards.
- Fortified: 1.55× health, 28% incoming-damage reduction, and 2.25× rewards.
- Boss phases begin at 65% and 30% health.
- Boss arena slam: 22-stud radius and 0.9-second dodge telegraph.
- Boss reward eligibility: at least 3% of maximum health contributed as server-recorded damage.

## Admin testing caps

- Speed presets: 36, 60, and 90 WalkSpeed, with a hard server cap of 100.
- Damage boost: 2x for 60 seconds, with a hard server multiplier cap of 3x.
- Item grant: 1-25 per action and never above the item stack maximum.
- Spawn actions: one allowlisted practice enemy per second.
- Failed unlocks: five attempts in 30 seconds trigger a 60-second lockout.

## Items and economy

- Inventory capacity: 40 distinct stacks; consumables/materials stack to their catalog maximum.
- Selling returns 35% of the catalog purchase price; locked or equipped items cannot be sold.
- Health Core: 45 HP with an 8-second cooldown. Mana Crystal: 40 MP with an 8-second cooldown.
- Battle Serum: 1.25x damage for 60 seconds. Stone Skin Tonic: +25 defense for 60 seconds. Energy Surge: +8 MP regeneration per second for 45 seconds.
- Defense mitigation uses `incoming damage × 100 / (100 + defense)`.
- Base critical chance/damage: 5% / 1.5x, augmented by equipment.
- Boss participants receive one guaranteed Boss Core; chase equipment remains weighted and non-guaranteed.

## Powers and mastery

- Energy Beam: level 8/evolution 1, 115 base damage, 30 MP, 8-second cooldown, 105-stud piercing line.
- Gravity Pulse: level 15/evolution 1, 85 base damage, 35 MP, 10-second cooldown, 20-stud pull radius.
- Chain Lightning: level 25/evolution 2, 100 opening damage, 45 MP, 12-second cooldown, up to six targets with 12% damage decay per jump.
- Mastery has ten ranks. Each rank adds 4% power damage and reduces MP cost by 1.5%.

## Quest campaign and bosses

- Campaign goals: 15 kills, 3 elite kills, 3 waves, 1 credited boss defeat, and 12 collected materials.
- Boss credit still requires at least 3% of maximum boss health contributed.
- Boss archetypes rotate every ten waves: Stone, Rift, Storm, then repeat.
- Rift vortex: 28-stud radius and 1.15-second telegraph. Storm marks: 8-stud radius and 0.85-second telegraph.
