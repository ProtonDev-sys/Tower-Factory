-- services
local replicatedStorage = game:GetService("ReplicatedStorage")
local modules = replicatedStorage.modules
local pathHandler = require(modules.pathingSystem.pathHandler)

while wait() do
    pathHandler:CreateBath(workspace.Map)
end