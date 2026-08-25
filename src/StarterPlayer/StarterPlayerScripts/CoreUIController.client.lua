local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

-- Evolution Ascendant replaces these CoreGui surfaces with its own HUD and bag.
-- Disabling them also prevents View/Back from opening a second player-list popup
-- underneath the controller-driven inventory.
local disabledCoreGui = {
	Enum.CoreGuiType.PlayerList,
	Enum.CoreGuiType.Backpack,
	Enum.CoreGuiType.Health,
	Enum.CoreGuiType.EmotesMenu,
}

local function suppressCoreGui()
	for _, coreGuiType in ipairs(disabledCoreGui) do
		pcall(StarterGui.SetCoreGuiEnabled, StarterGui, coreGuiType, false)
	end
	pcall(StarterGui.SetCore, StarterGui, "TopbarEnabled", false)
end

-- Core scripts can re-apply their defaults during loading and respawn. Repeat
-- long enough to win that initialization race, then re-apply on every spawn.
task.spawn(function()
	for _ = 1, 30 do
		suppressCoreGui()
		task.wait(0.5)
	end
end)

Players.LocalPlayer.CharacterAdded:Connect(function()
	for _ = 1, 6 do
		task.defer(suppressCoreGui)
		task.wait(0.25)
	end
end)
