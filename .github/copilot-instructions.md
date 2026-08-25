# Roblox project conventions

- Keep `World.server.lua` as a thin composition root. Put reusable gameplay systems in `src/ServerScriptService/Systems`.
- Keep shared constants and tunable feature settings in `src/ReplicatedStorage/Shared`.
- Keep server authority for rewards, movement modifiers, cooldowns, and validation. Never trust client-provided gameplay results.
- Make systems expose a small lifecycle API such as `Start(config)` and keep connections and cleanup inside the owning module.
- Make new features idempotent when possible: repeated syncs or server initialization should not duplicate world instances or event effects.
- Prefer configuration-driven values over magic numbers, and validate player, character, and humanoid references before mutating state.
- Clean up temporary instances, connections, attributes, and timed effects when a feature ends or a player leaves.
- Keep modules focused on one responsibility. Avoid adding unrelated behavior to existing systems.
- Validate changed Luau files with VS Code diagnostics and validate the Rojo project with `rojo sourcemap default.project.json`.
- Test gameplay changes in Roblox Studio Play mode after Rojo sync. Do not commit credentials, API keys, or generated build output.