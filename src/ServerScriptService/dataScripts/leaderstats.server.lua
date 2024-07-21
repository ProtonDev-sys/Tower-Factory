local dataStoreService = game:GetService("DataStoreService")

local players = game:GetService("Players")

local DEFAULT_DATA = {}

local function getPlayerData(player)
	local data = dataStoreService:GetDataStore(tostring(player.UserId))
	return data or DEFAULT_DATA
end

