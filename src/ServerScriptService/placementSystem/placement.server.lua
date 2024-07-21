local replicatedStorage = game:GetService("ReplicatedStorage")

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

local function getBoundingBox(model)
	local minVector = Vector3.new(math.huge, math.huge, math.huge)
	local maxVector = Vector3.new(-math.huge, -math.huge, -math.huge)

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "coloredHitbox" then
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
		end
	end

	return minVector, maxVector
end

local function doBoundingBoxesIntersect(min1, max1, min2, max2, tolerance)
    tolerance = tolerance or 0
    return (min1.X <= max2.X - tolerance and max1.X >= min2.X + tolerance) and
           (min1.Y <= max2.Y - tolerance and max1.Y >= min2.Y + tolerance) and
           (min1.Z <= max2.Z - tolerance and max1.Z >= min2.Z + tolerance)
end

local function handleCollision(object, plot)
    if object then
        local collided = false
        local collisionPoint = object.PrimaryPart.Touched:Connect(function() end)
        local collisionPoints = object.PrimaryPart:GetTouchingParts()
        
        local objectMinVector, objectMaxVector = getBoundingBox(object)
        local checkedModels = {}
        local tolerance = 0.1
        for _, part in ipairs(collisionPoints) do
            local parentModel = part.Parent
            if not part:IsDescendantOf(object) and parentModel:IsDescendantOf(plot.itemHolder) and parentModel.ClassName == 'Model' then
                if not checkedModels[parentModel] then
                    checkedModels[parentModel] = true

                    local secondObjectMinVector, secondObjectMaxVector = getBoundingBox(parentModel)
                    if doBoundingBoxesIntersect(objectMinVector, objectMaxVector, secondObjectMinVector, secondObjectMaxVector, tolerance) then
                        collided = true
                        break
                    end
                end
            end
        end

        collisionPoint:Disconnect()
        return collided
    end
end

local function bounds(object, plot)
    local min1,max1 = getBoundingBox(object)
    min1 = Vector3.new(min1.X, 2, min1.Z)
    max1 = Vector3.new(max1.X, 2, max1.Z)
    local min2,max2 = getBoundingBoxPart(plot)
    min2 = Vector3.new(min2.X, 2, min2.Z)
    max2 = Vector3.new(max2.X, 2, max2.Z)
    local intersect = doBoundingBoxesIntersect(min1,max1,min2,max2)
    return intersect
end

local function place(player, id, placedObjects, cframe, plot)
    local item = replicatedStorage.placeableItems[id]:Clone()
    item:PivotTo(cframe)
    item.PrimaryPart.CanCollide = false
    if plot then
        item.Parent = placedObjects
        if handleCollision(item, plot) or not bounds(item, plot) then
            item:Destroy()
            return false
        end
    end
    return true
end

replicatedStorage.remotes.placementSystem.place.OnServerInvoke = place