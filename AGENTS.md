# AGENTS.md

## Project
This repository is a Roblox action-RPG / wave-defense prototype. The driving code lives in `src/ServerScriptService/Systems`, shared game balance lives in `src/ReplicatedStorage/Shared`, and the bootstrap entrypoint is `src/ServerScriptService/World.server.lua`.

## Operating rules
- Keep `World.server.lua` as a thin composition root. Do not add gameplay logic there.
- Prefer reusable systems in `src/ServerScriptService/Systems`.
- Keep shared constants and tunables in `src/ReplicatedStorage/Shared`.
- Maintain server authority for rewards, cooldowns, movement validation, and damage resolution.
- Treat client input as untrusted. Validate player, character, and humanoid references before mutating state.
- Make systems idempotent when possible and clean up temporary connections, parts, attributes, and timers.
- Prefer configuration-driven values over magic numbers.
- Keep modules focused on one concern. Avoid mixing unrelated responsibilities.
- Preserve the existing lifecycle pattern: `Start(config)` and cleanup inside the owning module.

## Code-change workflow
- Start with the smallest relevant file(s); avoid broad repository-wide reads unless required.
- If fixing a bug, find the exact system, then read the most relevant config and service file before editing.
- Prefer surgical changes over refactors.
- Do not add test-only code to runtime modules.
- Do not broad-scope changes across unrelated gameplay systems.

## Validation
- Run VS Code diagnostics for edited Luau files.
- Validate the Rojo project with `rojo sourcemap default.project.json` after gameplay or bootstrapping changes.
- Test in Roblox Studio Play mode when a runtime behavior is impacted.

## Good prompts for this repo
Use prompts like:
- "Review the combat startup path and identify the likely cause of the server boot issue."
- "Fix the WaveDefense lifecycle so repeated syncs do not duplicate world state."
- "Add a narrow validation guard to this movement system without changing balance data."
- "Summarize the server-authoritative rules for damage and rewards in this system."

## Avoid
- Broad, speculative rewrites of gameplay systems.
- Editing shared config values without checking the consumer modules.
- Adding client-side trust assumptions.
- Unnecessary repo-wide searches or redesigns.
