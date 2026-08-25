local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DebugService = {}

local function isAuthorized(player, config)
	return RunService:IsStudio() or table.find(config.AdminUserIds, player.UserId) ~= nil
end

function DebugService.Start(config, progressionConfig, progression)
	local function runCommand(player, message)
		if not isAuthorized(player, config) or string.sub(message, 1, #config.Prefix) ~= config.Prefix then
			return
		end
		local arguments = string.split(string.sub(message, #config.Prefix + 1), " ")
		local command = string.lower(arguments[1] or "")
		local amount = tonumber(arguments[2])

		if command == "setlevel" and amount then
			player:SetAttribute("Level", math.max(1, math.floor(amount)))
			player:SetAttribute("XP", 0)
			progression.AddXP(player, 0, progressionConfig)
		elseif command == "givexp" and amount then
			progression.AddXP(player, math.max(0, amount), progressionConfig)
		elseif command == "givegold" and amount then
			progression.AddCoins(player, math.max(0, amount))
		elseif command == "refillhp" then
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = humanoid.MaxHealth
			end
		elseif command == "refillmp" then
			local maximum = player:GetAttribute("MaxMP") or 100
			player:SetAttribute("MP", maximum)
			player:SetAttribute("Energy", maximum)
		elseif command == "refillstamina" then
			player:SetAttribute("Stamina", player:GetAttribute("MaxStamina") or 100)
		elseif command == "setwave" and amount then
			workspace:SetAttribute("DebugNextWave", math.max(1, math.floor(amount)))
		else
			warn("Unknown developer command: " .. command)
		end
	end

	local function setup(player)
		player.Chatted:Connect(function(message)
			runCommand(player, message)
		end)
	end
	Players.PlayerAdded:Connect(setup)
	for _, player in ipairs(Players:GetPlayers()) do
		setup(player)
	end
end

return DebugService
