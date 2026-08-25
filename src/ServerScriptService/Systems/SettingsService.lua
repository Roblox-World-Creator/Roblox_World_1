local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SettingsService = {}

function SettingsService.Start(saveService)
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SettingsRemote")
	local function setup(player)
		while player.Parent and not player:GetAttribute("DataLoaded") do player:GetAttributeChangedSignal("DataLoaded"):Wait() end
		if not player.Parent then return end
		local settings = (saveService.GetLoadedData(player) or {}).Settings or {}
		player:SetAttribute("EffectQuality", settings.EffectQuality == "LOW" and "LOW" or "HIGH")
		player:SetAttribute("CameraShakeEnabled", settings.CameraShakeEnabled ~= false)
		player:SetAttribute("DamageNumbersEnabled", settings.DamageNumbersEnabled ~= false)
	end
	remote.OnServerEvent:Connect(function(player, name, value)
		if name == "EffectQuality" and (value == "HIGH" or value == "LOW") then player:SetAttribute(name, value)
		elseif (name == "CameraShakeEnabled" or name == "DamageNumbersEnabled") and type(value) == "boolean" then player:SetAttribute(name, value) end
	end)
	Players.PlayerAdded:Connect(function(player) task.spawn(setup, player) end)
	for _, player in ipairs(Players:GetPlayers()) do setup(player) end
end

return SettingsService
