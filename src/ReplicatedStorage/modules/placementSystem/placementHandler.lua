-- Settings

local interpolation = true
local moveByGrid = true
local buildModePlacement = true

local rotationStep = 90
local maxHeight = 90

local lerpLevel = 0.6

local gridTexture = "rbxassetid://2415319308"
local placement = {}
placement.__index = placement

local players = game:GetService("Players")
local runService = game:GetService("RunService")
local contextActionService = game:GetService("ContextActionService")

local player = players.LocalPlayer
local mouse = player:GetMouse()

-- constructor variables

local GRID_SIZE
local ITEM_LOCATION
local PLACEMENT_MODE 
local ROTATE_KEY
local TERIMAMTE_KEY

-- activation variables
local object
local placedObjects
local plot
local stackable

-- calculation variables
local posX, posY, posZ
local speed = 1
local rotation = 0
local rotatedValue = false

-- other
local collided = nil

local function renderGrid()
	local texture = Instance.new("Texture")
	texture.StudsPerTileU = GRID_SIZE
	texture.StudsPerTileV = GRID_SIZE
	texture.Texture = gridTexture
	texture.Face = Enum.NormalId.Top
	texture.Parent = plot
end

local function changeHitboxColor()
	if object and object.PrimaryPart then
		object.coloredhitbox.Transparency = 0.8
		if collided then
			object.coloredhitbox.Color = Color3.fromRGB(255, 66, 66)
		else
			object.coloredhitbox.Color = Color3.fromRGB(66, 255, 66)
		end
	end
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


local function handleCollision()
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


local function bounds(cframe, offsetX, offsetZ)
	local LOWER_X_BOUND
	local LOWER_Z_BOUND
	local UPPER_X_BOUND
	local UPPER_Z_BOUND

	LOWER_X_BOUND = plot.Position.X - (plot.Size.X*0.5) + offsetX
	LOWER_Z_BOUND = plot.Position.Z - (plot.Size.Z*0.5) + offsetZ
	UPPER_X_BOUND = plot.Position.X + (plot.Size.X*0.5) - offsetX
	UPPER_Z_BOUND = plot.Position.Z + (plot.Size.Z*0.5) - offsetZ
	
	local newX = math.clamp(cframe.Position.X, LOWER_X_BOUND, UPPER_X_BOUND)
	local newZ = math.clamp(cframe.Position.Z, LOWER_Z_BOUND, UPPER_Z_BOUND)

	return CFrame.new(newX, posY, newZ)
end

local function calculateYPosition(toPosition, toSize, objectSize)
	return (toPosition + toSize * 0.5) + objectSize*0.5
end

local function rotate(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		rotation += rotationStep
		rotatedValue = not rotatedValue
	end
end

local function cancelPlacement(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		object:Destroy()
		if plot:FindFirstChild("Texture") then
			plot.Texture:Destroy()
		end
		mouse.TargetFilter = nil
	end
end

local function snap(c)
	local newX = math.round(c.X/GRID_SIZE) * GRID_SIZE
	local newZ = math.round(c.Z/GRID_SIZE) * GRID_SIZE	
	return CFrame.new(newX, 0, newZ)
end

local function calculateModelPosition()
	if not mouse.Target then
		return
	end
	
	local finalCFrame = CFrame.new()
	local x,z 
	local offsetX,offsetZ
	
	if rotatedValue then
		offsetX, offsetZ = object.PrimaryPart.Size.X*0.5, object.PrimaryPart.Size.Z*0.5
		x,z = mouse.Hit.X - offsetX, mouse.Hit.Z - offsetZ
	else
		offsetX, offsetZ = object.PrimaryPart.Size.Z*0.5, object.PrimaryPart.Size.X*0.5
		x,z = mouse.Hit.X - offsetX, mouse.Hit.Z - offsetZ
	end
	
	if stackable and mouse.Target and mouse.Target:IsDescendantOf(plot) then
		posY = calculateYPosition(mouse.Target.Position.Y, mouse.Target.Size.Y, object.PrimaryPart.Size.Y) 
	else
		posY = calculateYPosition(plot.Position.Y, plot.Size.Y, object.PrimaryPart.Size.Y) 
	end
	
	if moveByGrid then
		local plotCFrame = CFrame.new(plot.CFrame.X	, 0, plot.CFrame.Z)
		local pos = CFrame.new(x,0,z)
		pos = snap(pos*plotCFrame:Inverse())
		finalCFrame = pos*plotCFrame*CFrame.new(offsetX, 0, offsetZ)
	else
		finalCFrame = CFrame.new(mouse.Hit.X, posY, mouse.Hit.Z)
	end
	
	finalCFrame = bounds(CFrame.new(finalCFrame.X, posY, finalCFrame.Z), offsetX, offsetZ)
	
	return finalCFrame*CFrame.fromEulerAnglesXYZ(0, math.rad(rotation), 0)
end

local function bindInputs()
	contextActionService:BindAction("Rotate", rotate, false, ROTATE_KEY)
	contextActionService:BindAction("CancelPlacement", cancelPlacement, false, TERIMAMTE_KEY)
end

local function unbindInputs()
	contextActionService:UnbindAction("Rotate")
	contextActionService:UnbindAction("CancelPlacement")
end

local function translateObject()
	if placedObjects and object.Parent == placedObjects then
		object:PivotTo(object.PrimaryPart.CFrame:Lerp(calculateModelPosition(), speed))
		collided = handleCollision()
		changeHitboxColor()
	end
end

local function verifyPlane()
	return plot.Size.X % GRID_SIZE == 0 and plot.Size.Z % GRID_SIZE == 0
end

local function approvePlacement()
	if not verifyPlane() then
		warn("Cannot snap to plot.")
		return false
	end
	
	if GRID_SIZE > math.min(plot.Size.X, plot.Size.Z) then
		error("Grid size larger than plot.")
		return false
	end
	
	return true
end

-- constructor function
function placement.new(gridSize, objects, placementMode, rotateKey, terminateKey)
	local data = {}
	local metadata = setmetatable(data, placement)
		
	GRID_SIZE = gridSize
	ITEM_LOCATION = objects
	PLACEMENT_MODE = placementMode
	ROTATE_KEY = rotateKey
	TERIMAMTE_KEY = terminateKey
	
	data.grid = GRID_SIZE
	data.itemlocation = ITEM_LOCATION
	data.placementmode = PLACEMENT_MODE or Enum.KeyCode.B
	data.rotatekey = ROTATE_KEY or Enum.KeyCode.R
	data.terminatekey = TERIMAMTE_KEY or Enum.KeyCode.X
	
	return data
end

function placement:activate(id, placedobjs, plt, stack) -- name, placedObjects, plot, stackable
	if plt:FindFirstChild("Texture") then
		plt.Texture:Destroy()
		object:Destroy()
	end
	object = ITEM_LOCATION[id]:Clone()
	for _,v in next, object:GetDescendants() do
		if v:IsA("BasePart") then
			v.CanCollide = false
		end
	end
	placedObjects = placedobjs
	plot = plt
	stackable = stack
	rotation = 0
	rotatedValue = true
	
	if not approvePlacement() then
		return "Invalid placement."
	end
	
	-- Filter objects depending on if current placement is stackable
	if not stackable then
		mouse.TargetFilter = placedObjects
	else
		mouse.TargetFilter = object
	end
	
	local preSpeed = 1
	if interpolation then
		preSpeed = math.clamp(math.abs(tonumber(1- lerpLevel)), 0, 0.9)
		speed = 1
	end
	
	object.Parent = placedObjects
	
	task.wait()
	bindInputs()
	renderGrid()
	speed = preSpeed
end

function placement:place(remote)
	if not collided and object then
		remote:InvokeServer(object.Name, placedObjects, calculateModelPosition(), plot)
	end
end

runService:BindToRenderStep("Input", Enum.RenderPriority.Input.Value, translateObject)

return placement