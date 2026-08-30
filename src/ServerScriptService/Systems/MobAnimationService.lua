local RunService = game:GetService("RunService")

local MobAnimationService = {}

local function addEnergyWings(model, root)
	local color = model:GetAttribute("AbilityColor") or Color3.fromRGB(170, 100, 255)
	local motors = {}
	for _, side in ipairs({-1, 1}) do
		local wing = Instance.new("WedgePart")
		wing.Name = side < 0 and "AnimatedLeftWing" or "AnimatedRightWing"
		wing.Size = Vector3.new(0.45, model:GetAttribute("LootTier") == "Boss" and 7 or 4.5, model:GetAttribute("LootTier") == "Boss" and 12 or 7)
		wing.Color, wing.Material, wing.Transparency = color, Enum.Material.Neon, 0.22
		wing.CanCollide, wing.CanTouch, wing.CanQuery, wing.Massless = false, false, false, true
		wing.CFrame, wing.Parent = root.CFrame, model
		local motor = Instance.new("Motor6D")
		motor.Name = side < 0 and "AnimatedLeftWingMotor" or "AnimatedRightWingMotor"
		motor.Part0, motor.Part1 = root, wing
		motor.C0 = CFrame.new(side * 2.2, 2.2, 1.5) * CFrame.Angles(math.rad(-8), side < 0 and math.pi or 0, side * math.rad(34))
		motor.Parent = root
		table.insert(motors, {Joint = motor, Side = side})
	end
	return motors
end

function MobAnimationService.Start(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return end
	local limbMotors = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Motor6D") and string.sub(descendant.Name, 1, 14) == "EnemyLimbMotor" then
			table.insert(limbMotors, descendant)
		end
	end
	local wings = model:GetAttribute("AnimatedWings") and addEnergyWings(model, root) or {}
	local visualMotor = model:FindFirstChild("EnemyFlightMotor", true) or model:FindFirstChild("EnemyVisualMotor", true)
	local started = os.clock()
	local role = model:GetAttribute("CombatRole") or "Melee"
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not model.Parent or humanoid.Health <= 0 then
			connection:Disconnect()
			return
		end
		local elapsed = os.clock() - started
		local moving = root.AssemblyLinearVelocity.Magnitude > 2
		local state = model:GetAttribute("AIState")
		local strideRate = role == "Skirmisher" and 12 or role == "Bruiser" and 6.5 or 9
		local stride = moving and math.sin(elapsed * strideRate) or math.sin(elapsed * 2.5) * 0.12
		for _, motor in ipairs(limbMotors) do
			local opposite = string.find(motor.Name, "Right", 1, true) and -1 or 1
			local amount = string.find(motor.Name, "Arm", 1, true) and 0.48 or 0.38
			if state == "Attacking" and string.find(motor.Name, "Arm", 1, true) then
				amount = role == "Archer" and 0.78 or role == "Bruiser" and 1.2 or 1.05
			end
			motor.Transform = CFrame.Angles(opposite * stride * amount, 0, 0)
		end
		if visualMotor then
			local bob = model:GetAttribute("FlyingEnemy") and math.sin(elapsed * 3.4) * 0.45 or (moving and math.abs(math.sin(elapsed * 9)) * 0.12 or 0)
			local attackPose = CFrame.identity
			if state == "Attacking" then
				attackPose = role == "Archer" and CFrame.new(0, 0, 0.25) * CFrame.Angles(math.rad(-12), 0, 0)
					or role == "Bruiser" and CFrame.new(0, -0.22, -0.35) * CFrame.Angles(math.rad(24), 0, 0)
					or role == "Champion" and CFrame.Angles(0, math.sin(elapsed * 10) * 0.2, math.rad(-12))
					or CFrame.new(0, 0, -0.3) * CFrame.Angles(math.rad(10), 0, 0)
			end
			visualMotor.Transform = attackPose * CFrame.new(0, bob, 0) * CFrame.Angles(0, 0, moving and math.sin(elapsed * strideRate) * (role == "Bruiser" and 0.06 or 0.035) or 0)
		end
		for _, wing in ipairs(wings) do
			local flap = math.sin(elapsed * 8.5) * math.rad(42)
			wing.Joint.Transform = CFrame.Angles(0, 0, wing.Side * flap)
		end
	end)
end

return MobAnimationService
