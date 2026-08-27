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
	local morph = character and character:FindFirstChild("TransformationMorph")
	if morph then morph:Destroy() end
	for _, child in ipairs(character and character:GetChildren() or {}) do
		if child:IsA("BasePart") and child:GetAttribute("FormBodyModified") then
			local color = child:GetAttribute("OriginalFormColor")
			local materialName = child:GetAttribute("OriginalFormMaterial")
			local transparency = child:GetAttribute("OriginalFormTransparency")
			if typeof(color) == "Color3" then child.Color = color end
			if type(materialName) == "string" and Enum.Material[materialName] then child.Material = Enum.Material[materialName] end
			if type(transparency) == "number" then child.Transparency = transparency end
			child:SetAttribute("FormBodyModified", nil)
			child:SetAttribute("OriginalFormColor", nil)
			child:SetAttribute("OriginalFormMaterial", nil)
			child:SetAttribute("OriginalFormTransparency", nil)
		elseif child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle")
			local transparency = handle and handle:GetAttribute("OriginalFormTransparency")
			if handle and type(transparency) == "number" then
				handle.Transparency = transparency
				handle:SetAttribute("OriginalFormTransparency", nil)
			end
		elseif child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
			local propertyName = child:IsA("Shirt") and "ShirtTemplate" or child:IsA("Pants") and "PantsTemplate" or "Graphic"
			local original = child:GetAttribute("OriginalFormClothing")
			if type(original) == "string" then child[propertyName] = original; child:SetAttribute("OriginalFormClothing", nil) end
		end
	end
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	for _, scaleName in ipairs({"BodyWidthScale", "BodyDepthScale", "BodyHeightScale", "HeadScale"}) do
		local scale = humanoid and humanoid:FindFirstChild(scaleName)
		local original = scale and scale:GetAttribute("OriginalFormScale")
		if scale and type(original) == "number" then scale.Value = original; scale:SetAttribute("OriginalFormScale", nil) end
	end
	for _, descendant in ipairs(character and character:GetDescendants() or {}) do
		if descendant:GetAttribute("TransformationVisual") then descendant:Destroy() end
	end
end

local function feature(model, bodyPart, name, size, color, offset, className)
	if not bodyPart then return nil end
	local part = Instance.new(className or "Part")
	part.Name, part.Size, part.Color, part.Material = name, size, color, Enum.Material.SmoothPlastic
	part.CanCollide, part.CanTouch, part.CanQuery, part.Massless = false, false, false, true
	part.CFrame, part.Parent = bodyPart.CFrame * offset, model
	local motor = Instance.new("Motor6D")
	motor.Name, motor.Part0, motor.Part1, motor.C0, motor.Parent = name .. "Joint", bodyPart, part, offset, part
	return part
end

local function setBodyScale(humanoid, name, multiplier)
	local scale = humanoid:FindFirstChild(name)
	if not scale then return end
	if scale:GetAttribute("OriginalFormScale") == nil then scale:SetAttribute("OriginalFormScale", scale.Value) end
	scale.Value = scale:GetAttribute("OriginalFormScale") * multiplier
end

local function feather(model, bodyPart, name, size, color, offset)
	local part = feature(model, bodyPart, name, size, color, offset)
	if not part then return end
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 0.72, 1)
	mesh.Parent = part
	return part
end

local function applyMorph(character, humanoid, formId, definition)
	local morph = Instance.new("Model")
	morph.Name, morph.Parent = "TransformationMorph", character
	local head = character:FindFirstChild("Head")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local bodyColor = definition.Color
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
			child:SetAttribute("OriginalFormColor", child.Color)
			child:SetAttribute("OriginalFormMaterial", child.Material.Name)
			child:SetAttribute("OriginalFormTransparency", child.Transparency)
			child:SetAttribute("FormBodyModified", true)
			child.Color, child.Material = bodyColor:Lerp(child.Color, 0.2), Enum.Material.SmoothPlastic
		elseif child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then handle:SetAttribute("OriginalFormTransparency", handle.Transparency); handle.Transparency = 1 end
		elseif child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
			local propertyName = child:IsA("Shirt") and "ShirtTemplate" or child:IsA("Pants") and "PantsTemplate" or "Graphic"
			child:SetAttribute("OriginalFormClothing", child[propertyName])
			child[propertyName] = ""
		end
	end

	if formId == "Wolf" then
		feature(morph, head, "LeftWolfEar", Vector3.new(0.45, 1.15, 0.35), bodyColor, CFrame.new(-0.43, 0.9, 0) * CFrame.Angles(0, 0, math.rad(-12)), "WedgePart")
		feature(morph, head, "RightWolfEar", Vector3.new(0.45, 1.15, 0.35), bodyColor, CFrame.new(0.43, 0.9, 0) * CFrame.Angles(0, math.pi, math.rad(12)), "WedgePart")
		feature(morph, head, "WolfMuzzle", Vector3.new(0.85, 0.55, 1.15), bodyColor:Lerp(Color3.new(1, 1, 1), 0.18), CFrame.new(0, -0.15, -0.75), "WedgePart")
		feature(morph, torso, "WolfTail", Vector3.new(0.42, 0.42, 2.8), bodyColor, CFrame.new(0, -0.5, 1.3) * CFrame.Angles(math.rad(35), 0, 0))
		setBodyScale(humanoid, "BodyHeightScale", 0.92)
		setBodyScale(humanoid, "BodyDepthScale", 1.12)
	elseif formId == "Bear" then
		local leftEar = feature(morph, head, "LeftBearEar", Vector3.one * 0.75, bodyColor, CFrame.new(-0.58, 0.72, 0))
		local rightEar = feature(morph, head, "RightBearEar", Vector3.one * 0.75, bodyColor, CFrame.new(0.58, 0.72, 0))
		if leftEar then leftEar.Shape = Enum.PartType.Ball end
		if rightEar then rightEar.Shape = Enum.PartType.Ball end
		local muzzle = feature(morph, head, "BearMuzzle", Vector3.new(1.15, 0.68, 0.9), bodyColor:Lerp(Color3.fromRGB(235, 195, 145), 0.5), CFrame.new(0, -0.2, -0.65))
		if muzzle then muzzle.Shape = Enum.PartType.Ball end
		feature(morph, torso, "BearShoulders", Vector3.new(3.4, 1.25, 1.35), bodyColor, CFrame.new(0, 0.65, 0.05))
		setBodyScale(humanoid, "BodyWidthScale", 1.28)
		setBodyScale(humanoid, "BodyDepthScale", 1.25)
		setBodyScale(humanoid, "HeadScale", 1.12)
	elseif formId == "Eagle" then
		local featherBrown = bodyColor:Lerp(Color3.fromRGB(75, 48, 28), 0.28)
		local featherCream = Color3.fromRGB(242, 235, 208)
		local beak = feature(morph, head, "EagleBeak", Vector3.new(0.42, 0.28, 0.62), Color3.fromRGB(245, 178, 42), CFrame.new(0, -0.08, -0.64) * CFrame.Angles(0, math.pi, 0), "WedgePart")
		if beak then beak.Material = Enum.Material.Neon end
		local chest = feather(morph, torso, "EagleChest", Vector3.new(1.22, 1.55, 0.22), featherCream, CFrame.new(0, 0, -0.58))
		if chest then chest.Material = Enum.Material.Fabric end
		-- A close feather fan reads as a wing while moving with the avatar; no oversized slab meshes.
		for _, side in ipairs({-1, 1}) do
			local sideName = side < 0 and "Left" or "Right"
			for index = 1, 5 do
				local length = 1.25 + index * 0.26
				local x = side * (0.72 + index * 0.29)
				local y = 0.48 - index * 0.12
				local z = 0.34 + index * 0.07
				local roll = side * math.rad(9 + index * 5)
				feather(morph, torso, sideName .. "EagleFeather" .. index, Vector3.new(length, 0.22, 0.48), index >= 4 and featherCream or featherBrown, CFrame.new(x, y, z) * CFrame.Angles(math.rad(-8), 0, roll))
			end
		end
		for index = -1, 1 do
			feather(morph, torso, "EagleTailFeather" .. tostring(index + 2), Vector3.new(0.38, 0.22, 1.65), featherCream, CFrame.new(index * 0.34, -0.92, 0.92) * CFrame.Angles(math.rad(18), 0, math.rad(index * 7)))
		end
		setBodyScale(humanoid, "BodyWidthScale", 0.88)
		setBodyScale(humanoid, "BodyDepthScale", 0.88)
	end
end

local function apply(player, id)
	local definition = id and config.Forms[id]
	local character, humanoid = player.Character, player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid then return false, "Character unavailable" end
	clearVisual(character)
	active[player] = definition and id or nil
	player:SetAttribute("ActiveTransformation", definition and id or "")
	if id ~= "Eagle" then player:SetAttribute("EagleFlightActive", false) end
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
		applyMorph(character, humanoid, id, definition)
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
	if not config.Forms[id] then return false, "Unknown transformation" end
	local folder = player:FindFirstChild("Transformations") or Instance.new("Folder")
	folder.Name, folder.Parent = "Transformations", player
	local value = folder:FindFirstChild(id) or Instance.new("BoolValue")
	value.Name, value.Parent = id, folder
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
		local folder = player:FindFirstChild("Transformations") or Instance.new("Folder")
		folder.Name, folder.Parent = "Transformations", player
		for id, definition in pairs(config.Forms) do
			local value = folder:FindFirstChild(id) or Instance.new("BoolValue")
			value.Name, value.Value, value.Parent = id, value.Value or loaded[id] == true or (player:GetAttribute("Level") or 1) >= definition.RequiredLevel, folder
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
