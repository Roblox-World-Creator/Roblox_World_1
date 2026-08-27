local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TransformationService = {}
local config
local active = {}

local function unlocked(player, id)
	local unlocks = player:FindFirstChild("Transformations")
	return player:GetAttribute("AdminAllTransformationsUnlocked") or (unlocks and unlocks:FindFirstChild(id) and unlocks[id].Value)
end

local function clearVisual(character)
	local visual = character and character:FindFirstChild("TransformationVisual")
	if visual then visual:Destroy() end
	for _, descendant in ipairs(character and character:GetDescendants() or {}) do
		if descendant:GetAttribute("TransformationVisual") then descendant:Destroy() end
	end
end

local function apply(player, id)
	local definition = id and config.Forms[id]
	local character, humanoid = player.Character, player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid then return false, "Character unavailable" end
	clearVisual(character)
	active[player] = definition and id or nil
	player:SetAttribute("ActiveTransformation", definition and id or "")
	player:SetAttribute("TransformationMoveMultiplier", definition and (definition.StatModifiers.MoveSpeed or 1) or 1)
	player:SetAttribute("TransformationDefense", definition and (definition.StatModifiers.Defense or 0) or 0)
	player:SetAttribute("TransformationCriticalChance", definition and (definition.StatModifiers.CriticalChance or 0) or 0)
	local baseSpeed = 36 * (player:GetAttribute("SpeedMultiplier") or 1) + (player:GetAttribute("EquipmentSpeed") or 0)
	humanoid.WalkSpeed = player:GetAttribute("AdminSpeedOverride") or baseSpeed * (definition and (definition.StatModifiers.MoveSpeed or 1) or 1)
	local baseHealth = player:GetAttribute("MaxHealth") or humanoid.MaxHealth
	local healthRatio = humanoid.Health / math.max(1, humanoid.MaxHealth)
	humanoid.MaxHealth = baseHealth * (definition and (definition.StatModifiers.Health or 1) or 1)
	humanoid.Health = math.max(1, humanoid.MaxHealth * healthRatio)
	if not definition then return true, "Returned to ascendant form" end
	local visual = Instance.new("Highlight")
	visual.Name, visual.Adornee, visual.FillColor = "TransformationVisual", character, definition.Color
	visual.FillTransparency, visual.OutlineTransparency, visual.Parent = 0.68, 0.05, character
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name, emitter.Color = "SpiritAura", ColorSequence.new(definition.Color, Color3.new(1, 1, 1))
		emitter.Rate, emitter.Lifetime, emitter.Speed, emitter.Parent = 22, NumberRange.new(0.5, 1), NumberRange.new(1, 3), root
		emitter:SetAttribute("TransformationVisual", true)
	end
	return true, "Transformed into " .. definition.DisplayName
end

local function state(player)
	local unlockedForms = {}
	for id in pairs(config.Forms) do unlockedForms[id] = unlocked(player, id) end
	return {Active = active[player] or "", Unlocked = unlockedForms}
end

function TransformationService.Unlock(player, id)
	local folder = player:FindFirstChild("Transformations")
	local value = folder and folder:FindFirstChild(id)
	if not value then return false, "Unknown transformation" end
	value.Value = true
	return true, "Unlocked " .. config.Forms[id].DisplayName
end

function TransformationService.Set(player, id)
	if id ~= "" and (not config.Forms[id] or not unlocked(player, id)) then return false, "Transformation is locked" end
	return apply(player, id ~= "" and id or nil)
end

function TransformationService.Start(transformationConfig, saveService)
	config = transformationConfig
	local remote = ReplicatedStorage.Remotes:WaitForChild("TransformationRemote")
	local function setup(player)
		while player.Parent and not player:GetAttribute("DataLoaded") do player:GetAttributeChangedSignal("DataLoaded"):Wait() end
		if not player.Parent then return end
		local loaded = (saveService.GetLoadedData(player) or {}).Transformations or {}
		local folder = Instance.new("Folder")
		folder.Name, folder.Parent = "Transformations", player
		for id, definition in pairs(config.Forms) do
			local value = Instance.new("BoolValue")
			value.Name, value.Value, value.Parent = id, loaded[id] == true or (player:GetAttribute("Level") or 1) >= definition.RequiredLevel, folder
		end
		player:GetAttributeChangedSignal("Level"):Connect(function()
			local level = player:GetAttribute("Level") or 1
			for id, definition in pairs(config.Forms) do if level >= definition.RequiredLevel then folder[id].Value = true end end
		end)
		player.CharacterAdded:Connect(function() task.delay(0.25, function() if active[player] then apply(player, active[player]) end end) end)
	end
	remote.OnServerInvoke = function(player, action, payload)
		if action == "GetState" then return {Success = true, State = state(player)} end
		if action == "Toggle" then local id = tostring(payload and payload.FormId or ""); if active[player] == id then id = "" end; local ok, message = TransformationService.Set(player, id); return {Success = ok, Message = message, State = state(player)} end
		return {Success = false, Message = "Unknown transformation action", State = state(player)}
	end
	Players.PlayerAdded:Connect(function(player) task.spawn(setup, player) end)
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(setup, player) end
	Players.PlayerRemoving:Connect(function(player) active[player] = nil end)
end

return TransformationService
