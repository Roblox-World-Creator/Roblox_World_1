local Players = game:GetService("Players")

local player = Players.LocalPlayer
local enemies = workspace:WaitForChild("Enemies")

local screen = Instance.new("ScreenGui")
screen.Name = "BossUI"
screen.ResetOnSpawn = false
screen.DisplayOrder = 105
screen.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.58, 0, 0, 62)
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.Position = UDim2.new(0.5, 0, 0, 22)
frame.BackgroundColor3 = Color3.fromRGB(24, 13, 24)
frame.BackgroundTransparency = 0.08
frame.Visible = false
frame.Parent = screen
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 80, 110)
stroke.Thickness = 2
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 25)
title.Position = UDim2.fromOffset(10, 3)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.Parent = frame

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, -20, 0, 21)
bar.Position = UDim2.fromOffset(10, 32)
bar.BackgroundColor3 = Color3.fromRGB(45, 25, 40)
bar.BorderSizePixel = 0
bar.Parent = frame
local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 6)
barCorner.Parent = bar
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = Color3.fromRGB(255, 65, 95)
fill.BorderSizePixel = 0
fill.Parent = bar
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 6)
fillCorner.Parent = fill
local value = Instance.new("TextLabel")
value.Size = UDim2.fromScale(1, 1)
value.BackgroundTransparency = 1
value.TextColor3 = Color3.new(1, 1, 1)
value.Font = Enum.Font.GothamBold
value.TextSize = 14
value.Parent = bar

local currentBoss
local healthConnection
local phaseConnection

local function hideBoss(boss)
	if currentBoss ~= boss then
		return
	end
	currentBoss = nil
	frame.Visible = false
	if healthConnection then
		healthConnection:Disconnect()
		healthConnection = nil
	end
	if phaseConnection then
		phaseConnection:Disconnect()
		phaseConnection = nil
	end
end

local function showBoss(boss)
	if currentBoss == boss or not boss:GetAttribute("BossWave") then
		return
	end
	local humanoid = boss:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	currentBoss = boss
	frame.Visible = true
	local function refresh()
		local phase = boss:GetAttribute("BossPhase") or 1
		title.Text = string.format("%s  •  PHASE %d", humanoid.DisplayName, phase)
		fill.Size = UDim2.fromScale(math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1), 1)
		value.Text = string.format("%d / %d", math.ceil(humanoid.Health), math.ceil(humanoid.MaxHealth))
		fill.BackgroundColor3 = phase >= 3 and Color3.fromRGB(210, 45, 255) or Color3.fromRGB(255, 65, 95)
	end
	healthConnection = humanoid.HealthChanged:Connect(refresh)
	phaseConnection = boss:GetAttributeChangedSignal("BossPhase"):Connect(refresh)
	boss.AncestryChanged:Connect(function(_, parent)
		if not parent then
			hideBoss(boss)
		end
	end)
	refresh()
end

local function inspect(enemy)
	task.defer(function()
		if enemy.Parent then
			showBoss(enemy)
			if not enemy:GetAttribute("BossWave") then
				enemy:GetAttributeChangedSignal("BossWave"):Once(function()
					showBoss(enemy)
				end)
			end
		end
	end)
end

enemies.ChildAdded:Connect(inspect)
for _, enemy in ipairs(enemies:GetChildren()) do
	inspect(enemy)
end
