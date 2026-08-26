# Evolution Ascendant

Evolution Ascendant is an original Roblox action-RPG and wave-defense prototype managed with Rojo. The current build is a playable combat slice: players defend a multi-level fort, fight pathfinding enemies with an Iron Blade and energy abilities, dash with stamina, earn persistent XP/gold, and progress toward evolution.

## Run in Roblox Studio

1. Install Rojo 7.7 (`aftman install` if Aftman is available).
2. Run `rojo serve default.project.json` from this directory.
3. Open a Roblox Studio place, connect the Rojo plugin to `localhost:34872`, and sync.
4. Start a Play test. Use M1 for the sword combo; `1`/`2` for Energy Bolt/Burst; `Z`, `X`, `C`, and `V` for Energy Beam, Gravity Pulse, Chain Lightning, and Rift Tornado; `Q` to dash; `Shift` to dodge; and hold `F` to block. Press `B` for inventory/crafting/store, `P` for powers and mastery loadouts, `J` for quests, and `3`/`4`/`5` for quick consumables.

Players spawn on the north upper battlement. Ramps reach the lower core deck, and cyan trusses on the four corner towers reach the upper ring. Enemies telegraph attacks with red warning effects; moving out of range during the windup avoids the hit.

Waves now progress through 50 before looping. Completion grants XP and gold, elites begin appearing from wave 3, and every tenth wave includes a multi-phase boss. Boss rewards require meaningful participation rather than the final hit.

Boss waves rotate between the Stone Destroyer, Rift Tyrant, and Storm Colossus. Stone emphasizes arena slams, Rift adds a telegraphed gravity vortex, and Storm marks player positions before lightning strikes. All special damage honors dodge invulnerability, god mode, and equipment defense.

The gear button in the upper-right toggles effect quality, camera shake, and damage numbers. Blocking shortly before an enemy strike triggers a perfect block; repeatedly tapping block cannot continuously reset that timing window.

The **ADMIN** button opens locked server controls. After entering the configured lock code, an authorized session can target a player by name/UserId, kick, toggle god mode, heal/refill resources, apply capped speed or temporary damage boosts, unlock power gates, grant allowlisted items, select the next wave, and create controlled practice enemies. Authorization resets when the player leaves the server. A shared numeric code is appropriate for private testing, but production releases should replace it with a private user-ID allowlist and rotate the code.

## Inventory, loot, and store

Revision `0.10.0` adds a persistent, migration-safe item loop. Enemies roll weighted consumable/material/equipment drops, elites gain a bonus table, and participating boss fighters receive a guaranteed Boss Core plus rare-drop rolls. The bag supports search, category filters, rarity sorting, favorites, locks, equipping, comparison, consumable use, crafting, buying, and selling. Equipped health, MP, attack, power, defense, speed, and critical stats feed directly into combat.

The Fort Supply kiosk points players to the Store tab. Starter supplies and selected gear can be bought with gold; rare boss and artifact items remain drop goals. The source icon atlas is at `assets/evolution-ascendant-item-atlas-v1.png`. Upload and slice it through Roblox asset tools before replacing the built-in procedural icon fallback with `rbxassetid://` references.

## Powers, mastery, and quests

Six combat attacks now unlock through level/evolution progression, including Rift Tornado. Every successful cast and damage event grants persistent mastery XP. The Powers panel shows unlock gates and mastery ranks, and lets players choose six attacks plus two movement powers for the active loadout. The server validates every active slot.

The Ascendant Quest Board and `J` open a five-objective campaign covering normal enemies, elites, waves, boss participation, and material collection. Completed quests have server-authoritative claimable XP, gold, consumable, material, and Boss Core rewards. Quest progress, claims, mastery, inventory, equipment, and visual settings use save schema v3 with defaults for older profiles.

## Xbox-style controller

- `X`: melee attack; `RT`: cast selected power; `LB`/`RB`: cycle powers.
- `B`: dash; `LT`: block; left-stick click: dodge; `Y`: evolve.
- View/Back: bag; right-stick click: settings; hold `LT` and press D-pad up for admin. Keyboard admin shortcut: `F8`.
- D-pad left/down/right: Health Core, Mana Crystal, and Battle Serum.
- D-pad up: quest log.
- The on-screen Powers panel shows the active six attacks and two movement powers; select it with the mouse/touch UI or keyboard `P`.
- While the bag is open, `LB`/`RB` change tabs, `A` activates the selected control, and `B` closes it.

Revision `0.11.1` makes the server bootstrap create and repair every required remote before any gameplay service starts. This prevents a partially synced Studio place from blocking inventory startup—and therefore combat and waves—when newly declared remotes have not yet been created by Rojo. The custom UI disables Roblox's overlapping PlayerList, Backpack, Health, and Emotes CoreGui surfaces.

Revision `0.11.2` docks inventory and quests to the right so the combat HUD remains visible. CoreGui suppression is repeatedly applied during client initialization and after respawn, and the Roblox top bar is hidden to prevent its persistent overlay from covering health/resources.

Studio tests use quiet in-memory session data by default, so unpublished places do not generate DataStore errors. Published live servers automatically use persistent DataStores. To test persistence in Studio, publish the experience, enable **Game Settings → Security → Enable Studio Access to API Services**, and set `EnableInStudio = true` in `SaveConfig.lua`.

## Studio developer commands

These chat commands are available to everyone in Studio. In production, only user IDs listed in `DebugConfig.lua` are authorized.

- `!setlevel 10`
- `!givexp 500`
- `!givegold 1000`
- `!refillhp`
- `!refillmp`
- `!refillstamina`
- `!setwave 10` (sets the next wave; useful for boss testing)

## Repository layout

- `src/ReplicatedStorage/Shared`: balance and runtime configuration.
- `src/ServerScriptService/Systems`: authoritative gameplay services.
- `src/StarterPlayer/StarterPlayerScripts`: input, HUD, and client presentation.
- `default.project.json`: Rojo DataModel mapping and prototype arena.

See [ARCHITECTURE.md](ARCHITECTURE.md), [GAME_SYSTEMS.md](GAME_SYSTEMS.md), [BALANCE.md](BALANCE.md), and [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) for implementation details and roadmap status.

## Revisions

Every playable update increments `WorldConfig.Version`. The HUD reads that replicated revision directly; it no longer carries a second hardcoded version that can drift out of sync.
