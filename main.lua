local function roll()
    local args = {
        [1] = "PremRollSkin10"
    }
    game:GetService("ReplicatedStorage").RemoteFunction:InvokeServer(unpack(args))
end
 
-- sells all available skins
local function sell()
    local skins = {
        "Hot Pink", "Agent", "Checkered", "Grey Camo", "Rusted Red",
        "Green Camo", "Orange Crush", "Painted Yellow", "Painted Orange",
        "Damaged", "Earth", "Painted Blue", "Painted Green", "Painted Red", 
        "Painted Pink", "Painted Purple", "Green Sentry", "Pink Sentry", 
        "Red Sentry", "Royal", "Fallen Agent"
    }
    local guns = {"SMG", "LMG", "Double Barrel Shotgun", "Revolver", "AK47", "Turret", "Shotgun"}
 
    for _, g in ipairs(guns) do
        for _, s in ipairs(skins) do
            local evArgs = {
                [1] = "SellSkin",
                [2] = g,
                [3] = s
            }
            game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent"):FireServer(unpack(evArgs))
            game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent"):FireServer(unpack(evArgs))
        end
    end
end
 
sell()
roll()
 
local rollConnection = game:GetService("RunService").Heartbeat:Connect(function()
    roll()
end)
 
local sellConnection = game:GetService("RunService").Heartbeat:Connect(function()
    sell()
end)
