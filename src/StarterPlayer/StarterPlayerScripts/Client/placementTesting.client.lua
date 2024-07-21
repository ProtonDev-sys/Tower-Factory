local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local screenGui = localPlayer:WaitForChild("PlayerGui")
local testing = screenGui:WaitForChild("testing")
local button = testing:WaitForChild("TextButton")

local module = require(game.ReplicatedStorage.modules.placementSystem.placementHandler)

local placement = module.new(
	2,
	game.ReplicatedStorage.placeableItems,
	Enum.KeyCode.B,
	Enum.KeyCode.R,
	Enum.KeyCode.B
)

local placing = false


button.MouseButton1Click:Connect(function()
	if not placing then
		placing = true
		placement:activate("crate", workspace.Map.Part.itemHolder, workspace.Map.Part, false)
	end
end)

local m = game.Players.LocalPlayer:GetMouse()
m.Button1Down:Connect(function()
	placement:place(game.ReplicatedStorage.remotes.placementSystem.place)
end)