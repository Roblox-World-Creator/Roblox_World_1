# Evolution Ascendant: Current Game Architecture

Audit date: 2026-08-26. This document describes the repository before the elemental-expansion refactor and is the baseline for compatibility decisions.

## Runtime topology

The project is Rojo-managed. `World.server.lua` creates/repairs remotes, starts each service behind `pcall`, and exposes startup health through Workspace attributes. Server code is authoritative for damage, cooldowns, movement displacement, progression, rewards, inventory, equipment, quests, waves, and admin actions. Clients send intent and render UI/VFX.

```text
ReplicatedStorage/Shared          balance and content configuration
ServerScriptService/Systems      server-authoritative services and enemy runtime
StarterPlayerScripts             input, HUD/menu controllers, and cosmetic VFX
default.project.json             DataModel, arena, spawn, and remote mapping
```

## Existing gameplay systems

| Area | Current implementation | Authority / data flow |
|---|---|---|
| Powers | Six attacks (`EnergyBolt`, `EnergyBurst`, `EnergyBeam`, `GravityPulse`, `ChainLightning`, `Tornado`) plus `PowerDash` and `Dodge`; RT ranged/LT local forms; mastery 0-10 | `ProgressionConfig`, `PowerService`, `CombatService`, `MasteryService`, `CombatController`, `EffectsController` |
| Combat | Four-hit melee combo, ranged secondary weapons, block/perfect block, critical hits, damage contribution, knockback/pull/stun | Client intent -> `CombatService` -> `DamageService`; effect messages are cosmetic |
| Movement | Server-validated dash/dodge, stamina cost, raycast obstruction, dodge invulnerability | `MovementService` |
| Progression | Levels, XP, gold, three evolution tiers, MP/stamina, equipment-derived stats | `PlayerProgression`, `EvolutionService`, replicated player attributes |
| Inventory | Forty-stack bag, equipment slots, favorites/locks, consumables, crafting, buy/sell, procedural equipped visuals | `ItemConfig`, `InventoryService`, `StoreService`, `WeaponService` |
| Loot/pickups | Weighted item rolls; boss participation loot; local rarity beams; fixed health/energy/item pickups | `InventoryService`, `WaveDefense`, `InventoryController` |
| Enemies | Basic/Fast/Tank/Boss definitions, one AI owner per enemy, aggro/leash/core fallback, attack telegraphs | `EnemyConfig`, `EnemyAI`, `PathfindingBudget` |
| Waves | Fifty-wave loop, health/damage/speed scaling, elites, rotating bosses, participation rewards | `WaveDefense`, `WaveConfig`, `BossPhaseController` |
| World | One procedural fort arena, eight enemy spawns/waypoints, four existing edge warp pads | `WaveDefense.createArena`; current pads only return players to fort locations |
| UI | Combat HUD/bars/hotbar, inventory/store/crafting, powers/loadout, quests, evolution, settings, boss HUD, admin | Client controllers under `StarterPlayerScripts` |
| Persistence | Additive schema v3; level/XP/gold/evolution, inventory/equipment, mastery, quests, settings | `SaveService`; Studio memory by default, DataStore in published servers |
| Admin/debug | Locked server admin plus Studio-authorized chat commands | `AdminService`, `DebugService` |

## Existing content and assets

- The arena, fort, enemies, weapons, armor overlays, pickups, projectiles, and most VFX are procedural Parts/Attachments/Trails/Beams. They have no external Creator Store dependency.
- `assets/evolution-ascendant-item-atlas-v1.png` is a local source atlas, not a runtime Roblox asset ID.
- There are no repository-owned animation or sound asset IDs and no imported model scripts to audit.
- Stable saved item IDs already differ from display names. Visual weapon construction currently reads `WeaponColor`/`WeaponSize`; it can be wrapped by a model-profile registry without migrating saved item IDs.

## Remotes

Events: `CombatRemote`, `AbilityRemote`, `AbilityEffects`, `CombatFeedback`, `EvolutionRemote`, `DashRemote`, `DodgeRemote`, `InventoryEvent`, `QuestEvent`, `SettingsRemote`.

Functions: `AdminRemote`, `InventoryRemote`, `StoreRemote`, `QuestRemote`, `PowerRemote`.

All gameplay-changing remote handlers validate on the server. Cosmetic effect payloads are produced by the server and rendered locally.

## Performance characteristics

- Path requests are globally budgeted and concurrency-limited.
- Each enemy owns one AI task; there is no per-enemy Heartbeat connection.
- Temporary client effects use `Debris`, but there is no shared effect pool yet.
- Ability target searches currently scan the enemy folder; Chain Lightning performs repeated full living-enemy scans and is a priority for spatial-query refactoring.
- Gravity/pull uses impulses and resistance attributes. Bosses already have high knockback/stun resistance.

## Compatibility constraints

1. Preserve all eight current powers and saved IDs.
2. Extend save data additively; never rename or remove v3 fields.
3. Keep `DamageService` as the only direct enemy-health mutation entry point.
4. Keep VFX cosmetic and client-rendered.
5. Reuse the procedural fort, enemy rigs, wave loop, four warp instances, inventory UI, and configuration-driven catalog.
6. Introduce model profiles as optional presentation references; gameplay must continue with procedural fallbacks.

## Identified gaps

There is no element/resistance registry, reusable status-effect service, general crowd-control service, player skill tree, transformation framework, world-realm service, model asset registry, weapon XP, random item modifiers, Mythic rarity, or true world destinations. Ability execution is data-backed but still branches inside `CombatService`; the hotbar also contains a fixed list. These are extension points, not reasons to replace working systems.
