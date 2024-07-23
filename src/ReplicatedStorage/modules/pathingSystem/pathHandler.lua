-- services
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local pathHandler = {}

local function getBoundingBoxPart(part)
    local minVector = Vector3.new(math.huge, math.huge, math.huge)
	local maxVector = Vector3.new(-math.huge, -math.huge, -math.huge)

    local cf = part.CFrame
    local size = part.Size
    local halfSize = size / 2

    local corners = {
        cf * Vector3.new(-halfSize.X, -halfSize.Y, -halfSize.Z),
        cf * Vector3.new(-halfSize.X, -halfSize.Y,  halfSize.Z),
        cf * Vector3.new(-halfSize.X,  halfSize.Y, -halfSize.Z),
        cf * Vector3.new(-halfSize.X,  halfSize.Y,  halfSize.Z),
        cf * Vector3.new( halfSize.X, -halfSize.Y, -halfSize.Z),
        cf * Vector3.new( halfSize.X, -halfSize.Y,  halfSize.Z),
        cf * Vector3.new( halfSize.X,  halfSize.Y, -halfSize.Z),
        cf * Vector3.new( halfSize.X,  halfSize.Y,  halfSize.Z)
    }

    for _, corner in ipairs(corners) do
        minVector = Vector3.new(
            math.min(minVector.X, corner.X),
            math.min(minVector.Y, corner.Y),
            math.min(minVector.Z, corner.Z)
        )

        maxVector = Vector3.new(
            math.max(maxVector.X, corner.X),
            math.max(maxVector.Y, corner.Y),
            math.max(maxVector.Z, corner.Z)
        )
    end
    return minVector, maxVector
end

local bad_position = {}
local path = {}
local visited = {}
local depth = 0
local GRID_SPACING = 4

local function shuffle(tabl)
    for i=1,#tabl-1 do
        local ran = math.random(i,#tabl)
        tabl[i],tabl[ran] = tabl[ran],tabl[i]
    end
end

local function deepEqual(tbl1, tbl2)
    if tbl1 == tbl2 then
        return true
    end

    if type(tbl1) ~= "table" or type(tbl2) ~= "table" then
        return false
    end

    local keys1 = {}
    local keys2 = {}

    for k in pairs(tbl1) do
        keys1[k] = true
    end

    for k in pairs(tbl2) do
        keys2[k] = true
    end

    for k in pairs(keys1) do
        if not deepEqual(tbl1[k], tbl2[k]) then
            return false
        end
    end

    for k in pairs(keys2) do
        if not deepEqual(tbl1[k], tbl2[k]) then
            return false
        end
    end

    return true
end

local didntWork = {}
local path = {}
local visited = {}
local function isValidMove(gridSize, newPosition, visited)
    for _, v in pairs(didntWork) do
        if v == newPosition then
            return false
        end
    end
    if newPosition.X < 0 or newPosition.X >= gridSize or newPosition.Y < 0 or newPosition.Y >= gridSize then
        return false
    end
    for _, v in pairs(visited) do
        if v == newPosition then
            return false
        end
    end
    return true
end

function randomiseDict(originalDict)
	local cloneDictionary = {}
	local newDictionary	= {}
	
	for _, v in pairs(originalDict) do
		table.insert(cloneDictionary, v)
	end
	for i, v in pairs(originalDict) do
		local Index = math.random(1, #cloneDictionary)
		
		newDictionary[i] = cloneDictionary[Index]
		table.remove(cloneDictionary, Index)
	end
	
	return newDictionary
end

local function dfs(gridSize, currentPosition, exit, visited, path, lastDirection, timesLastDirectionRepeated)
    if not timesLastDirectionRepeated then
        timesLastDirectionRepeated = 1
    end
    if currentPosition == exit then
        table.insert(path, currentPosition)
        return true
    end

    table.insert(visited, currentPosition)
    table.insert(path, currentPosition)
    
    -- Randomize the directions to ensure a random path
    local directions = {
        ["A"] = Vector2.new(currentPosition.X+1, currentPosition.Y),
        ["B"] = Vector2.new(currentPosition.X, currentPosition.Y-1),
        ["C"] = Vector2.new(currentPosition.X, currentPosition.Y+1),
        ["D"] = Vector2.new(currentPosition.X-1, currentPosition.Y)
    }

    directions = randomiseDict(directions)

    if lastDirection and math.random(1,100) <= 100-timesLastDirectionRepeated and isValidMove(gridSize, directions[lastDirection], visited) then
        local tmp = directions
        directions = {
            [lastDirection] = tmp[lastDirection]
        }
    end

    for key, newPosition in next, directions do
        if isValidMove(gridSize, newPosition, visited) then
            -- Ensure the new position is not directly adjacent to more than one part of the path
            local adjacents = {
                Vector2.new(newPosition.X-1, newPosition.Y),
                Vector2.new(newPosition.X+1, newPosition.Y),
                Vector2.new(newPosition.X, newPosition.Y-1),
                Vector2.new(newPosition.X, newPosition.Y+1)
            }
            local adjacentCount = 0
            for _, adj in pairs(adjacents) do
                for _, v in pairs(visited) do
                    if v == adj then
                        adjacentCount = adjacentCount + 1
                    end
                end
            end
            
            if adjacentCount <= 1 then
                if dfs(gridSize, newPosition, exit, visited, path, key, key == lastDirection and timesLastDirectionRepeated+1 or 1) then
                    return true
                end
            end
        end
    end

    -- Backtrack
    table.remove(path)
    table.remove(visited)
    table.insert(didntWork, currentPosition)
    return false
end

local function convertVectorToTrackVector(vector, track)
    if type(vector) == "userdata" then -- vector2
        return Vector3.new(
            vector.X*GRID_SPACING + track.Position.X - (track.Size.X/2) + (GRID_SPACING/2),
            track.Position.Y + 0.5,
            vector.Y*GRID_SPACING + track.Position.Z - (track.Size.Z/2) + (GRID_SPACING/2)
        )
    elseif type(vector) == "vector" then -- vector3
        return Vector3.new(
            vector.X*GRID_SPACING + track.Position.X - (track.Size.X/2) + (GRID_SPACING/2),
            track.Position.Y + 0.5,
            vector.Z*GRID_SPACING + track.Position.Z - (track.Size.Z/2) + (GRID_SPACING/2)
        )
    end
end

local function visualizePath(waypoints, track, pathType)
    local pathFollow = track.Parent.PathFollow
    pathFollow.Start.CFrame = CFrame.new(waypoints[#waypoints].X, pathFollow.Start.Position.Y, waypoints[#waypoints].Y)
    pathFollow.End.CFrame = CFrame.new(waypoints[#waypoints].X, pathFollow.End.Position.Y, waypoints[#waypoints].Y)
    
    for i, waypoint in next, waypoints do
        local convertedVector = convertVectorToTrackVector(waypoint, track)
        local pathPart = ReplicatedStorage.Paths[pathType]:Clone()
        if i == 1 then
            pathFollow.Start.Size = Vector3.new(GRID_SPACING, 6, GRID_SPACING)
            pathFollow.Start.CFrame = CFrame.new(convertedVector.X, pathFollow.Start.Position.Y, convertedVector.Z - GRID_SPACING)
            pathPart.Color = Color3.fromRGB(0,255,0)
        elseif i == #waypoints then
            pathFollow.End.Size = Vector3.new(GRID_SPACING, 6, GRID_SPACING)
            pathFollow.End.CFrame = CFrame.new(convertedVector.X, pathFollow.Start.Position.Y, convertedVector.Z + GRID_SPACING)
            pathPart.Color = Color3.fromRGB(255,0,0)
        end
        
        pathPart.Parent = track.Parent.Path
        pathPart.Size = Vector3.new(GRID_SPACING,0.2,GRID_SPACING) 
        pathPart.Position = convertedVector
        pathPart.Anchored = true
        pathPart.Name = i
    end
end

function pathHandler:CreateTrack(track, pathType)
    local gridSize = track.Size.X // GRID_SPACING
    visited = {}
    path = {}
    didntWork = {}
    while #path == 0 do
        dfs(gridSize, Vector2.new(math.random(1,gridSize-1),0), Vector2.new(math.random(1,gridSize-1), gridSize-1), visited, path)
        if #path == 0 then
            visited = {}
            didntWork = {}
        end
        task.wait()
    end
    print(path)
    print(visited)
    visualizePath(path, track, pathType)
    return
end

function pathHandler:GetAIPath(track) -- creates a path so that the enemmies only follow the track, allows for tracks to be dynamic.
    local waypoints
    local path = PathfindingService:CreatePath({
        Costs = {
            Track = math.huge,
            WalkHere = -math.huge
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