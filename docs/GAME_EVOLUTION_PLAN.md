# Evolution Ascendant: Evolution Plan

This is the implementation ledger for the master expansion. Status terms are deliberately explicit.

## EXISTING

- Playable fifty-wave defense loop, four edge warp pads, procedural arena/fort, four enemy archetypes, elites, three rotating multi-phase bosses.
- Six attack powers plus dash/dodge, mastery levels, ranged/local forms, melee/block, server damage validation, MP/stamina.
- Persistent levels, XP, gold, evolution tiers, inventory/equipment, crafting/store, loot, quests, visual settings, admin/debug tools.
- Procedural, replaceable-in-practice weapon and armor presentation; no untrusted Creator Store scripts.

## REUSED

- `DamageService` remains the health mutation boundary.
- `CombatService` remains the validated request boundary while ability execution is extracted incrementally.
- Existing configs retain stable save IDs. New configs reference those IDs instead of visual instance names.
- `WaveDefense`, `EnemyAI`, `PathfindingBudget`, `EffectsController`, `InventoryService`, `SaveService`, and all current UI remain active.
- Existing warp Parts are upgraded in place rather than deleted.

## REFACTORED

- Ability definitions gain element, effect/model profile, evolution, status, and crowd-control metadata.
- Enemy targeting moves toward tagged/spatial queries with folder-scan fallback.
- Equipment presentation resolves optional model profiles through an asset registry and preserves procedural fallback models.
- Save schema is extended additively with migration-safe defaults.

## NEW

Stage-one foundation:

- Element, asset, skill-tree, loot, transformation, and elemental-world configuration registries.
- Reusable status and crowd-control services.
- Skill-point earning/purchasing and persistent skill ranks.
- Configurable transformation profiles with Wolf/Bear/Eagle first.
- Elemental realm metadata bound to the four existing portals.
- First playable Fire/Ice/Lightning/Earth/Gravity ability set and reusable elemental VFX profiles.

## DEPRECATED

- Direct reliance on visual model names as gameplay identifiers (none are saved today; future integrations must use registry IDs).
- New ability code added as one-off scripts.
- Repeated full-folder nearest-target scans where a spatial query is available.
- Fixed-only `HIGH`/`LOW` quality semantics; configuration will support Low/Medium/High/Ultra while accepting old values.

## PLANNED

1. Audit/stabilize and registries.
2. Status/crowd-control/spatial target foundation.
3. Elements and first fifteen playable abilities.
4. Mechanical mastery evolutions and branch choice persistence.
5. Universal/element skill tree and HUD integration.
6. Weapon metadata, first eight themed weapons, weapon XP/evolution.
7. Typed loot/pickup presentation, Mythic rarity, safe modifiers.
8. Wolf/Bear/Eagle playable transformation loop, then Tiger/Rhino/Dragon.
9. Four realm destinations using existing portals; elemental enemies, drops, and bosses.
10. Stress/performance passes, balance, audio/VFX polish, Creator Store integrations only after per-asset security audit.

## Checkpoint 1 acceptance target

- Existing gameplay builds unchanged.
- Stable asset/model IDs exist with procedural fallbacks.
- Elements, skills, statuses, CC, transformations, loot, and worlds have central definitions.
- Saves load old schema data and supply defaults for every new field.
- At least one showcase each for segmented Chain Lightning, Ground Slam, and Black Hole is playable before moving to content breadth.

## Checkpoint 1 result — IMPLEMENTED

- Central registries: assets/model profiles, elements/interactions, skills, loot/pickup profiles, transformations, and realms.
- Save schema v4 migration: legacy players retain all v3 data and receive level-derived skill currencies; skills/forms and future world/weapon metadata persist additively.
- Reusable crowd control plus spatial radius targeting; Chain Lightning uses spatial candidates and scales from 6 to 20 targets through mastery.
- First fifteen elemental abilities are selectable in the existing six-slot loadout; RT/LT behavior and all original powers remain.
- Segmented Chain Lightning, seismic Ground Slam, sustained Black Hole, elemental projectile colors, typed damage numbers, mastery-driven area growth, and skill-driven damage/cooldown/area/crit/health/regen.
- Config-driven first weapon set, Mythic rarity, required-level store/equip validation, and stable model/evolution/passive/ability IDs.
- Wolf/Bear/Eagle form selection with level unlocks, stat identities, aura fallback presentation, persistence, and swappable model profiles.
- Four existing pads upgraded in place to Fire/Ice/Storm/Earth demo realms with metadata and return portals.
- Ascendant Dev Console expanded for skills, forms, realm teleporting, cooldown resets, and bounded stress tests.

## Checkpoint 1 known limitations

- Realm enemies and bosses still use the central wave arena; realm-specific wave routing is the next content stage.
- Animal forms currently use safe avatar aura/stat fallbacks; custom animal rigs and unique form attack execution are next.
- Fire burn is marked but does not yet run a rewarded server DoT loop; Ice slow, Lightning stun, Earth stagger, and Gravity compression are active.
- Procedural weapon fallbacks are active; no Creator Store asset has been imported without an explicit asset audit.

## Asset policy

No Creator Store asset is accepted without a recorded creator/ID/URL and inspection of every Script, LocalScript, ModuleScript, RemoteEvent, and RemoteFunction. Imported gameplay/damage scripts are not trusted; safe VFX/animation helpers may be adapted. See `ASSET_CREDITS.md`.
