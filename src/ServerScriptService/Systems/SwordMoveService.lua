local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.MeleeConfig)
local SwordMoveService = {}

function SwordMoveService.Start(config)
	local cooldowns = {}
	local api = {}
	function api.Cast(player, id)
		local move = type(id) == "string" and Config.Moves[id]
		if not move or not player:GetAttribute("InventoryReady") then return end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 or player:GetAttribute("EvolutionTransforming") then return end
		local function reject(message) config.Feedback:FireClient(player, "CastRejected", message) end
		local skills = player:FindFirstChild("Skills")
		local skill = skills and skills:FindFirstChild(move.Skill)
		if not player:GetAttribute("AdminAllPowersUnlocked") and ((player:GetAttribute("Level") or 1) < move.RequiredLevel or not skill or skill.Value < 1) then reject("Unlock " .. move.DisplayName .. " in MELEE first"); return end
		if (player:GetAttribute("EquippedWeapon") or "") == "" then reject("Equip a melee weapon first"); return end
		local now = workspace:GetServerTimeNow()
		if now < (player:GetAttribute("SwordMoveBusyUntil") or 0) or now < (player:GetAttribute("MeleeReadyAt") or 0) then return end
		cooldowns[player] = cooldowns[player] or {}
		if now < (cooldowns[player][id] or 0) then reject("Sword move cooling down"); return end
		if (player:GetAttribute("Stamina") or 0) < move.Stamina then reject("Need more stamina"); return end
		local recoveryScale = math.max(0.55, 1 - (player:GetAttribute("MeleeCooldownReduction") or 0))
		cooldowns[player][id] = now + move.Cooldown * recoveryScale
		player:SetAttribute("Sword" .. id .. "ReadyAt", cooldowns[player][id])
		player:SetAttribute("SwordMoveBusyUntil", now + move.Duration)
		player:SetAttribute("Stamina", player:GetAttribute("Stamina") - move.Stamina)
		player:SetAttribute("LastStaminaUse", now)
		player:SetAttribute("Blocking", false)
		config.Effects:FireAllClients("SwordMove", {Character = character, Origin = root.Position, Direction = root.CFrame.LookVector, Move = id, Duration = move.Duration, Element = player:GetAttribute("EquippedWeaponElement")})
		local weapon = player:GetAttribute("EquippedWeapon")
		local parameters = RaycastParams.new()
		parameters.FilterType = Enum.RaycastFilterType.Exclude
		parameters.FilterDescendantsInstances = {character, workspace:FindFirstChild("Enemies") or character}
		parameters.RespectCanCollide = true
		for hitIndex = 1, move.Hits or 1 do
			task.delay(move.Windup + (hitIndex - 1) * (move.HitInterval or 0), function()
				if not player.Parent or player.Character ~= character or humanoid.Health <= 0 or not root.Parent or player:GetAttribute("EquippedWeapon") ~= weapon then return end
				local range = move.Range + (player:GetAttribute("MeleeRangeBonus") or 0)
				for _, enemy in ipairs(config.GetEnemies(root.Position, range)) do
					local target = enemy:FindFirstChild("HumanoidRootPart")
					if not target then continue end
					local offset = target.Position - root.Position
					if id ~= "Whirlwind" and offset.Magnitude > 0.01 and root.CFrame.LookVector:Dot(offset.Unit) < 0.3 then continue end
					local obstruction = workspace:Raycast(root.Position, offset, parameters)
					if obstruction and not obstruction.Instance:IsDescendantOf(enemy) then continue end
					config.Damage(player, enemy, move.DamageMultiplier, id == "Cleave")
					config.Knockback(enemy, root.Position, move.Knockback)
				end
			end)
		end
	end
	function api.Reset(player)
		cooldowns[player] = nil
		for id in pairs(Config.Moves) do player:SetAttribute("Sword" .. id .. "ReadyAt", 0) end
	end
	local connection = Players.PlayerRemoving:Connect(function(player) cooldowns[player] = nil end)
	function api.Destroy() connection:Disconnect(); table.clear(cooldowns) end
	return api
end

return SwordMoveService
