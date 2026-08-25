local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StoreService = {}

function StoreService.Start(itemConfig, inventoryService)
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("StoreRemote")
	remote.OnServerInvoke = function(player, action, payload)
		payload = type(payload) == "table" and payload or {}
		if action == "GetCatalog" then
			local catalog = {}
			for itemId, definition in pairs(itemConfig.Items) do
				if definition.BuyPrice then table.insert(catalog, {ItemId = itemId, Price = definition.BuyPrice}) end
			end
			table.sort(catalog, function(left, right) return left.Price < right.Price end)
			return {Success = true, Message = "Fort supply store", Catalog = catalog}
		elseif action == "Buy" then
			local success, message = inventoryService.Buy(player, tostring(payload.ItemId))
			return {Success = success, Message = message}
		elseif action == "Sell" then
			local success, message = inventoryService.Sell(player, tostring(payload.ItemId))
			return {Success = success, Message = message}
		end
		return {Success = false, Message = "Unknown store action"}
	end
end

return StoreService
