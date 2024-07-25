local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local holder = replicatedStorage.holder
local mouse = localPlayer:GetMouse()
local runService = game:GetService("RunService")
local modules = replicatedStorage.modules
local networkingService = require(modules.networkService.networkHandler)

repeat task.wait() until game:IsLoaded()
wait(2)

local enemyData = {}
networkingService:registerEvent("RemoteEvent", "requestEnemyData", function(receivedEnemyData)
    enemyData = receivedEnemyData
end)

local lastupdate = tick()
local function updateData(model)
    if tick() - lastupdate > 0.1 then
        networkingService:getEvent("requestEnemyData"):FireServer(model)
        lastupdate = tick()
    end
end

runService.Heartbeat:Connect(function()
    if mouse.Target and mouse.Target:IsDescendantOf(workspace.Map.Enemies) then
        if (mouse.Target.Parent.ClassName == "Model") then
            local part = mouse.Target.Parent.PrimaryPart
            local model = mouse.Target.parent
            updateData(model)
            if not part:FindFirstChild("testingOverlay") then
                local overlay = holder.testingOverlay:Clone()
                overlay.Parent = part
                task.spawn(function()
                    while mouse.Target and mouse.Target.Parent == model do
                        task.wait()
                    end
                    overlay:Destroy()
                end)
            end
            if enemyData.health then
                part:FindFirstChild("testingOverlay").Frame.TextLabel.Text = tostring(enemyData.health) .. " / " .. tostring(enemyData.maxHealth)
            end
        end
    end
end)