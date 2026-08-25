# Game Systems

## Phase 1 vertical slice

- Player progression: level, nonlinear XP requirement, gold, computed health, and attack.
- Resources: HP, regenerating MP, rapidly regenerating stamina after a delay.
- Combat: rate-limited server melee, radius-validated abilities, centralized enemy damage, damage numbers, and single-claim kill rewards.
- Sword combat: four server-timed strikes with alternating procedural swings, escalating damage, controlled hit stun, and a heavy knockback finisher.
- Defense: directional hold-to-block mitigation, stamina consumption, perfect-block interruption, dodge displacement, and server-authoritative invulnerability.
- Equipment presentation: an Iron Blade is welded to the character on spawn.
- Abilities: Energy Bolt is a server-timed projectile with path interception and delayed impact. Energy Burst is a self-centered radial attack with knockback. MP costs, ranges, and cooldowns are server checked.
- Effects: ability, melee, defense, hit-reaction, finisher, and damage-number cosmetics render per-client from server-approved effect messages; cosmetic parts cannot collide, touch, or participate in hit queries.
- Client settings: players can independently reduce effect layers, disable camera shake, or hide damage numbers.
- Movement: Power Dash uses stamina, a server cooldown, obstacle raycasting, and a short trail.
- Enemies and waves: practice targets that retaliate when engaged, scaling wave composition, player acquisition, pathfinding, telegraphed attacks, core fallback, and a wave-ten boss.
- Wave progression: 50 scalable waves, start/clear announcements, completion rewards, active-wave accounting, and Giant/Haste/Fortified elite rolls.
- Boss encounter: dedicated health/phase HUD, reusable 65%/30% phase thresholds, escalating combat stats, dodgeable arena slams, and contribution-based rewards.
- World: a 300×300-stud battlefield with four gated fort entrances, ramps, lower core catwalks, an upper battlement ring, climbable lookout towers, elevated spawn, and streaming support.
- Saving: versioned DataStore payload for level, XP, gold, and evolution with retry/fallback behavior.
- Debugging: Studio/admin-only chat commands for progression and resource testing.
- Administration: server-validated session unlock, failed-attempt lockout, action throttling, player targeting, moderation, god mode, capped speed/damage boosts, power-gate override, wave controls, and practice spawns.
- Inventory: schema-v2 persisted stacks, metadata, capacity, search/filter/sort UI, favorites, locks, equipment, comparison, consumable use, crafting, store purchases, and selling.
- Equipment and loot: server-computed stat totals feed combat; weighted enemy/elite drops and guaranteed participating-player boss cores trigger rarity-colored local loot beams.
- Item presentation: data-driven rarity/category colors, procedural UI glyphs, an original source-art icon atlas, and weapon-specific size/color/glow/trail visuals.
- Controller: Xbox-style bindings cover combat, blocking, dodging, evolution, power selection/casting, quick consumables, inventory navigation, admin, and settings.
- Powers/mastery: server-gated Energy Bolt, Energy Burst, Energy Beam, Gravity Pulse, and Chain Lightning earn persistent mastery that increases damage and reduces MP cost.
- Quests: a server-owned five-quest campaign consumes combat, wave, boss, and inventory events; only the server advances objectives and grants claims.
- Boss variety: every tenth wave rotates Stone/Rift/Storm presentation and mechanics while reusing the phase controller and contribution rewards.
- Settings persistence: effect quality, camera shake, and damage-number preferences are validated on the server and saved in schema v3.

## Trust boundary

The client never supplies damage, reward values, mastery XP, quest progress, resource balances, cooldown completion, arbitrary item definitions, or arbitrary enemy definitions. Aim positions are accepted only after type and range checks. Dash direction comes from the server-observed character orientation. Admin authorization, targeting, caps, throttles, and spawn/item allowlists are enforced by the server.

## Known prototype boundaries

Melee uses procedural fallback motion rather than authored animation assets, and the HUD is script-generated. Boss phase configuration is reusable, but later bosses still need distinct ability sets and arena hazards.
