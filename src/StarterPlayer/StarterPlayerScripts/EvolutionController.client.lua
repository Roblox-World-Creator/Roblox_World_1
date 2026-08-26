local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EvolutionConfig"))
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EvolutionRemote")
local gui = Instance.new("ScreenGui")
gui.Name = "EvolutionUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 126
gui.Parent = player:WaitForChild("PlayerGui")
local open = Instance.new("TextButton")
open.Size = UDim2.fromOffset(118, 36)
open.Position = UDim2.new(1, -448, 0, 14)
open.Text = "EVOLUTION [U]"
open.TextColor3 = Color3.new(1, 1, 1)
open.BackgroundColor3 = Color3.fromRGB(215, 145, 55)
open.Parent = gui
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(430, 330)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(20, 26, 40)
panel.Visible = false
panel.Parent = gui
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 38)
title.Position = UDim2.fromOffset(12, 10)
title.BackgroundTransparency = 1
title.Text = "EVOLUTION PATH"
title.TextColor3 = Color3.fromRGB(255, 215, 90)
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.Parent = panel
local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(18, 58)
status.Size = UDim2.new(1, -36, 0, 180)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(220, 230, 245)
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Font = Enum.Font.Gotham
status.TextSize = 15
status.Parent = panel
local evolve = Instance.new("TextButton")
evolve.Size = UDim2.new(1, -36, 0, 46)
evolve.Position = UDim2.new(0, 18, 1, -64)
evolve.Text = "EVOLVE NOW"
evolve.TextColor3 = Color3.new(1, 1, 1)
evolve.BackgroundColor3 = Color3.fromRGB(65, 160, 115)
evolve.Parent = panel
local function render()
	local current = player:GetAttribute("Evolution") or 0
	local nextEvolution = config[current + 1]
	if not nextEvolution then
		status.Text = string.format("CURRENT ASCENDANT: %d\n\nYou have reached the final known evolution.", current)
		evolve.Visible = false
		return
	end
	status.Text = string.format("CURRENT ASCENDANT: %d\n\nNEXT ASCENDANT: %d\nRequired level: %d\nRequired wave: %d\nCost: %d coins\n\nRewards:\nAttack x%.2f  |  Health x%.2f\nEnergy x%.2f  |  Speed x%.2f", current, current + 1, nextEvolution.Level, nextEvolution.Wave, nextEvolution.Coins, nextEvolution.AttackMultiplier, nextEvolution.HealthMultiplier, nextEvolution.EnergyMultiplier, nextEvolution.SpeedMultiplier)
	evolve.Visible = true
	evolve.Text = player:GetAttribute("CanEvolve") and "EVOLVE NOW" or "REQUIREMENTS NOT MET"
	evolve.BackgroundColor3 = player:GetAttribute("CanEvolve") and Color3.fromRGB(65, 160, 115) or Color3.fromRGB(80, 88, 105)
end
local function toggle()
	panel.Visible = not panel.Visible
	if panel.Visible then render() end
end
open.Activated:Connect(toggle)
evolve.Activated:Connect(function()
	if player:GetAttribute("CanEvolve") then remote:FireServer() end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.U then toggle() end
end)
for _, attribute in ipairs({"Evolution", "Level", "Coins", "CanEvolve"}) do player:GetAttributeChangedSignal(attribute):Connect(render) end