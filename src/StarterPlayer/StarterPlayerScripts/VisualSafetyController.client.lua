local Lighting = game:GetService("Lighting")

local function removeForcedBlur(object)
	if object:IsA("BlurEffect") or object:IsA("DepthOfFieldEffect") then
		object:Destroy()
	end
end

local function clean(container)
	if not container then return end
	for _, object in ipairs(container:GetDescendants()) do removeForcedBlur(object) end
	container.DescendantAdded:Connect(removeForcedBlur)
end

clean(Lighting)
clean(workspace.CurrentCamera)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	clean(workspace.CurrentCamera)
end)

