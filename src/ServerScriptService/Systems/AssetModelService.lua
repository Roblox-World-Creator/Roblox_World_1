local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetModelService = {}
local ALLOWED_CONTAINERS = {Weapons = true, Transformations = true, Enemies = true, Bosses = true, Projectiles = true, Pickups = true, WorldProps = true}
local UNSAFE_CLASSES = {Script = true, LocalScript = true, ModuleScript = true, RemoteEvent = true, RemoteFunction = true, BindableEvent = true, BindableFunction = true}

local function sanitize(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if UNSAFE_CLASSES[descendant.ClassName] then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
		end
	end
end

local function normalizeModel(instance)
	if instance:IsA("Model") then return instance end
	if instance:IsA("BasePart") then
		local model = Instance.new("Model")
		instance.Parent = model
		model.PrimaryPart = instance
		return model
	end
	instance:Destroy()
	return nil
end

function AssetModelService.Clone(containerName, modelId)
	if not ALLOWED_CONTAINERS[containerName] or type(modelId) ~= "string" or modelId == "" then return nil end
	local assets = ReplicatedStorage:FindFirstChild("GameAssets")
	local container = assets and assets:FindFirstChild(containerName)
	local source = container and container:FindFirstChild(modelId)
	if not source or (not source:IsA("Model") and not source:IsA("BasePart")) then return nil end
	local clone = normalizeModel(source:Clone())
	if not clone then return nil end
	sanitize(clone)
	clone.Name = modelId
	clone:SetAttribute("ApprovedAssetClone", true)
	clone.PrimaryPart = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
	if not clone.PrimaryPart then clone:Destroy(); return nil end
	return clone
end

function AssetModelService.WeldModel(model)
	local root = model and model.PrimaryPart
	if not root then return false end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant ~= root then
			local alreadyConnected = false
			for _, connected in ipairs(root:GetConnectedParts(true)) do if connected == descendant then alreadyConnected = true break end end
			if not alreadyConnected then
				local weld = Instance.new("WeldConstraint")
				weld.Name, weld.Part0, weld.Part1, weld.Parent = "ImportedAssetWeld", root, descendant, root
			end
		end
	end
	return true
end

return AssetModelService
