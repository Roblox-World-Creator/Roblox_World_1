# Roblox World 1

This is a Rojo-managed Roblox Studio project. Edit Luau files in VS Code, let Rojo sync them into Studio, and use Studio's Play/Test controls to verify the result.

## One-time setup

1. Open this folder in VS Code.
2. Install Rojo from the Rojo extension's command palette menu: `Rojo: Install Rojo`.
3. In Roblox Studio, install the Rojo plugin from the same command palette menu: `Rojo: Install Roblox Studio plugin`.
4. Open a new Baseplate or the place you want to develop.
5. Run the VS Code task `Roblox: Start live sync`.
6. In Studio, click the Rojo plugin button and connect to the project.

The first sync creates `LiveSyncMarker` in Workspace and prints `Roblox World 1 loaded through Rojo` in the Studio Output window. Change `WorldConfig.lua` and save to see the marker update without manually copying scripts.

## Daily workflow

- Use `Ctrl+Shift+B` or the task picker for `Roblox: Start live sync`.
- Edit files under `src/`; the `default.project.json` file maps them to Roblox services.
- Use Studio Play/Test for live behavior checks.
- Use `Roblox: Build place model` when a standalone `.rbxlx` file is needed.
- Use `Roblox: Validate project` to inspect the generated Rojo sourcemap.

Copilot can work in this workflow by editing the files in this repository. Rojo then delivers those edits to the connected Studio session. Studio remains the authority for running and testing the game.

## Installed Roblox extensions

The workspace recommends the installed Rojo, Luau LSP, autocomplete, and API Explorer extensions. The Roblox Editor extension can read and write scripts through Roblox Open Cloud, but it requires a Roblox API key with Engine (Beta), Read, and Write access and cannot update scripts that are currently open in Studio. It is best kept as a fallback for remote script editing, not the live-sync path.

The `rbxexecute` extension is intentionally not part of this workflow. Its README requires a third-party executor and a websocket autoexec script; that is outside the supported Roblox Studio development path and is not needed for Rojo.

## OpenRouter free usage

OpenRouter's official free options are:

- `openrouter/free`, which routes to an available free model.
- Any model listed at <https://openrouter.ai/models?max_price=0>, using its `:free` variant where supported.

According to the current OpenRouter FAQ, new users receive a small free allowance. Free-model API use is limited to 50 requests per day without purchased credits, or 1,000 requests per day after purchasing at least $10 in credits. Free models have low limits and may be unsuitable for production. There are no legitimate permanent free API-key links; create a key in your own OpenRouter account and keep it outside this repository.

The `.env.example` file shows the variable names for future local tooling. Never commit a real `OPENROUTER_API_KEY`. Official pages:

- <https://openrouter.ai/keys>
- <https://openrouter.ai/models?max_price=0>
- <https://openrouter.ai/docs/faq>
- <https://openrouter.ai/docs/api-reference/overview>

## Roblox credentials

For the Roblox Editor extension only, create an API key at <https://create.roblox.com/dashboard/credentials?activeTab=ApiKeysTab> with Engine (Beta), the target experience, Read, and Write operations. Store it in the extension's secure prompt or credential storage, never in this repository.