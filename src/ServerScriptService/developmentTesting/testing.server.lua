local replicatedStorage = game:GetService("ReplicatedStorage")
local remotes = replicatedStorage.remotes
local development = remotes.development

local modules = replicatedStorage.modules
local pathHandler = require(modules.pathingSystem.pathHandler)
local networkingService = require(replicatedStorage.modules.networkService.networkHandler)

local WHITELISTED_USERS = {
    4693178461
}

local function canUseDevelopmentRemotes(userid)
    for _,whitelisted_id in next, WHITELISTED_USERS do
        if whitelisted_id == userid then
            return true
        end
    end
    return false
end

networkingService:registerEvent("RemoteEvent", "resetPath", function(plr)
    if not canUseDevelopmentRemotes(plr.UserId) then
        plr:Kick()
    end
    workspace.Map.Path:ClearAllChildren()
    pathHandler:CreateTrack(workspace.Map.Part, "Default")
end)

local waveHandler = require(modules.waveSystem.waveHandler)

task.spawn(function()
    while task.wait() do
        waveHandler:tick()
    end
end)

function waveHandler:enemyReachEnd(enemy)
    replicatedStorage.inGameStats.towerHealth.Value -= enemy.health
    if replicatedStorage.inGameStats.towerHealth.Value <= 0 then
        warn("dead.")
    end
end

networkingService:registerEvent("RemoteEvent", "spawnEnemy", function(plr)
    if not canUseDevelopmentRemotes(plr.UserId) then
        plr:Kick()
    end
    waveHandler:sendWave(1)
end)


