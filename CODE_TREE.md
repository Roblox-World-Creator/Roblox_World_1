# Evolution Ascendant code tree

This is the practical source graph for the Rojo build. Start at `World.server.lua`; it creates remotes and starts every server-owned system in dependency order.

```text
src/
├─ ServerScriptService/
│  ├─ World.server.lua                 bootstrap + dependency wiring
│  └─ Systems/
│     ├─ PlayerProgression.lua         level, XP, damage, speed, jump scaling
│     ├─ CombatService.lua             melee combos, aim validation, powers, rewards
│     ├─ DamageService.lua             server-authoritative damage and critical hits
│     ├─ MovementService.lua           dash, dodge, wolf, bear climb, eagle flight
│     ├─ TransformationService.lua     forms, form visuals, form skill ownership
│     ├─ WaveDefense.lua               boards, realms, mobs, bosses, hazards, safe zones
│     ├─ EnemyAI.lua                   aggro, attacks, passive mobs, sanctuary exclusion
│     ├─ MobAnimationService.lua       walk/bob/attack motion and dragon wing flaps
│     ├─ BossPhaseController.lua       boss phases and special attacks
│     ├─ InventoryService.lua          bag, equipment, physical drops, selling, stats
│     ├─ QuestService.lua              quest state, filters, progress, rewards
│     ├─ SkillTreeService.lua          universal, melee, and element unlock trees
│     ├─ ImportedAssetService.lua      quarantine and sanitize Studio Toolbox piles
│     └─ AssetModelService.lua         clone/weld approved runtime visuals and props
├─ ReplicatedStorage/Shared/
│  ├─ ProgressionConfig.lua            combat numbers, abilities, level movement scaling
│  ├─ EnemyConfig.lua                  mob/boss stats, models, attacks, dragon orientation
│  ├─ RealmConfig.lua                  board positions, size, mobs, props, safe radius
│  ├─ QuestConfig.lua                  global quests + 10 generated quests per realm
│  ├─ SkillTreeConfig.lua              10-tier universal/melee/element trees
│  ├─ TransformationConfig.lua         form requirements, stats, and form skills
│  ├─ ItemConfig.lua                   items, rarity, stats, recipes, and loot tables
│  └─ SaveConfig.lua                   persistent schema
└─ StarterPlayer/StarterPlayerScripts/
   ├─ CombatController.client.lua      input, cursor aim assist, combat HUD
   ├─ EffectsController.client.lua     spells, melee styles, damage numbers, impacts
   ├─ AscensionController.client.lua   skill/melee trees and animal forms
   ├─ InventoryController.client.lua   inventory/equipment/store/quick-sell menu
   ├─ QuestController.client.lua       global and realm-filtered quest boards
   └─ PowersController.client.lua      power library, slots, requirements, instructions
```

## Main runtime flows

```text
player input → client controller → RemoteEvent/RemoteFunction
             → server system validates request
             → damage/progression/inventory/quest state changes
             → client effects and menu state refresh

Studio Toolbox pile → ImportedAssetService archives and sanitizes it
                    → ReplicatedStorage.GameAssets
                    → AssetModelService clones approved visuals
                    → WaveDefense distributes scenery and attaches mob visuals
```

Server systems own gameplay truth. Client controllers only request actions and render feedback; never move damage, rewards, requirements, or inventory authority into a client script.
