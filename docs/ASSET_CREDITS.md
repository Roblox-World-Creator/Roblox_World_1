# Asset Credits and Security Audit

The current runtime uses repository-authored procedural geometry and effects. No Creator Store model or script is presently bundled.

| Asset name | Creator | Asset ID / URL | Usage | Model path | Scripts included | Audit action |
|---|---|---|---|---|---|---|
| Evolution Ascendant item atlas v1 | Project-local | `assets/evolution-ascendant-item-atlas-v1.png` | Source artwork for future Roblox-uploaded item icons | Not uploaded/runtime-bound | None | Retained as local source asset |
| Procedural fallback models | Project-local | N/A | Weapons, armor, pickups, enemies, portals, projectiles, VFX | Generated at runtime | Repository services/controllers only | Retained |

## Required record for future imports

Every imported asset must add its creator, asset ID, direct Creator Store URL, usage, destination path, included scripts/remotes, scripts kept/removed/modified, and security findings. Reject unknown `require(assetId)`, HTTP calls, obfuscation, backdoors/admin commands, unexpected DataStore/teleport access, destructive loops, and client-authoritative damage or rewards.
