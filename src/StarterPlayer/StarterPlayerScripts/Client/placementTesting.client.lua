local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local screenGui = localPlayer:WaitForChild("PlayerGui")
local testing = screenGui:WaitForChild("testing")
local testPlacingButton = testing:WaitForChild("TextButton")
local testPathButton = testing:WaitForChild("TextButton2")
local testSpawnEnemyButton = testing:WaitForChild("TextButton3")

local module = require(game.ReplicatedStorage.modules.placementSystem.placementHandler)

local replicatedStorage = game:GetService("ReplicatedStorage")
local remotes = replicatedStorage.remotes
local development = remotes.development
local resetPath = development.resetPath
local spawnEnemy = development.spawnEnemy

local placement = module.new(
	2,
	replicatedStorage.placeableItems,
	Enum.KeyCode.B,
	Enum.KeyCode.R,
	Enum.KeyCode.B
)

local placing = false


testPlacingButton.MouseButton1Click:Connect(function()
	placement:activate("crate", workspace.Map.Part.itemHolder, workspace.Map.Part, false)
end)

testPathButton.MouseButton1Click:Connect(function()
	resetPath:FireServer()
end)

testSpawnEnemyButton.MouseButton1Click:Connect(function()
	spawnEnemy:FireServer()
end)

local m = game.Players.LocalPlayer:GetMouse()
m.Button1Down:Connect(function()
	placement:place(game.ReplicatedStorage.remotes.placementSystem.place)
end)