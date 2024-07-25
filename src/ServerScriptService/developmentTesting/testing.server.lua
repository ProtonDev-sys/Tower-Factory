local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local remotes = replicatedStorage.remotes
local development = remotes.development

local modules = replicatedStorage.modules
local pathHandler = require(modules.pathingSystem.pathHandler)
local networkingService = require(replicatedStorage.modules.networkService.networkHandler)
local towers = require(modules.towers.towers)

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

networkingService:registerEvent("RemoteEvent", "requestEnemyData", function(player, enemy)
    for _,v in next, waveHandler.enemies do
        if v.model == enemy then
            networkingService:getEvent("requestEnemyData"):FireClient(player, v)
        end
    end
end)


local towercoolDowns = {}

RunService.Heartbeat:Connect(function()
    for _,tower in next, workspace.Map.Part.itemHolder:GetChildren() do
        for _,enemy in next, waveHandler.enemies do
            if (enemy.model.PrimaryPart.Position - tower.PrimaryPart.Position).Magnitude <= towers[tower.Name].range then
                if (not towercoolDowns[tower]) or ((tick() - towercoolDowns[tower])*1000 > towers[tower.Name].cooldown) then
                    local data = towers[tower.Name]
                    waveHandler:damageEnemey(enemy, data.damage)
                    towercoolDowns[tower] = tick()
                end
            end
        end
    end
end)