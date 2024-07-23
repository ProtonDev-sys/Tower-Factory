-- services
local replicatedStorage = game:GetService("ReplicatedStorage")
local modules = replicatedStorage.modules
local pathHandler = require(modules.pathingSystem.pathHandler)


pathHandler:CreateTrack(workspace.Map.Part, "Default")
