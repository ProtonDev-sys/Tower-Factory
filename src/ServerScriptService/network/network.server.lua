local replicatedStorage = game:GetService("ReplicatedStorage")
local modules = replicatedStorage.modules
local networkService = modules.networkService
local networkHandler = require(networkService.networkHandler)

networkHandler:registerEvent("RemoteEvent", "testing", function(player, ...)
    warn("gamer!!! ")
    print(player)
    warn(...)
end)