local config_114514 = {
    Enabled = false,
    BaseDistance = 16,
    ScanInterval = 0.001,
    BlockCooldown = 0.08,
    MoveCompBase = 1.5,
    MoveCompFactor = 0.25,
    SpeedThreshold = 8,
    PredictBase = 4,
    PredictMax = 12,
    PredictFactor = 0.35,
    TargetAngle = 50,
    MinAttackSpeed = 12,
    ShowVisualization = false,
    EnablePrediction = false,
    PingCompensation = 0.1,
    FastKillerAdjust = 1.3,
    TargetSoundIds = {
        "102228729296384", "140242176732868", "112809109188560", "136323728355613",
        "115026634746636", "84116622032112", "108907358619313", "127793641088496",
        "86174610237192", "95079963655241", "101199185291628", "119942598489800",
        "84307400688050", "113037804008732", "105200830849301", "75330693422988",
        "82221759983649", "81702359653578", "108610718831698", "112395455254818",
        "109431876587852", "109348678063422", "85853080745515", "12222216"
    }
}

pcall(function()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    
    local soundLookup = {}
    for _, id in ipairs(config_114514.TargetSoundIds) do
        soundLookup[id] = true
        soundLookup["rbxassetid://" .. id] = true
    end
    
    local LocalPlayer = Players.LocalPlayer
    local lastBlockTime = 0
    local combatConnection = nil
    local lastScanTime = 0
    local visualizationParts = {}
    local soundCache = {}
    local lastSoundCheck = 0
    local lastPingCheck = 0
    local currentPing = 0
    
    local function GetPing()
        local currentTime = os.clock()
        if currentTime - lastPingCheck < 0.5 then
            return currentPing
        end
        lastPingCheck = currentTime
        
        local stats = Stats and Stats.Network and Stats.Network:FindFirstChild("ServerStatsItem")
        if stats then
            local pingStat = stats:FindFirstChild("Data Ping")
            if pingStat then
                currentPing = pingStat.Value
                return currentPing
            end
        end
        
        return 0
    end
    
    local function GetPingCompensation()
        local ping = GetPing()
        return math.min(0.3, ping / 1000 * config_114514.PingCompensation * 10)
    end
    
    local function CreateVisualization()
        if not LocalPlayer.Character then return end
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        for _, part in ipairs(visualizationParts) do
            part:Destroy()
        end
        visualizationParts = {}
        
        local center = rootPart.Position
        local distance = config_114514.BaseDistance
        local angle = math.rad(config_114514.TargetAngle)
        local segments = 36
        
        local basePart = Instance.new("Part")
        basePart.Size = Vector3.new(0.1, 0.1, 0.1)
        basePart.Position = center + Vector3.new(0, 0.1, 0)
        basePart.Anchored = true
        basePart.CanCollide = false
        basePart.Transparency = 1
        basePart.Parent = workspace
        table.insert(visualizationParts, basePart)
        
        for i = 1, segments do
            local part = Instance.new("Part")
            part.Size = Vector3.new(0.5, 0.1, 0.5)
            part.BrickColor = BrickColor.new("Bright green")
            part.Material = Enum.Material.Neon
            part.Transparency = 0.7
            part.Anchored = true
            part.CanCollide = false
            part.Parent = workspace
            table.insert(visualizationParts, part)
        end
        
        local function UpdateVisualization()
            if not config_114514.ShowVisualization then return end
            if not LocalPlayer.Character then return end
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            
            local center = root.Position + Vector3.new(0, 0.1, 0)
            local lookVector = root.CFrame.LookVector
            local distance = config_114514.BaseDistance
            local angle = math.rad(config_114514.TargetAngle)
            
            basePart.Position = center
            
            for i = 1, #visualizationParts - 1 do
                local part = visualizationParts[i + 1]
                local segmentAngle = (i - 1) * (2 * angle) / (#visualizationParts - 2) - angle
                local rotCFrame = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), segmentAngle)
                local dir = rotCFrame:VectorToWorldSpace(lookVector)
                local pos = center + dir * distance
                part.Position = pos
                part.Size = Vector3.new(0.5, 0.1, 0.5)
            end
        end
        
        local visConnection
        visConnection = RunService.Heartbeat:Connect(function()
            if not config_114514.ShowVisualization then
                for _, part in ipairs(visualizationParts) do
                    part:Destroy()
                end
                visualizationParts = {}
                visConnection:Disconnect()
                return
            end
            pcall(UpdateVisualization)
        end)
    end
    
    local function HasTargetSound(character)
        if not character then return false end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false end
        
        local currentTime = os.clock()
        if currentTime - lastSoundCheck < 0.0005 then
            return soundCache[character] or false
        end
        lastSoundCheck = currentTime
        
        local found = false
        for _, child in ipairs(rootPart:GetChildren()) do
            if child:IsA("Sound") then
                local soundId = tostring(child.SoundId)
                local numericId = string.match(soundId, "(%d+)$")
                if numericId and soundLookup[numericId] then
                    found = true
                    break
                end
            end
        end
        
        soundCache[character] = found
        return found
    end
    
    local function GetMoveCompensation()
        if not LocalPlayer.Character then return 0 end
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return 0 end
        
        local velocity = rootPart.Velocity
        local speed = math.sqrt(velocity.X^2 + velocity.Y^2 + velocity.Z^2)
        return config_114514.MoveCompBase + (speed * config_114514.MoveCompFactor)
    end
    
    local function IsFastKiller(killer)
        if not killer then return false end
        local killerRoot = killer:FindFirstChild("HumanoidRootPart")
        if not killerRoot then return false end
        
        local killerVel = killerRoot.Velocity
        local killerSpeed = math.sqrt(killerVel.X^2 + killerVel.Y^2 + killerVel.Z^2)
        return killerSpeed > config_114514.MinAttackSpeed
    end
    
    local function GetTotalDetectionRange(killer)
        local base = config_114514.BaseDistance
        local moveBonus = GetMoveCompensation()
        local predict = 0
        local pingBonus = GetPingCompensation() * 5
        
        if config_114514.EnablePrediction and killer and killer:FindFirstChild("HumanoidRootPart") then
            local killerVel = killer.HumanoidRootPart.Velocity
            local killerSpeed = math.sqrt(killerVel.X^2 + killerVel.Y^2 + killerVel.Z^2)
            
            if killerSpeed > config_114514.SpeedThreshold then
                predict = math.min(
                    config_114514.PredictMax, 
                    config_114514.PredictBase + (killerSpeed * config_114514.PredictFactor)
                )
            end
            
            if IsFastKiller(killer) then
                predict = predict * config_114514.FastKillerAdjust
            end
        end
        
        return base + moveBonus + predict + pingBonus
    end
    
    local function IsTargetingMe(killer)
        local myCharacter = LocalPlayer.Character
        if not myCharacter then return false end
        
        local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
        local killerRoot = killer and killer:FindFirstChild("HumanoidRootPart")
        if not myRoot or not killerRoot then return false end
        
        local directionToMe = (myRoot.Position - killerRoot.Position).Unit
        local killerLook = killerRoot.CFrame.LookVector
        
        local dot = directionToMe:Dot(killerLook)
        local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
        
        return angle <= config_114514.TargetAngle
    end
    
    local function GetThreateningKillers()
        local killers = {}
        local killersFolder = workspace:FindFirstChild("Killers") or (workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers"))
        if not killersFolder then return killers end
        
        local myCharacter = LocalPlayer.Character
        if not myCharacter then return killers end
        
        local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
        if not myRoot then return killers end
        
        for _, killer in ipairs(killersFolder:GetChildren()) do
            if killer:IsA("Model") and killer:FindFirstChild("HumanoidRootPart") then
                local killerRoot = killer.HumanoidRootPart
                local distance = (myRoot.Position - killerRoot.Position).Magnitude
                local detectionRange = GetTotalDetectionRange(killer)
                
                if distance <= detectionRange and HasTargetSound(killer) and IsTargetingMe(killer) then
                    table.insert(killers, killer)
                end
            end
        end
        
        return killers
    end
    
    local function GetAdjustedCooldown()
        local ping = GetPing()
        return math.max(0.05, config_114514.BlockCooldown - (ping / 1000 * 0.5))
    end
    
    local function PerformBlock()
        local now = os.clock()
        if now - lastBlockTime >= GetAdjustedCooldown() then
            pcall(function()
                local args = {
                    "UseActorAbility",
                    {
                        buffer.fromstring("\"Block\"")
                    }
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                lastBlockTime = now
            end)
        end
    end
    
    local function CombatLoop()
        local currentTime = os.clock()
        if currentTime - lastScanTime >= config_114514.ScanInterval then
            lastScanTime = currentTime
            local killers = GetThreateningKillers()
            if #killers > 0 then
                PerformBlock()
            end
        end
    end
    
    ZZ:AddToggle("AutoBlockToggle", {
        Text = "Auto Block",
        Default = false,
        Callback = function(enabled)
            config_114514.Enabled = enabled
            if enabled then
                if combatConnection then
                    combatConnection:Disconnect()
                end
                combatConnection = RunService.Stepped:Connect(function()
                    pcall(CombatLoop)
                end)
            elseif combatConnection then
                combatConnection:Disconnect()
                combatConnection = nil
            end
        end
    })
    
    ZZ:AddSlider("BaseDistance", {
        Text = "distance",
        Default = 16,
        Min = 5,
        Max = 30,
        Rounding = 1,
        Callback = function(value)
            config_114514.BaseDistance = value
        end
    })
    
    ZZ:AddSlider("TargetAngleSlider", {
        Text = "Angle",
        Default = 70,
        Min = 10,
        Max = 180,
        Rounding = 1,
        Callback = function(value)
            config_114514.TargetAngle = value
        end
    })
    
    ZZ:AddToggle("VisualizationToggle", {
        Text = "Visualization",
        Default = false,
        Callback = function(enabled)
            config_114514.ShowVisualization = enabled
            if enabled then
                CreateVisualization()
            else
                for _, part in ipairs(visualizationParts) do
                    part:Destroy()
                end
                visualizationParts = {}
            end
        end
    })
    
    LocalPlayer.CharacterAdded:Connect(function()
        if config_114514.Enabled and combatConnection then
            combatConnection:Disconnect()
            combatConnection = RunService.Stepped:Connect(CombatLoop)
        end
        if config_114514.ShowVisualization then
            CreateVisualization()
        end
    end)
end)

