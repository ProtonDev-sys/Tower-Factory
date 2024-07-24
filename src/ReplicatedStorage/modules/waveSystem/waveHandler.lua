local enemies = require(script.Parent.enemies)
local waves = require(script.Parent.waves)

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
                    enemy.model.PrimaryPart.Position = Vector3.new(nextPath.Position.X, enemy.model.PrimaryPart.Position.Y, nextPath.Position.Z)
                    if enemy.path >= #workspace.Map.Path:GetChildren() - 1 then
                        self:enemyReachEnd(self.enemies[index])
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
                    newEnemyPosition = Vector3.new(newEnemyPosition.X, enemy.model.PrimaryPart.Position.Y, newEnemyPosition.Z)
                    enemy.model.PrimaryPart.Position = newEnemyPosition
                    enemy.model.PrimaryPart.Force.Velocity = velocity
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

function waveHandler:enemyReachEnd(enemy)
    return
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

function waveHandler:sendWave(waveNumber)
    task.spawn(function() -- we want this to happen in the background so that other tasks can continue too.
        local startTick = tick() * 1000
        local toSend = {}
        local sending = {}
        for _,v in next, waves[waveNumber] do
            table.insert(toSend, v)
        end
        while true do
            local cleanup = {}
            for tickRequired,enemyArray in next, toSend do
                if not sending[tickRequired] and (tick() * 1000) - startTick >= tickRequired then
                    sending[tickRequired] = true
                    task.spawn(function(enemyArray) -- spawn all the enemy with correct spacing set.
                        local spacing = enemyArray.spacing
                        local amount = enemyArray.amount
                        local id = enemyArray.id
                        local lastTick = startTick
                        while amount >= 0 do
                            local currentTick = tick() * 1000
                            if (currentTick-lastTick) >= spacing then
                                amount -= 1
                                lastTick = currentTick
                                self:sendEnemy(id)
                            else
                                task.wait()
                            end
                        end
                        table.insert(cleanup, tickRequired)
                    end, enemyArray)
                end
            end
            task.wait()
        end
    end)
end

function waveHandler:sendEnemy(enemy)
    local map = workspace.Map
    local newEnemey = deepCopy(enemies[enemy])

    local model = enemies[enemy].model:Clone()
    model.Parent = map.Enemies
    model.PrimaryPart.CFrame = map.Path["1"].CFrame + Vector3.new(0,1,0)
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
    table.insert(self.enemies, newEnemey)
end

return waveHandler