local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local holder = replicatedStorage.holder
local mouse = localPlayer:GetMouse()
local runService = game:GetService("RunService")

runService.Heartbeat:Connect(function()
    if mouse.Target and mouse.Target:IsDescendantOf(workspace.Map.Enemies) then
        if (mouse.Target.Parent.ClassName == "Model") then
            local part = mouse.Target.Parent.PrimaryPart
            local model = mouse.Target.parent
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
        end
    end
end)