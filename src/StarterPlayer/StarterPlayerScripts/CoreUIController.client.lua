local StarterGui = game:GetService("StarterGui")

-- Evolution Ascendant replaces these CoreGui surfaces with its own HUD and bag.
-- Disabling them also prevents View/Back from opening a second player-list popup
-- underneath the controller-driven inventory.
local disabledCoreGui = {
	Enum.CoreGuiType.PlayerList,
	Enum.CoreGuiType.Backpack,
	Enum.CoreGuiType.Health,
	Enum.CoreGuiType.EmotesMenu,
}

task.spawn(function()
	for attempt = 1, 10 do
		local allApplied = true
		for _, coreGuiType in ipairs(disabledCoreGui) do
			local success = pcall(StarterGui.SetCoreGuiEnabled, StarterGui, coreGuiType, false)
			allApplied = allApplied and success
		end
		if allApplied then return end
		task.wait(0.5)
	end
end)
