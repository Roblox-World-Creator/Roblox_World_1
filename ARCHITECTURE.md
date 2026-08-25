# Architecture

The server is authoritative for damage, rewards, resources, cooldowns, movement validation, evolution, and saved progression. The client sends intent and renders HUD/input feedback.

## Startup

`World.server.lua` type-checks and self-heals every required RemoteEvent/RemoteFunction before starting services behind protected calls. This makes live sync resilient when a Studio place is missing newly declared instances. A failed optional service is logged in `Workspace.WorldError` without preventing unrelated systems from starting; startup code must not wait indefinitely for an undeclared dependency.

## Service relationships

```text
CombatController -> CombatRemote / AbilityRemote / DashRemote
                         |
                         v
CombatService -> DamageService -> PlayerProgression -> SaveService
MovementService --------^                 |
WaveDefense -> enemy models               v
                              replicated player attributes -> HUD

CombatService -> AbilityEffects -> EffectsController (cosmetic only)
WaveDefense -> EnemyAI -> PathfindingService / player combat / core fallback
WaveDefense -> BossPhaseController -> phase attributes / arena mechanics / BossUI
EnemyAI -> PathfindingBudget -> bounded PathfindingService requests
AdminController -> AdminService -> WaveDefense / InventoryService / player attributes
InventoryController -> InventoryRemote / StoreRemote -> InventoryService / StoreService -> SaveService
CombatService -> MasteryService / QuestService -> replicated progression folders -> Combat HUD / QuestController
```

Configuration is held in `ReplicatedStorage.Shared`. Runtime modules do not own balance constants. Ability VFX are rendered locally from validated server effect messages. Server hit validation never depends on those cosmetic instances.

Combat actions are stateful on the server. `CombatService` owns melee combo order, recovery timing, enemy stun immunity, blocking state, and perfect-block rearm timing. `MovementService` owns dodge displacement, stamina, cooldown, and invulnerability. `EnemyAI` checks those replicated server attributes when resolving a telegraphed attack.

Each enemy has exactly one movement owner: `EnemyAI`. It prioritizes an engaged or nearby living player, uses timed/telegraphed attacks, drops invalid targets outside its leash, and otherwise advances toward the defense core. This prevents competing `MoveTo` calls from combat and wave scripts.

`PathfindingBudget` limits global request rate and concurrency; individual enemies also detect stalls and request recovery paths. `WaveDefense` counts only active wave enemies, leaving practice targets independent. Boss rewards read server-recorded damage contributions and are never decided by the client.

`AdminService` keeps authorization in server memory, rate-limits calls, validates player targets, and applies hard caps. `InventoryService` accepts only IDs defined by `ItemConfig`; admin-spawned enemies are practice entities and never count toward wave completion.

`ItemConfig` is the catalog and balance source for item definitions, rarities, stats, consumables, recipes, prices, and weighted loot. `InventoryService` owns stacks, equipment, crafting, buffs, drops, and computed equipment attributes. `StoreService` exposes only server-priced catalog actions. `SaveService` serializes additive inventory, equipment, mastery, quest, and settings data in schema v3 while accepting older players with defaults for missing sections.

`MasteryService` owns per-power XP/rank derivation. `QuestService` consumes trusted server events from combat, waves, bosses, and inventory grants, then owns reward claims. `SettingsService` is the validation bridge for client preferences. Save schema v3 serializes all three while remaining additive for older profiles.

## Compatibility

`EnergyBolt` and `EnergyBurst` are the Phase 2 starter abilities. The prototype `Energy` attributes mirror `MP` during migration.
