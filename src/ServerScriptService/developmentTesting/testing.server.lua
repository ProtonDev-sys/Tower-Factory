local replicatedStorage = game:GetService("ReplicatedStorage")
local remotes = replicatedStorage.remotes
local development = remotes.development

local modules = replicatedStorage.modules
local pathHandler = require(modules.pathingSystem.pathHandler)

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

development.resetPath.onServerEvent:Connect(function(plr)
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
    warn("hello from testing server script ", enemy)
end

development.spawnEnemy.onServerEvent:Connect(function(plr)
    waveHandler:sendWave(1)
end)


