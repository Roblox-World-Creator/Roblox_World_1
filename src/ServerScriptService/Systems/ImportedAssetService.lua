local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")

local ImportedAssetService = {}

local UNSAFE_CLASSES = {
	Script = true, LocalScript = true, ModuleScript = true,
	RemoteEvent = true, RemoteFunction = true, BindableEvent = true, BindableFunction = true,
	Humanoid = true, Animator = true,
}

local IMPORT_MAP = {
	Weapons = {
		{Source = "Classic Sword", Target = "BasicSwordModel01"},
		{Source = "Sword", Target = "DawnsteelSwordModel01"},
		{Source = "Sword Katana", Target = "SkyglassKatanaModel01"},
		{Source = "Katana", Target = "ThunderKatanaModel01"},
		{Source = "Azure Sword", Target = "InfernoSwordModel01"},
		{Source = "Katana Model", Target = "FrostSpearModel01"},
		{Source = "Epic Katana", Target = "RiftwindKatanaModel01"},
		{Source = "Diamond Blade Sword", Target = "EarthbreakerModel01"},
		{Source = "Black Katana", Target = "GravityHammerModel01"},
		{Source = "Sword of Light", Target = "CelestialLightbladeModel01"},
		{Source = "Admin Gun", Target = "SolarChaingunModel01", Root = "Weapons"},
		{Source = "Tommy Gun", Target = "EmberRepeaterModel01", Root = "Weapons"},
		{Source = "Purple Laser Gun", Target = "VoidStaffModel01", Root = "Weapons"},
		{Source = "Pistol Gun", Target = "FrostPistolModel01", Root = "Weapons"},
		{Source = "Fast Hyper Laser Gun", Target = "TempestLaserModel01", Root = "Weapons"},
		{Source = "Working Pistol", Target = "StonehandCannonModel01", Root = "Weapons"},
		-- Spawners and multi-weapon packs deliberately stay quarantined in ServerStorage.
		-- Only one self-contained weapon model may enter gameplay catalogs.
	},
	Enemies = {
		{Source = "Wolf", Target = "FireImpModel01"},
		{Source = "Wolf Classic", Target = "FrostWolfModel01"},
		{Source = "Alpha Wolf", Target = "ThunderWolfModel01"},
		{Source = "Iron Golem", Target = "IronGolemModel01"},
		{Source = "Lava Golem", Target = "LavaGolemModel01"},
		{Source = "Orc", Target = "OrcModel01"},
		{Source = "Orc Smasher", Target = "OrcSmasherModel01"},
		{Source = "Orc Archer", Target = "OrcArcherModel01"},
		{Source = "Dragon V1", Target = "AshwingDrakeModel01"},
		{Source = "Dragon", Target = "RiftDragonModel01"},
		{Source = "Monster NPC Killer", Target = "NullHunterModel01"},
		{Source = "Backrooms Monster", Target = "LabyrinthHorrorModel01"},
		{Source = "Orc Warrior", Target = "OrcWarriorModel01"},
	},
	Bosses = {
		{Source = "Lava Golem", Target = "LavaTitanModel01"},
		{Source = "Iron Golem", Target = "FrostGiantModel01"},
		{Source = "Alpha Wolf", Target = "StormColossusModel01"},
		{Source = "Orc Smasher", Target = "MountainGuardianModel01"},
	},
	WorldProps = {
		{Root = "Nature Artifacts", Source = "Crystal 2", Target = "FireCrystalProp01"},
		{Root = "Nature Artifacts", Source = "Ice Crystal", Target = "IceCrystalProp01"},
		{Root = "Nature Artifacts", Source = "Cave Crystals", Target = "StormCrystalProp01"},
		{Root = "Nature Artifacts", Source = "Crystal", Target = "EarthCrystalProp01"},
		{Root = "Altars", Source = "Altar of Doom", Target = "FireAltarProp01"},
		{Root = "Altars", Source = "Altar 2", Target = "IceAltarProp01"},
		{Root = "Altars", Source = "Altar", Target = "StormAltarProp01"},
		{Root = "Altars", Source = "Autumn Altar", Target = "EarthAltarProp01"},
		{Root = "Ancient Ruins", Source = "Stone Portal Ruins", Target = "PortalRuinsProp01"},
		{Root = "Art Items", Source = "Statue With Sword", Target = "HeroStatueProp01"},
		{Root = "Towers", Source = "Tower for Obby", Target = "RealmTowerProp01"},
	},
}

local SOURCE_ROOTS = {"Swords", "Weapons", "Mobs", "Nature Artifacts", "Art Items", "Towers", "Altars", "Ancient Ruins"}

local function normalizedName(value)
	return string.lower(string.gsub(tostring(value or ""), "[^%w]", ""))
end

local function findNamedDescendant(root, wantedName)
	if not root then return nil end
	local wanted = normalizedName(wantedName)
	if normalizedName(root.Name) == wanted then return root end
	for _, descendant in ipairs(root:GetDescendants()) do
		if normalizedName(descendant.Name) == wanted then return descendant end
	end
	return nil
end

local function removeExecutableContent(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if UNSAFE_CLASSES[descendant.ClassName] then descendant:Destroy() end
	end
end

local function makeArchivable(root)
	-- Toolbox assets frequently disable Archivable on the root or important nested
	-- meshes. Normalize it at runtime so approved visuals can always be cloned even
	-- when Studio's property editor or export workflow did not update the source.
	root.Archivable = true
	for _, descendant in ipairs(root:GetDescendants()) do descendant.Archivable = true end
end

local function removeForcedBlur(object)
	if object:IsA("BlurEffect") or object:IsA("DepthOfFieldEffect") then object:Destroy() end
end

local function sanitize(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if UNSAFE_CLASSES[descendant.ClassName] then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
		end
	end
end

local function asModel(source, targetName)
	local clone = source:Clone()
	local model
	if clone:IsA("Model") then
		model = clone
	else
		model = Instance.new("Model")
		for _, child in ipairs(clone:GetChildren()) do child.Parent = model end
		if clone:IsA("BasePart") then clone.Parent = model else clone:Destroy() end
	end
	sanitize(model)
	model.Name = targetName
	model.PrimaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not model.PrimaryPart then model:Destroy(); return nil end
	model:SetAttribute("ImportedAndSanitized", true)
	return model
end

function ImportedAssetService.Start()
	local assets = ReplicatedStorage:FindFirstChild("GameAssets")
	if not assets then return end
	local archive = ServerStorage:FindFirstChild("ImportedAssetArchive") or Instance.new("Folder")
	archive.Name = "ImportedAssetArchive"
	archive.Parent = ServerStorage

	-- Move every raw Toolbox pile out of the rendered world immediately.
	for _, rootName in ipairs(SOURCE_ROOTS) do
		-- Toolbox folders are commonly dropped beneath ImportQuarantine or another
		-- organizing folder. Direct-child-only lookup silently missed those models.
		local root = findNamedDescendant(workspace, rootName)
		if root then
			makeArchivable(root)
			removeExecutableContent(root)
			root.Parent = archive
		end
	end
	for _, object in ipairs(Lighting:GetDescendants()) do removeForcedBlur(object) end
	Lighting.DescendantAdded:Connect(removeForcedBlur)
	-- Repository-backed Toolbox sources live in ServerStorage, where scripts cannot
	-- execute. Remove them from the raw archive as well before cloning any visuals.
for _, sourceRoot in ipairs(archive:GetChildren()) do
		makeArchivable(sourceRoot)
		removeExecutableContent(sourceRoot)
	end

	for category, entries in pairs(IMPORT_MAP) do
		local destination = assets:FindFirstChild(category)
		if destination then
			for _, entry in ipairs(entries) do
				local sourceRoot = archive:FindFirstChild(entry.Root or (category == "Weapons" and "Swords" or "Mobs"))
				local source = findNamedDescendant(sourceRoot, entry.Source)
				if source and not destination:FindFirstChild(entry.Target) then
					makeArchivable(source)
					local model = asModel(source, entry.Target)
					if model then model.Parent = destination end
				end
			end
		end
	end

	workspace:SetAttribute("ImportedAssetsOrganized", true)
	local enemyContainer = assets:FindFirstChild("Enemies")
	workspace:SetAttribute("ImportedEnemyModelCount", enemyContainer and #enemyContainer:GetChildren() or 0)
	if enemyContainer and #enemyContainer:GetChildren() == 0 then
		warn("No imported enemy models were found. Export sanitized models to assets/models and map them in default.project.json for Rojo builds.")
	end
end

return ImportedAssetService
