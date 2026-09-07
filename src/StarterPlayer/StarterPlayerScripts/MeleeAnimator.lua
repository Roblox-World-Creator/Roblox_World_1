local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.MeleeConfig)
local MeleeAnimator = {}
local active = {}
local connection

local function stop(character)
	local state = active[character]
	if not state then return end
	for _, joint in ipairs(state.Joints) do
		if joint.Motor.Parent then joint.Motor.Transform = joint.Rest end
	end
	for _, trail in ipairs(state.Trails) do if trail.Parent then trail.Enabled = false end end
	active[character] = nil
end

function MeleeAnimator.Play(character, combo, style, moveId)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	stop(character)
	local move = moveId and Config.Moves[moveId]
	local sign = combo % 2 == 0 and -1 or 1
	local windup = move and move.Windup or Config.Animation.Windup
	local duration = move and move.Duration or windup + Config.Animation.Strike + Config.Animation.Recovery
	local state = {Started = os.clock(), Duration = duration, Windup = windup, MoveId = moveId, Joints = {}, Trails = {}, Humanoid = humanoid}
	local function joint(names, from, to)
		local motor
		for _, name in ipairs(names) do motor = character:FindFirstChild(name, true); if motor then break end end
		if motor and motor:IsA("Motor6D") then table.insert(state.Joints, {Motor = motor, Rest = motor.Transform, From = from, To = to}) end
	end
	local heavy = moveId == "Cleave" or style == "Hammer" or style == "Greatsword" or combo == 4
	local thrust = moveId == "Lunge" or style == "Spear"
	local shoulderFrom = heavy and CFrame.Angles(-2.1, 0, 0.25) or CFrame.Angles(-0.8, sign * -0.6, sign * 0.9)
	local shoulderTo = heavy and CFrame.Angles(-0.25, 0, -0.15) or CFrame.Angles(-1.1, sign * 0.7, sign * -0.6)
	if thrust then shoulderFrom, shoulderTo = CFrame.Angles(-0.5, 0, 0.5), CFrame.Angles(-1.6, 0, 0) end
	joint({"RightShoulder", "Right Shoulder"}, shoulderFrom, shoulderTo)
	joint({"RightElbow"}, CFrame.Angles(0.7, 0, 0), CFrame.Angles(0.1, 0, 0))
	joint({"LeftShoulder", "Left Shoulder"}, CFrame.Angles(-0.4, 0, -0.25), CFrame.Angles(-0.8, 0, 0.2))
	joint({"Waist", "RootJoint"}, CFrame.Angles(0, -sign * 0.35, 0), CFrame.Angles(heavy and 0.2 or 0, sign * 0.45, 0))
	joint({"SwordGrip"}, CFrame.Angles(thrust and -1.2 or -0.2, 0, sign * 0.35), CFrame.Angles(thrust and -1.45 or 0.2, 0, -sign * 0.4))
	if moveId == "Whirlwind" then
		joint({"Root"}, CFrame.identity, CFrame.Angles(0, math.pi * 1.8, 0))
	end
	local visuals = character:FindFirstChild("EquippedItemVisuals")
	if visuals then
		for _, object in ipairs(visuals:GetDescendants()) do
			if object:IsA("Trail") then object.Enabled = false; table.insert(state.Trails, object) end
		end
	end
	active[character] = state
	if connection then return end
	-- Animator writes Transform after PreAnimation. Apply attack poses after that
	-- write, immediately before simulation, so R6/R15 swings cannot be overwritten.
	connection = RunService.PreSimulation:Connect(function()
		for model, animation in pairs(active) do
			local elapsed = os.clock() - animation.Started
			if not model.Parent or animation.Humanoid.Health <= 0 or elapsed >= animation.Duration then stop(model); continue end
			local strikeEnd = math.min(animation.Duration - 0.1, animation.Windup + (animation.MoveId == "Whirlwind" and 0.4 or Config.Animation.Strike))
			for _, pose in ipairs(animation.Joints) do
				if not pose.Motor.Parent then continue end
				local transform
				if elapsed < animation.Windup then
					local alpha = elapsed / animation.Windup
					transform = CFrame.identity:Lerp(pose.From, alpha * alpha * (3 - 2 * alpha))
				elseif elapsed < strikeEnd then
					local alpha = (elapsed - animation.Windup) / (strikeEnd - animation.Windup)
					transform = pose.From:Lerp(pose.To, 1 - (1 - alpha) ^ 3)
				else
					transform = pose.To:Lerp(CFrame.identity, (elapsed - strikeEnd) / (animation.Duration - strikeEnd))
				end
				pose.Motor.Transform = pose.Rest * transform
			end
			for _, trail in ipairs(animation.Trails) do if trail.Parent then trail.Enabled = elapsed >= animation.Windup and elapsed < strikeEnd end end
		end
		if next(active) == nil then connection:Disconnect(); connection = nil end
	end)
end

return MeleeAnimator
