local enemies = require(script.Parent.enemies)

local waveHandler = {}

waveHandler.enemies = {}

function waveHandler:moveEnemies()
    for index = #self.enemies, 1, -1 do
        local enemy = self.enemies[index]
    
        local currentPath = workspace.Map.Path[tostring(enemy.path)]
        local nextPath = workspace.Map.Path[tostring(enemy.path + 1)]
        task.spawn(function()
            while true do
                if not enemy.model or not enemy.model.PrimaryPart then
                    break
                end
                local direction = (nextPath.Position - currentPath.Position).Unit
                local enemyPosition = enemy.model.PrimaryPart.Position

                local velocity = direction * enemy.movementSpeed
                local step = velocity * (game:GetService("RunService").Heartbeat:Wait())
                local newEnemyPosition = enemyPosition + step

                local toCurrent = newEnemyPosition - currentPath.Position
                local toNext = nextPath.Position - currentPath.Position
                local projection = toCurrent:Dot(toNext.Unit)

                if projection > toNext.Magnitude then
                    enemy.model.PrimaryPart.Position = nextPath.Position
                    if enemy.path >= #workspace.Map.Path:GetChildren() - 1 then
                        enemy.model:Destroy()
                        table.remove(self.enemies, index)
                        break
                    end
                    
                    enemy.path += 1
                    currentPath = workspace.Map.Path[tostring(enemy.path)]
                    nextPath = workspace.Map.Path[tostring(enemy.path + 1)]
                else
                    if not enemy.model.PrimaryPart or not nextPath then
                        break
                    end
                    enemy.model.PrimaryPart.Position = newEnemyPosition
                    enemy.model.PrimaryPart.Velocity = velocity
                    break
                end
            end
        end)
    end
end

function waveHandler:tick()
    for _,v in next, self.enemies do
        v.ticksExisted += 1
    end
    self.moveEnemies(self)
end

local function deepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end


function waveHandler:sendEnemy(enemy)
    local map = workspace.Map
    local newEnemey = deepCopy(enemies[enemy])
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