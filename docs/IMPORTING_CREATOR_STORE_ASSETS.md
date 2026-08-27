# Importing Creator Store Models Safely

## Studio workflow

1. Open the Rojo-connected place in Roblox Studio, then open **Window/Home → Toolbox**.
2. Select **Creator Store → Models** and search for the asset. Prefer Roblox-created or well-documented creators and record the creator, asset ID, and direct URL before insertion.
3. Insert the model into `Workspace → ImportQuarantine` first. Never press Play while an unaudited model is in this folder; do not immediately move it into the approved library.
4. In Explorer, expand every descendant. Inspect every `Script`, `LocalScript`, `ModuleScript`, `RemoteEvent`, `RemoteFunction`, `BindableEvent`, and `BindableFunction`.
5. Reject assets containing obfuscation, unknown numeric `require(...)`, HTTP calls, admin/backdoor code, unexpected DataStore/teleport code, destructive loops, or client-authoritative damage/rewards.
6. Delete all gameplay scripts and remotes from a visual model. Keep only reviewed cosmetic instances such as MeshParts, Attachments, Trails, Beams, ParticleEmitters, textures, safe constraints, and audited animation helpers.
7. Group the visual under one `Model`, choose a sensible `PrimaryPart`, and orient it consistently. The weapon grip axis should run along local Y; place the handle/pivot near the character's hand.
8. Rename the root to the exact stable model profile from `AssetRegistry.lua`, such as `ThunderKatanaModel01`.
9. Move the approved model to `ReplicatedStorage → GameAssets → Weapons` (or `Transformations`, `Enemies`, `Bosses`, `Projectiles`, `Pickups`, `WorldProps`). Never place it in a gameplay service.
10. Update `docs/ASSET_CREDITS.md`, including all scripts found and what was kept, removed, or modified.

The runtime `AssetModelService` clones only approved model/profile names and strips scripts, remotes, and bindables again defensively. If a model is missing or has no BasePart, the game uses its procedural fallback.

## Keeping imported models in source control

Toolbox insertion modifies the Studio place, not a Luau source file. For a team/Git workflow, right-click the sanitized Model in Explorer and choose **Save to File**, saving it as `assets/models/<ModelProfile>.rbxm`. Then add that file as a `$path` entry under the appropriate `GameAssets` folder in `default.project.json`.

Example:

```json
"Weapons": {
  "$className": "Folder",
  "ThunderKatanaModel01": {
    "$path": "assets/models/ThunderKatanaModel01.rbxm"
  }
}
```

Do not commit the original unsanitized download. Packages can be useful for controlled updates, but disable automatic updates on third-party packages until each new version has been audited.
