-- services
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local pathHandler = {}

function pathHandler:CreateBath(track) -- creates a path so that the enemmies only follow the track, allows for tracks to be dynamic.
    

    local waypoints
    local path = PathfindingService:CreatePath({
        Costs = {
            Track = math.huge
        }
    })
    local success, errorMessage = pcall(function()
        path:ComputeAsync(track.PathFollow.Start.Position, track.PathFollow.End.Position)
    end)

    if success and path.Status == Enum.PathStatus.Success then
		waypoints = path:GetWaypoints()
	end
    if not waypoints then return end
    local lastPosition = nil
    local newPosition = Vector3.new()
    workspace.Map.VisualisePath:ClearAllChildren()
    for _,v in next, waypoints do
        local p = Instance.new("Part")
        p.Size = Vector3.new(1,1,1)
        p.Anchored = true
        p.CanCollide = false
        if lastPosition then
            local differential = (v.Position - lastPosition)
            if math.abs(differential.X) < math.abs(differential.Z) then
                newPosition = Vector3.new(lastPosition.X, v.Position.Y, v.Position.Z)
            else
                newPosition = Vector3.new(v.Position.X, v.Position.Y, lastPosition.Z)
            end
        else
            newPosition = v.Position
        end
        
        p.CFrame = CFrame.new(newPosition)
        p.Parent = workspace.Map.VisualisePath
        lastPosition = newPosition
    end
end

return pathHandler