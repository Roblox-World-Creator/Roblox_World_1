local PathfindingService = game:GetService("PathfindingService")

local PathfindingBudget = {}

local configured = false
local maximumPerSecond = 12
local maximumConcurrent = 3
local activeRequests = 0
local recentRequests = {}

function PathfindingBudget.Configure(config)
	if configured then
		return
	end
	configured = true
	maximumPerSecond = config.PathRequestsPerSecond or maximumPerSecond
	maximumConcurrent = config.PathMaximumConcurrent or maximumConcurrent
end

local function prune(now)
	while recentRequests[1] and now - recentRequests[1] >= 1 do
		table.remove(recentRequests, 1)
	end
end

function PathfindingBudget.Compute(startPosition, goalPosition)
	while true do
		local now = os.clock()
		prune(now)
		if activeRequests < maximumConcurrent and #recentRequests < maximumPerSecond then
			activeRequests += 1
			table.insert(recentRequests, now)
			break
		end
		task.wait(0.05)
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 6,
		AgentCanJump = true,
		AgentCanClimb = true,
		WaypointSpacing = 6,
	})
	local success = pcall(function()
		path:ComputeAsync(startPosition, goalPosition)
	end)
	activeRequests -= 1
	if success and path.Status == Enum.PathStatus.Success then
		return path:GetWaypoints()
	end
	return {}
end

return PathfindingBudget
