# Elemental worlds, combat, inventory, and controller review

Implemented September 7, 2026. Roblox Studio and physical-controller acceptance testing remain pending.

## Worlds and effects

- Six raised outposts per realm have opposing ramps, accessible surfaces, and relocated district markers. Realm enemies spawn on walkable scenery rather than inside it.
- Fire: basalt skyline, calderas, lava cascades, ember weather. Ice: glacier crowns, frozen tarns, glacial veins, snow and frost. Storm: ruined arches, suspended stones, atmospheric arcs. Earth: ancient cedar groves, springs, waterfalls, pollen.
- Local atmosphere transitions restore the hub's atmosphere. Tagged ambient sources support streaming and cleanup. LOW effect quality reduces particles and disables bloom.
- Spell visuals add expanding beam outlines, particle bursts, trails and stronger elemental silhouettes. Hostile filled telegraphs retain their danger footprints. Distance and instance budgets limit new cosmetic work.

## Sword arts and progression

The MELEE menu (M) exposes all melee upgrades and the new sword arts. The existing four-hit combo now uses a shared R6/R15 posing module applied after Roblox's Animator update. Common and imported swords also receive trails, visible only during strikes.

| Move | Keyboard | Unlock | Base stamina / cooldown |
| --- | --- | --- | --- |
| Flash Thrust | Z | Level 5 + Melee01 rank 1 | 18 / 4s |
| Skybreaker Cleave | C | Level 15 + Melee02 rank 1 | 30 / 7s |
| Cyclone Edge | V | Level 35 + Melee04 rank 1 | 40 / 10s |

Melee mastery earns one XP per successful direct hit on a non-practice enemy. Every 25 XP grants a rank, up to 20; each rank adds 1.5% damage to basic melee and sword arts. XP persists in saves. Skill upgrades continue to use level-up skill points. Form points continue to drop from enemy kills.

Sword moves validate unlocks, living characters, equipment, stamina and cooldowns on the server. Hits check range, facing where appropriate, and obstructions. Repeated requests cannot duplicate a move; changing character or unequipping cancels its pending hits. These are cosmetic motion poses and server-resolved damage, not uploaded animation assets.

## Inventory, admin, and spell fixes

- Item grants have direct category filters, quantity presets, explicit target text, stack limits and validated quantities. Named bosses and all configured transformation forms have admin controls.
- Admin cooldown resets now update both server state and the casting client's timers. Forced evolution does not subtract gold; ordinary evolution still checks level, cleared waves and currency.
- Six spell slots preserve empty positions and survive save/reload. Assigning to slot 6 stays in slot 6. Duplicate and locked spells are rejected, and combat/ultimate slots can be cleared.
- Store operations wait for inventory load. Quest rewards remain claimable if their item reward will not fit. Partial world-loot pickups leave the uncollected quantity available.
- Crafting honors locked/favorite ingredients and can reuse a slot freed by consuming ingredients. Sell Junk preserves materials and consumables. Individual sale also protects favorites.
- Item details refresh across tab changes and show ingredient counts and protected ingredients. Equipped form health bonuses survive stat refreshes.
- Elemental melee kills credit melee quests. Realm elite spawns make realm elite quests completable. Failed persistent data loads do not overwrite existing saves.

## Xbox 360 controller layout

Uses Roblox's standard gamepad inputs for an Xbox 360 controller connected to a supported PC. This does not make Roblox run on an Xbox 360 console. Physical hardware detection and play feel have not been verified here.

| Input | Action |
| --- | --- |
| Left stick / right stick | Move / camera and aim |
| A / X / B | Jump / basic melee combo / assigned technique (Dodge by default) |
| Y | Selected sword art; choose it in MELEE |
| RT / LT | Selected spell, aimed / local area |
| LB / RB | Cycle equipped combat spells |
| Left-stick click / right-stick click | Assigned travel power / ultimate |
| D-pad up (hold) / right | Block / secondary ranged weapon |
| D-pad left / down | Health core / mana crystal |
| BACK | Enter or exit menu dock navigation |
| A / B in menus | Select / close panel, then leave dock |
| D-pad / left stick in menus | Navigate; scrolling follows selection |
| START | Roblox system menu (engine default) |

Keyboard spells use 1-6; supplies use 7-9. X casts the assigned ultimate, Q uses travel, Shift uses the technique, F blocks, E/right-click fires the secondary weapon. B opens inventory, J quests, K skills, M melee, P powers, T forms, U evolution, and F8 admin. Touch retains combat controls and adds dedicated sword-art buttons.

Controller shortcuts previously shared by settings/ultimate, quests/block, and inventory/menu navigation are separated. The menu dock reaches every menu. Opening panels suppresses combat inputs and releases blocking; dynamic lists restore focus where possible. Menus with search or arbitrary numeric/text entry use Roblox TextBox input; item grants also offer controller-friendly filters and quantity presets.

Reference: [Roblox gamepad input](https://create.roblox.com/docs/input/gamepad), [GuiService selection](https://create.roblox.com/docs/reference/engine/classes/GuiService).

## Automated validation

- `python tests/run_regressions.py --luau <path-to-luau.exe>`: 715 configuration and server regression assertions passed against actual modules with Roblox API stubs.
- Checks include every item's acquisition route, item/ability/recipe/loot references, reachable realms and powers, protected inventory transactions, full-bag quest claims, sparse spell slots, level caps, evolution requirements, sword unlocks/stamina/cooldowns/hit counts and respawn cancellation.
- All 68 runtime Luau files compile. VS Code's installed Roblox LSP was run over the source tree; no error diagnostics were reported.
- `rojo sourcemap default.project.json --output build/overhaul-sourcemap.json` and `rojo build default.project.json --output build/overhaul-validation.rbxlx` succeed. Rojo reports an existing lossy name-encoding warning inside the imported mobs asset.

## Studio acceptance checks still required

1. Open `build/overhaul-validation.rbxlx` and enter Play. Verify `WorldStatus`, server Output, and client Output. Test R6 and R15 avatars.
2. Visit all four realms; climb both ramps, fight on terraces, verify sanctuary/transit access and elite quest credit. Revisit streamed-out areas and check ambient sources do not duplicate. Compare HIGH and LOW effects.
3. Cast projectile, beam, radial, chain, gravity, tornado, local and ultimate spells for each element. Check damage timing, visibility and multiplayer observers.
4. Test sword combo cadence, each sword art, interruption by death/equipment changes, cooldown resets, and movement/weapon grip with common and imported weapons.
5. Test item grants to self/another player, filters, stacking, empty/full bags, crafting, equip/unequip, sale protection, claims, level-ups, all three evolutions and form stat refreshes.
6. With a fresh character, earn XP, skill points and form points normally. Save/rejoin a published test place to verify items, slots, mastery and progression persist. Studio persistence is disabled by the existing SaveConfig.
7. Connect an Xbox 360 controller or use Studio Controller Emulator. Visit every menu through BACK, buy a melee upgrade, assign spells, equip gear, select a sword art, scroll long catalogs, then return to combat. Verify reconnect, B navigation, text entry, and each binding above. Repeat with two clients and representative mobile performance.

The Luau stub tests do not establish rendering quality, physics behavior, DataStore integration or physical controller compatibility.
