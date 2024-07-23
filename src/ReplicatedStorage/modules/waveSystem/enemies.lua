local replicatedStorage = game:GetService("ReplicatedStorage")
local enemies = replicatedStorage.Enemies

local enemies = {
    ["test"] = {
        ["name"] = "Testing enemy",
        ["health"] = 100,
        ["armor"] = 100,
        ["armorDamage"] = 0.8,
        ["ability"] = function(ctx)
            return
        end,
        ["abilityTime"] = 5,
        ["movementSpeed"] = 200,
        ["flying"] = false,
        ["model"] = enemies.test,
        ["boss"] = false
    }
}

return enemies