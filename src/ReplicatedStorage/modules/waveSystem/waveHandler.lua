local enemies = require(script.Parent.enemies)

local waveHandler = {}

waveHandler.enemies = {}

function waveHandler:moveEnemies()
    local to_remove = {}

    for index, enemy in next, self.enemies do
        warn(enemy)
        local currentPath = workspace.Map.Path[tostring(enemy.path)]
        local nextPath = workspace.Map.Path[tostring(enemy.path + 1)]
        local direction = (nextPath.Position - currentPath.Position).Unit
        local targetDistance = (nextPath.Position - currentPath.Position).Magnitude
        local currentDistance = (nextPath.Position - enemy.model.PrimaryPart.Position).Magnitude

        -- Calculate the velocity needed to move towards the next path point
        local velocity = direction * enemy.movementSpeed
        enemy.model.PrimaryPart.Force.Velocity = velocity

        -- Check if the enemy is close enough to the next path point to consider it reached
        if currentDistance < math.max(enemy.movementSpeed * 0.1, .8) then
            if enemy.path >= #workspace.Map.Path:GetChildren() - 1 then
                enemy.model:Destroy()
                table.insert(to_remove, index)
                break
            end

            enemy.path += 1
        else
            enemy.model.PrimaryPart.Velocity = velocity
        end

        enemy.distanceMagnitude = currentDistance
    end

    -- Clean up removed enemies
    for _, v in next, to_remove do
        table.remove(self.enemies, v)
    end
end

function waveHandler:tick()
    for _,v in next, self.enemies do
        v.ticksExisted += 1
    end
    self.moveEnemies(self)
end

function waveHandler:sendEnemy(enemy)
    local map = workspace.Map
    local newEnemey = enemies[enemy]
    local model = enemies[enemy].model:Clone()
    model.Parent = map.Enemies
    model.PrimaryPart.CFrame = map.Path["1"].CFrame
    model.PrimaryPart.Anchored = false
    local force = Instance.new("BodyVelocity")
    force.Parent = model.PrimaryPart
    force.Name = "Force"

    local bodyForce = Instance.new("BodyForce")
    bodyForce.Force = Vector3.new(0, model.PrimaryPart:GetMass() * workspace.Gravity, 0)
    bodyForce.Parent = model.PrimaryPart

    newEnemey.model = model
    newEnemey.ticksExisted = 0
    newEnemey.path = 1
    newEnemey.distanceMagnitude = math.huge
    table.insert(self.enemies, newEnemey)
end

return waveHandler