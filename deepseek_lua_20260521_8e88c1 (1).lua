local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

WindUI:AddTheme({
    Name = "Blue Red Dark",

    Accent = Color3.fromHex("#3399FF"),     
    Background = Color3.fromHex("#0A0A0A"),
    Outline = Color3.fromHex("#FF3333"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#223344"),
    Button = Color3.fromHex("#0A0A2A"),
    Icon = Color3.fromHex("#FF6666"),
})

local Window = WindUI:CreateWindow({
    Title = "<font color='#000000'>[</font><font color='#FF3333'>Thanh</font><font color='#0066FF'>Duy</font><font color='#FF3333'>Hub</font><font color='#000000'>]</font><font color='#FF3333'> TSB</font>",
    Icon = "Pulse", 
    Author = "by ThanhDuy",
    Folder = "MySuperHub",
    
    Background = "rbxassetid://80074775088000", 
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "My Theme",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.65,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            print("clicked")
        end,
    },
})

Window:EditOpenButton({
    Title = "<font color='#000000'>[</font><font color='#FF3333'>Thanh</font><font color='#0066FF'>Duy</font><font color='#FF3333'>Hub</font><font color='#000000'>]</font><font color='#FF3333'> TSB</font>",
    Icon = "Pulse",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("#FF00FF"), 
        Color3.fromHex("#0A0A0A")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

-- ===== GLOBAL STATE =====
local MasterEnabled = false
local CombatEnabled = false
local CamlockEnabled = false
local CurrentTarget = nil
local CamlockTarget = nil
local LOCK_DISTANCE = 80
local CamLOCK_DISTANCE = 120
local CamPREDICTION = 0.12
local CamSMOOTHNESS = 0.18

-- Instant Lethal V2 state
local InstantLethalEnabled = false
local InstantLethalConnection = nil
local InstantLethalAnimConnection = nil

-- FPS Counter
local FPS = 0
local lastUpdate = tick()
local frameCount = 0
local Ping = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    
    if now - lastUpdate >= 1 then
        FPS = math.floor(frameCount / (now - lastUpdate))
        frameCount = 0
        lastUpdate = now
    end
end)

-- Ping Counter
task.spawn(function()
    while task.wait(2) do
        local success, pingValue = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if success then
            Ping = pingValue
        end
    end
end)

-- ===== FUNCTIONS =====
function GetNearestPlayer()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end

    local root = char.HumanoidRootPart
    local nearest, dist = nil, LOCK_DISTANCE

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - root.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = plr
                end
            end
        end
    end
    return nearest
end

function CamFindTarget()
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end

    local root = myChar.HumanoidRootPart
    local nearest, bestDist = nil, CamLOCK_DISTANCE

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local d = (hrp.Position - root.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    nearest = plr
                end
            end
        end
    end
    return nearest
end

-- ===== INSTANT LETHAL V2 FUNCTIONS (Từ file 1) =====
local function InstantLethal_DoFlick()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if root and hum then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.pi, 0)
        local x, y, z = Camera.CFrame:ToEulerAnglesYXZ()
        Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.fromEulerAnglesYXZ(x, y + math.pi, z)
        hum.AutoRotate = false
        task.delay(0.4, function() if hum then hum.AutoRotate = true end end)
    end
end

local function InstantLethal_DoJump()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity = Vector3.new(0, 64, 0) end
end

local function InstantLethal_ConnectLogic()
    if InstantLethalAnimConnection then 
        InstantLethalAnimConnection:Disconnect() 
    end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    local animId = "rbxassetid://12296113986"
    local Smoothness = 0.22
    
    InstantLethalAnimConnection = hum.AnimationPlayed:Connect(function(anim)
        if InstantLethalEnabled and anim.Animation.AnimationId == animId then
            task.wait(1.72)
            InstantLethal_DoJump()
            InstantLethal_DoFlick()
            local dashData = {{Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}}
            if char:FindFirstChild("Communicate") then
                char.Communicate:FireServer(unpack(dashData))
            end
            task.wait(Smoothness)
            InstantLethal_DoFlick()
        end
    end)
end

local function StartInstantLethal()
    if InstantLethalConnection then 
        InstantLethalConnection:Disconnect() 
    end
    InstantLethal_ConnectLogic()
    InstantLethalConnection = LocalPlayer.CharacterAdded:Connect(function()
        if InstantLethalEnabled then 
            task.wait(0.5) 
            InstantLethal_ConnectLogic() 
        end
    end)
end

local function StopInstantLethal()
    if InstantLethalAnimConnection then
        InstantLethalAnimConnection:Disconnect()
        InstantLethalAnimConnection = nil
    end
    if InstantLethalConnection then
        InstantLethalConnection:Disconnect()
        InstantLethalConnection = nil
    end
end

-- Auto Kill Functions
local targetPlayer = nil
local killEnabled = false
local orbitEnabled = false
local nameInput = ""

local function getNearestPlayerAK()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local root = char.HumanoidRootPart
    local nearest, minDist = nil, math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (root.Position - hrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = plr
                end
            end
        end
    end
    return nearest
end

local function tapKey(key, delayTime)
    delayTime = delayTime or 0.05
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(delayTime)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

-- Main loop
RunService.RenderStepped:Connect(function()
    -- Combat (Silent Aim)
    if MasterEnabled and CombatEnabled then
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end

        if not CurrentTarget or not CurrentTarget.Character or not CurrentTarget.Character:FindFirstChildOfClass("Humanoid") or CurrentTarget.Character.Humanoid.Health <= 0 then
            CurrentTarget = GetNearestPlayer()
            return
        end

        local targetHRP = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then return end

        char.HumanoidRootPart.CFrame = CFrame.new(
            char.HumanoidRootPart.Position,
            Vector3.new(targetHRP.Position.X, char.HumanoidRootPart.Position.Y, targetHRP.Position.Z)
        )
    end

    -- Camlock
    if CamlockEnabled then
        if not CamlockTarget or not CamlockTarget.Character or not CamlockTarget.Character:FindFirstChild("HumanoidRootPart") then
            CamlockTarget = CamFindTarget()
            return
        end

        local hrp = CamlockTarget.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local predicted = hrp.Position + (hrp.AssemblyLinearVelocity * CamPREDICTION)
        local currentCF = Camera.CFrame
        local targetCF = CFrame.new(currentCF.Position, predicted)
        Camera.CFrame = currentCF:Lerp(targetCF, CamSMOOTHNESS)
    end
end)

-- ===== CREATE TABS =====
local TonghopTab = Window:Tab({
    Title = "TongHop",
    Icon = "Ghost",
})

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "Ghost",
})

-- ===== AUTO TECHS  =====
local AutoTechSection = Window:Section({
    Title = "Auto Tech Character"
})

local GarouAutoTab = AutoTechSection:Tab({ Title = "Garou" })
local SaitamaAutoTab = AutoTechSection:Tab({ Title = "Saitama" })
local TatsumakiAutoTab = AutoTechSection:Tab({ Title = "Tatsumaki" })
local MiscAutoTab = AutoTechSection:Tab({ Title = "All Character" })

-- ===== GAROU AUTO TECH =====

-- Instant Lethal V2 (Từ file 1)
GarouAutoTab:Toggle({
    Title = "Instant Lethal V2",
    Desc = "Auto Instant Lethal combo for Garou",
    Locked = false,
    Default = false,
    Callback = function(state)
        InstantLethalEnabled = state
        if state then
            StartInstantLethal()
        else
            StopInstantLethal()
        end
    end
})

-- Auto Kyoto
GarouAutoTab:Toggle({
    Title = "Auto Kyoto",
    Desc = "",
    Locked = false,
    Default = false,
    Callback = function(state)
         toggles.GarouAutoKyoto = state
        if state then
            task.spawn(function()
                local v_u_1 = 22.5
                local v_u_4 = 0.6
                local v5 = game:GetService("Players")
                local v_u_6 = game:GetService("VirtualInputManager")
                local v_u_8 = v5.LocalPlayer
                local v_u_9 = 0
                local v_u_11 = true
                
                local function v_u_13() return os.clock() end
                local function v_u_15()
                    local v14 = v_u_8.Character
                    if v14 then return v14:FindFirstChild("HumanoidRootPart") else return nil end
                end
                local function v_u_17()
                    if v_u_13() - v_u_9 >= v_u_4 then
                        v_u_9 = v_u_13()
                        local v16 = v_u_15()
                        if v16 then
                            v16.CFrame = v16.CFrame + v16.CFrame.LookVector * v_u_1
                            pcall(function()
                                v_u_6:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
                                task.wait(0.05)
                                v_u_6:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
                            end)
                        end
                    end
                end
                local animId = "rbxassetid://12273188754"
                local delayTime = 1.5
                local connection = nil
                local function setupChar(char)
                    if connection then connection:Disconnect() end
                    local hum = char:FindFirstChild("Humanoid")
                    if hum then
                        connection = hum.AnimationPlayed:Connect(function(animTrack)
                            if v_u_11 and animTrack.Animation and animTrack.Animation.AnimationId == animId then
                                task.delay(delayTime, function()
                                    if v_u_11 then v_u_17() end
                                end)
                            end
                        end)
                    end
                end
                v_u_8.CharacterAdded:Connect(setupChar)
                if v_u_8.Character then setupChar(v_u_8.Character) end
                while toggles.GarouAutoKyoto do task.wait(1) end
                if connection then connection:Disconnect() end
            end)
        end
    end
})

GarouAutoTab:Toggle({
    Title = "Twisted",
    Desc = "",
    Callback = function(state)
        print("Auto Twisted:", state)
        _G._AutoTwisted_Enabled = state

        local player = game.Players.LocalPlayer
        local cooldown = false
        local animationConnection
        local charAddedConnection
        local animationId = "rbxassetid://13294471966"
        local delayBeforeRemote = 0.23

        local function useRemote()
            if not _G._AutoTwisted_Enabled then return end
            local char = player.Character
            if char and char:FindFirstChild("Communicate") then
                local args = {
                    [1] = {
                        ["Dash"] = Enum.KeyCode.W,
                        ["Key"] = Enum.KeyCode.Q,
                        ["Goal"] = "KeyPress"
                    }
                }
                char.Communicate:FireServer(unpack(args))
            end
        end

        local function stepBack()
            if not _G._AutoTwisted_Enabled then return end
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 3.4)
            end
        end

        local function bindAnimationDetection()
            local char = player.Character or player.CharacterAdded:Wait()
            local humanoid = char:WaitForChild("Humanoid")

            animationConnection = humanoid.AnimationPlayed:Connect(function(track)
                if not _G._AutoTwisted_Enabled then return end
                if track.Animation and track.Animation.AnimationId == animationId and not cooldown then
                    cooldown = true

                    task.delay(delayBeforeRemote, function()
                        if not _G._AutoTwisted_Enabled then return end
                        stepBack()
                        useRemote()
                    end)

                    task.delay(5, function()
                        cooldown = false
                    end)
                end
            end)
        end

        if _G._AutoTwisted_Enabled then
            bindAnimationDetection()
            charAddedConnection = player.CharacterAdded:Connect(function()
                task.wait(1)
                if _G._AutoTwisted_Enabled then
                    bindAnimationDetection()
                end
            end)
        else
            if animationConnection then
                animationConnection:Disconnect()
                animationConnection = nil
            end
            if charAddedConnection then
                charAddedConnection:Disconnect()
                charAddedConnection = nil
            end
        end
    end
})

GarouAutoTab:Toggle({
    Title = "Flowing + Hunter's Grasp",
    Desc = "",
    Callback = function(state)
        print("Flowing + Hunter's Grasp Toggle:", state)
        _G.FlowingGraspEnabled = state

        local RunService = game:GetService("RunService")
        local TweenService = game:GetService("TweenService")
        local player = game.Players.LocalPlayer
        local animationId = "rbxassetid://12273188754"
        local flowingConnection
        local isTweening = false
        local lastPlaying = false

        if _G.FlowingGraspConnection then
            _G.FlowingGraspConnection:Disconnect()
            _G.FlowingGraspConnection = nil
        end

        if not state then return end

        _G.FlowingGraspConnection = RunService.RenderStepped:Connect(function()
            local char = player.Character
            local humanoid = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not humanoid or not hrp then return end

            local isPlaying = false
            for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                if track.Animation and track.Animation.AnimationId == animationId then
                    isPlaying = true
                    break
                end
            end

            if isPlaying and not isTweening and not lastPlaying then
                isTweening = true
                lastPlaying = true

                task.delay(1.8, function()
                    local forwardCFrame = hrp.CFrame + hrp.CFrame.LookVector * 24
                    local tween = TweenService:Create(hrp, TweenInfo.new(0.1), {CFrame = forwardCFrame})
                    tween:Play()
                    tween.Completed:Wait()

                    local tool = player.Backpack:FindFirstChild("Hunter's Grasp")
                    local remote = char:FindFirstChild("Communicate")
                    if tool and remote then
                        local args = {
                            [1] = {
                                ["Tool"] = tool,
                                ["Goal"] = "Console Move"
                            }
                        }
                        remote:FireServer(unpack(args))
                    end

                    isTweening = false
                end)
            elseif not isPlaying then
                lastPlaying = false
            end
        end)
    end
})

GarouAutoTab:Toggle({
    Title = "Upper + Hunter's Grasp",
    Desc = "",
    Callback = function(state)
        print("Upper + Hunter's Grasp Toggle:", state)
        _G.UpperGraspEnabled = state

        local RunService = game:GetService("RunService")
        local TweenService = game:GetService("TweenService")
        local Workspace = game:GetService("Workspace")
        local player = game.Players.LocalPlayer
        local animationId = "rbxassetid://10503381238"
        local TWEEN_HEIGHT_OFFSET = Vector3.new(0, 8, 0)
        local isTweening = false
        local lastPlaying = false
        local cooldown = false

        if _G.UpperGraspConnection then
            _G.UpperGraspConnection:Disconnect()
            _G.UpperGraspConnection = nil
        end

        if not state then return end

        _G.UpperGraspConnection = RunService.RenderStepped:Connect(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChild("Humanoid")
            if not char or not hrp or not humanoid then return end

            local isPlaying = false
            for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                if track.Animation and track.Animation.AnimationId == animationId then
                    isPlaying = true
                    break
                end
            end

            if isPlaying and not isTweening and not lastPlaying and not cooldown then
                isTweening = true
                lastPlaying = true
                cooldown = true

                task.delay(0.18, function()
                    local target
                    local shortestDist = 7
                    local live = Workspace:FindFirstChild("Live")
                    if live then
                        for _, model in ipairs(live:GetChildren()) do
                            if model:IsA("Model") and model ~= char then
                                local torso = model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
                                if torso then
                                    local dist = (hrp.Position - torso.Position).Magnitude
                                    if dist <= shortestDist then
                                        shortestDist = dist
                                        target = torso
                                    end
                                end
                            end
                        end
                    end

                    if target then
                        local targetPos = target.Position + TWEEN_HEIGHT_OFFSET
                        local tween = TweenService:Create(hrp, TweenInfo.new(0.1), {CFrame = CFrame.new(targetPos)})
                        tween:Play()
                        tween.Completed:Wait()
                    end

                    local tool = player.Backpack:FindFirstChild("Hunter's Grasp")
                    local remote = char:FindFirstChild("Communicate")
                    if tool and remote then
                        local args = {
                            [1] = {
                                ["Tool"] = tool,
                                ["Goal"] = "Console Move"
                            }
                        }
                        remote:FireServer(unpack(args))
                    end

                    isTweening = false
                    task.delay(15, function()
                        cooldown = false
                    end)
                end)
            elseif not isPlaying then
                lastPlaying = false
            end
        end)
    end
})

GarouAutoTab:Toggle({
    Title = "Hunter's Grasp + Dash",
    Desc = "",
    Callback = function(state)
        print("Hunter's Grasp + Dash Toggle:", state)
        _G.GraspDashEnabled = state

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local LocalPlayer = Players.LocalPlayer
        local animationIdToDetect = "rbxassetid://12309835105"
        local detected = false

        if _G.GraspDashConnection then
            _G.GraspDashConnection:Disconnect()
            _G.GraspDashConnection = nil
        end

        if state then
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local Humanoid = Character:WaitForChild("Humanoid")

            _G.GraspDashConnection = Humanoid.AnimationPlayed:Connect(function(track)
                if track.Animation.AnimationId == animationIdToDetect and not detected then
                    detected = true
                    print("Phát hiện animation!")

                    task.delay(0.8, function()
                        local char = LocalPlayer.Character
                        if not char then return end

                        local root = char:FindFirstChild("HumanoidRootPart")
                        if root then
                            local backVec = -root.CFrame.LookVector * 4.5
                            root.CFrame = root.CFrame + backVec
                            print("Đã lùi lại 5 stud")
                        end

                        local remote = char:FindFirstChild("Communicate")
                        if remote then
                            local args = {
                                {
                                    Dash = Enum.KeyCode.W,
                                    Key = Enum.KeyCode.Q,
                                    Goal = "KeyPress"
                                }
                            }
                            remote:FireServer(unpack(args))
                            print("Đã gửi remote Dash Q")
                        end

                        task.wait(1.5)
                        detected = false
                    end)
                end
            end)
        end
    end
})

GarouAutoTab:Toggle({
    Title = "Auto Surf",
    Desc = "",
    Callback = function(state)
        print("Auto Surf Toggle:", state)
        _G.AutoSurfEnabled = state

        local Players = game:GetService("Players")
        local TweenService = game:GetService("TweenService")
        local RunService = game:GetService("RunService")
        local LocalPlayer = Players.LocalPlayer
        local TARGET_ANIM_ID = "rbxassetid://12309835105"
        local isTweening = false

        if _G.AutoSurfRenderConnection then
            _G.AutoSurfRenderConnection:Disconnect()
            _G.AutoSurfRenderConnection = nil
        end
        if _G.AutoSurfCharConnection then
            _G.AutoSurfCharConnection:Disconnect()
            _G.AutoSurfCharConnection = nil
        end

        if not state then return end

        local function getCharacter()
            return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        end

        local function isTargetAnimPlaying()
            local char = getCharacter()
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not humanoid then return false end

            for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                if track.Animation and track.Animation.AnimationId == TARGET_ANIM_ID then
                    return true
                end
            end
            return false
        end

        _G.AutoSurfRenderConnection = RunService.RenderStepped:Connect(function()
            if not _G.AutoSurfEnabled or isTweening then return end
            if isTargetAnimPlaying() then
                isTweening = true
                task.wait(0.6)

                local char = getCharacter()
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Anchored = false
                    local forward = root.CFrame.LookVector.Unit
                    local tween = TweenService:Create(root, TweenInfo.new(0.78), {CFrame = root.CFrame + (forward * 50)})
                    tween:Play()
                    tween.Completed:Wait()
                end

                task.wait(1.5)
                isTweening = false
            end
        end)

        _G.AutoSurfCharConnection = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            getCharacter()
        end)
    end
})

GarouAutoTab:Toggle({
    Title = "Auto Whirlwind Dunk",
    Desc = "",
    Callback = function(isEnabled)
        print("Auto Whirlwind Dunk:", isEnabled)
        _G.WhirlwindDunkEnabled = isEnabled

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local lp = Players.LocalPlayer

        if _G.TeleportAnimConnection then
            _G.TeleportAnimConnection:Disconnect()
            _G.TeleportAnimConnection = nil
        end

        if isEnabled then
            local isTeleporting = false
            local lastTrack = nil

            _G.TeleportAnimConnection = RunService.RenderStepped:Connect(function()
                local character = lp.Character
                if not character or isTeleporting then return end

                local humanoid = character:FindFirstChildWhichIsA("Humanoid")
                local root = character:FindFirstChild("HumanoidRootPart")
                if not humanoid or not root then return end

                for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                    if track.Animation and track.Animation.AnimationId == "rbxassetid://12296113986" then
                        if lastTrack == track then return end
                        lastTrack = track

                        isTeleporting = true
                        task.delay(1, function()
                            if root and root.Parent then
                                root.CFrame = root.CFrame + Vector3.new(0, 70, 0)
                            end
                            isTeleporting = false
                        end)
                        break
                    end
                end

                if lastTrack and not lastTrack.IsPlaying then
                    lastTrack = nil
                end
            end)
        end
    end
})

-- ===== SAITAMA AUTO TECH =====

-- Reflex Tech (Saitama)
SaitamaAutoTab:Toggle({
    Title = "Reflex Tech",
    Desc = "Bug",
    Locked = false,
    Default = false,
    Callback = function(state)
        toggles.ReflexTech = state
        if state then
            task.spawn(function()
                local v1 = game.Players.LocalPlayer
                local vu5 = workspace:WaitForChild("Live"):WaitForChild(v1.Name)
                local vu6 = false
                local vu7 = {}
                local vu8 = "rbxassetid://10471336737"
                local vu9 = game:GetService("Players")
                local vu10 = game:GetService("RunService")
                local vu11 = vu9.LocalPlayer
                
                local function vu22()
                    local v12 = vu11.Character
                    if not (v12 and v12:FindFirstChild("HumanoidRootPart")) then return nil end
                    local v13 = v12.HumanoidRootPart
                    local v14 = math.huge
                    local v19 = nil
                    for _, v20 in ipairs(vu9:GetPlayers()) do
                        if v20 ~= vu11 and v20.Character and v20.Character:FindFirstChild("HumanoidRootPart") then
                            local v21 = (v13.Position - v20.Character.HumanoidRootPart.Position).Magnitude
                            if v21 < v14 then v19 = v20 v14 = v21 end
                        end
                    end
                    return v19
                end
                
                local function vu32()
                    local v23 = vu11.Character or vu11.CharacterAdded:Wait()
                    local vu24 = v23:WaitForChild("Humanoid")
                    local vu25 = v23:WaitForChild("HumanoidRootPart")
                    vu24.AutoRotate = false
                    local vu27 = vu24:GetPropertyChangedSignal("AutoRotate"):Connect(function() if vu24.AutoRotate == true then vu24.AutoRotate = false end end)
                    local vu28 = vu22()
                    if vu28 then
                        local vu29 = tick()
                        local vu30 = nil
                        vu30 = vu10.RenderStepped:Connect(function()
                            if tick() - vu29 <= 3 then
                                if vu28.Character and vu28.Character:FindFirstChild("HumanoidRootPart") then
                                    local v31 = vu28.Character.HumanoidRootPart.Position
                                    vu25.CFrame = CFrame.lookAt(vu25.Position, Vector3.new(v31.X, vu25.Position.Y, v31.Z))
                                end
                            else
                                vu30:Disconnect()
                                vu27:Disconnect()
                                vu24.AutoRotate = true
                            end
                        end)
                    end
                end
                
                local function vu38()
                    local vu33 = game:GetService("VirtualInputManager")
                    vu33:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.delay(1, function() vu33:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
                    task.wait(0.29)
                    local v35 = {{Mobile = true, Goal = "LeftClick"}}
                    game.Players.LocalPlayer.Character.Communicate:FireServer(unpack(v35))
                    task.wait(0.1)
                    task.wait(0.5)
                    local v36 = {{Goal = "LeftClickRelease", Mobile = true}}
                    game.Players.LocalPlayer.Character.Communicate:FireServer(unpack(v36))
                    vu32()
                    local v37 = {{Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}}
                    game.Players.LocalPlayer.Character.Communicate:FireServer(unpack(v37))
                end
                
                local function vu50()
                    local v49 = vu5:GetAttributeChangedSignal("Combo"):Connect(function()
                        if vu5:GetAttribute("Combo") == 4 then
                            local vu39 = vu11.Character or vu11.CharacterAdded:Wait()
                            local v43 = vu39:WaitForChild("Humanoid").AnimationPlayed:Connect(function(p42)
                                if p42.Animation and p42.Animation.AnimationId == vu8 then vu38(vu39) end
                            end)
                            table.insert(vu7, v43)
                            for _, v48 in ipairs(vu39:WaitForChild("Humanoid"):GetPlayingAnimationTracks()) do
                                if v48.Animation and v48.Animation.AnimationId == vu8 then vu38(vu39) break end
                            end
                        end
                    end)
                    table.insert(vu7, v49)
                end
                
                vu50()
                while toggles.ReflexTech do task.wait(1) end
                for _, v54 in ipairs(vu7) do v54:Disconnect() end
            end)
        end
    end
})

SaitamaAutoTab:Toggle({
    Title = "Skill 4 + Dash",
    Desc = "Saitama",
    Callback = function(state)
        print("Skill 4 + Dash Toggle:", state)
        _G.UpperCutDashEnabled = state

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local animationId = "rbxassetid://12510170988"

        local function FireDashRemote()
            local comm = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Communicate")
            if comm then
                local args = {
                    {
                        Dash = Enum.KeyCode.W,
                        Key = Enum.KeyCode.Q,
                        Goal = "KeyPress"
                    }
                }
                comm:FireServer(unpack(args))
            end
        end

        if _G.UpperCutDashConnection then
            _G.UpperCutDashConnection:Disconnect()
            _G.UpperCutDashConnection = nil
        end

        if state then
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local Humanoid = Character:WaitForChild("Humanoid")

            _G.UpperCutDashConnection = Humanoid.AnimationPlayed:Connect(function(track)
                if track.Animation and track.Animation.AnimationId == animationId then
                    task.delay(1, function()
                        if track.IsPlaying then
                            FireDashRemote()
                        end
                    end)
                end
            end)
        end
    end
})

-- ===== TATSUMAKI AUTO TECH =====

-- Final Pull Tech (Tatsumaki)
TatsumakiAutoTab:Toggle({
    Title = "3m1 + Crushing Pull",
    Desc = "",
    Locked = false,
    Default = false,
    Callback = function(Enabled)
        print("Final Pull Tech:", Enabled)
        _G.FinalPullEnabled = Enabled

        -- Dọn dây nối cũ
        if _G.FinalPull_Connection then
            _G.FinalPull_Connection:Disconnect()
            _G.FinalPull_Connection = nil
        end
        if _G.FinalPull_CharAdded then
            _G.FinalPull_CharAdded:Disconnect()
            _G.FinalPull_CharAdded = nil
        end

        if not Enabled then return end

        local Players = game:GetService("Players")
        local VirtualInputManager = game:GetService("VirtualInputManager")
        local LocalPlayer = Players.LocalPlayer
        local FPT_Running = false

        local function HookFinalPull(character)
            local humanoid = character:WaitForChild("Humanoid")

            if _G.FinalPull_Connection then
                _G.FinalPull_Connection:Disconnect()
            end

            _G.FinalPull_Connection = humanoid.AnimationPlayed:Connect(function(track)
                if not _G.FinalPullEnabled then return end
                if FPT_Running then return end

                local id = track.Animation.AnimationId
                if id == "rbxassetid://16515448089" then
                    FPT_Running = true

                    task.wait(0.2)
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)

                    task.wait(0.7)
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)

                    task.delay(5, function()
                        FPT_Running = false
                    end)

                elseif id == "rbxassetid://10479335397" then
                    FPT_Running = true
                    task.delay(5, function()
                        FPT_Running = false
                    end)
                end
            end)
        end

        if LocalPlayer.Character then
            HookFinalPull(LocalPlayer.Character)
        end

        _G.FinalPull_CharAdded = LocalPlayer.CharacterAdded:Connect(HookFinalPull)
    end
})

-- ===== MISC AUTO TECH =====

-- Hexed Tech
MiscAutoTab:Toggle({
    Title = "Hexed Tech",
    Desc = "",
    Locked = false,
    Default = false,
    Callback = function(state)
        toggles.HexedTech = state
        if state then
            task.spawn(function()
                local vu1 = {"rbxassetid://10503381238", "rbxassetid://13379003796"}
                local vu2 = 0.32
                local vu3 = 0.25
                local vu4 = 0.35
                local vu10 = game:GetService("Players")
                local vu11 = game:GetService("RunService")
                local vu12 = vu10.LocalPlayer
                local vu9 = nil
                
                local function vu23()
                    local v13 = vu12.Character
                    if not (v13 and v13:FindFirstChild("HumanoidRootPart")) then return nil end
                    local v14 = v13.HumanoidRootPart.Position
                    local v15 = nil
                    local v16 = nil
                    local v17 = workspace:FindFirstChild("Live")
                    if v17 then
                        for _, v21 in ipairs(v17:GetChildren()) do
                            if v21:IsA("Model") and v21:FindFirstChild("HumanoidRootPart") and (v21.Name == "Weakest Dummy" or (vu10:GetPlayerFromCharacter(v21) and v21 ~= vu12.Character)) then
                                local v22 = (v21.HumanoidRootPart.Position - v14).Magnitude
                                if not v16 or v22 < v16 then
                                    v16 = v22
                                    v15 = v21
                                end
                            end
                        end
                    end
                    return v15
                end
                
                local function vu34(p24)
                    local vu25 = p24:GetDescendants()
                    for _, v29 in ipairs(vu25) do
                        if v29:IsA("BasePart") then v29.CanCollide = false end
                    end
                    task.delay(1.2, function()
                        for _, v33 in ipairs(vu25) do
                            if v33:IsA("BasePart") then v33.CanCollide = true end
                        end
                    end)
                end
                
                local function vu49()
                    if vu9 then vu9:Disconnect() end
                    local vu35 = vu12.Character or vu12.CharacterAdded:Wait()
                    vu9 = vu35:WaitForChild("Humanoid").AnimationPlayed:Connect(function(p37)
                        local v38 = p37.Animation
                        if v38 and table.find(vu1, v38.AnimationId) then
                            vu34(vu35)
                            task.wait(vu2)
                            local v39 = {{Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}}
                            local v40 = vu35:FindFirstChild("Communicate")
                            if v40 then v40:FireServer(unpack(v39)) end
                            task.wait(vu3)
                            local vu41 = vu35:FindFirstChild("HumanoidRootPart")
                            if vu41 then
                                local vu42 = Instance.new("Attachment")
                                vu42.Name = "Lix_Att"
                                vu42.Parent = vu41
                                local vu43 = Instance.new("AlignOrientation")
                                vu43.Mode = Enum.OrientationAlignmentMode.OneAttachment
                                vu43.Attachment0 = vu42
                                vu43.MaxTorque = math.huge
                                vu43.Responsiveness = 1000
                                vu43.RigidityEnabled = false
                                vu43.Parent = vu41
                                local vu44 = tick()
                                local vu45 = nil
                                vu45 = vu11.Heartbeat:Connect(function()
                                    if vu4 >= tick() - vu44 then
                                        local v46 = vu23()
                                        if v46 and v46:FindFirstChild("HumanoidRootPart") then
                                            local v47 = v46.HumanoidRootPart.Position
                                            local v48 = CFrame.lookAt(vu41.Position, Vector3.new(v47.X, vu41.Position.Y, v47.Z)) * CFrame.Angles(math.rad(30), 100, -100)
                                            vu41.CFrame = v48
                                            vu43.CFrame = v48
                                        end
                                    else
                                        vu45:Disconnect()
                                        vu43:Destroy()
                                        vu42:Destroy()
                                    end
                                end)
                            end
                        end
                    end)
                end
                vu49()
                while toggles.HexedTech do task.wait(1) end
                if vu9 then vu9:Disconnect() end
            end)
        end
    end
})

-- Lix Tech
MiscAutoTab:Toggle({
    Title = "Lix Tech",
    Desc = "",
    Locked = false,
    Default = false,
    Callback = function(state)
        toggles.LixTech = state
        if state then
            task.spawn(function()
                local v1 = game:GetService("Players").LocalPlayer
                local vu5 = 0.3
                local vu6 = 0.05
                local vu7 = 0.05
                local vu8 = 2
                local vu9 = false
                local vu10 = false
                local vu11 = "rbxassetid://1127797184"
                local vu13 = false
                
                local function vu19(p16, p17, p18)
                    if p16 < p17 then return p17 elseif p18 < p16 then return p18 else return p16 end
                end
                
                local function vu118(p112, p113)
                    if not getnilinstances then return nil end
                    for _, v117 in pairs(getnilinstances()) do
                        if v117 and v117.ClassName == p113 and v117.Name == p112 then return v117 end
                    end
                    return nil
                end
                
                local vu119 = v1.Character or v1.CharacterAdded:Wait()
                local vu120 = vu119:FindFirstChildOfClass("Humanoid")
                local vu121 = vu119:FindFirstChild("HumanoidRootPart")
                
                local function vu123(p122)
                    return p122 and {WalkSpeed = p122.WalkSpeed, JumpPower = p122.JumpPower, PlatformStand = p122.PlatformStand, AutoRotate = p122.AutoRotate}
                        or {WalkSpeed = 16, JumpPower = 50, PlatformStand = false, AutoRotate = true}
                end
                local vu124 = vu123(vu120)
                
                local function vu134(pu125)
                    if vu9 and not vu10 then
                        if pu125 and pu125.Animation then
                            local v128 = tonumber(pu125.Animation.AnimationId:match("%d+"))
                            if v128 == 13379003796 or v128 == 10503381238 then
                                vu10 = true
                                vu120 = vu119 and vu119:FindFirstChildOfClass("Humanoid") or vu120
                                vu121 = vu119 and vu119:FindFirstChild("HumanoidRootPart") or vu121
                                local vu129 = vu123(vu120)
                                task.wait(vu5)
                                local vu130 = {{Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}}
                                if vu119 and vu119:FindFirstChild("Communicate") then
                                    pcall(function() vu119.Communicate:FireServer(table.unpack(vu130)) end)
                                end
                                local vu131 = vu118("moveme", "BodyVelocity")
                                local vu132
                                if vu131 then vu132 = vu131.Parent pcall(function() vu131.Parent = nil end) end
                                local vu133 = {{Goal = "delete bv", BV = vu131}}
                                if vu119 and vu119:FindFirstChild("Communicate") then
                                    pcall(function() vu119.Communicate:FireServer(table.unpack(vu133)) end)
                                end
                                task.wait(0.3)
                                if vu121 then pcall(function() vu121.CFrame = vu121.CFrame * CFrame.Angles(0, math.rad(180), 0) end) end
                                if vu131 and vu132 then pcall(function() vu131.Parent = vu132 end) end
                                if vu120 then pcall(function() vu120.WalkSpeed = vu129.WalkSpeed or 16 vu120.JumpPower = vu129.JumpPower or 50 vu120.PlatformStand = vu129.PlatformStand or false vu120.AutoRotate = vu129.AutoRotate or true end) end
                                task.wait(0.4)
                                vu121 = vu119 and vu119:FindFirstChild("HumanoidRootPart") or vu121
                                if vu121 then pcall(function() vu121.CFrame = vu121.CFrame * CFrame.Angles(0, math.rad(180), 0) end) end
                                task.wait(0.15)
                                vu10 = false
                            end
                        end
                    end
                end
                
                local function vu136(p135)
                    vu119 = p135
                    vu120 = vu119:FindFirstChildOfClass("Humanoid")
                    vu121 = vu119:FindFirstChild("HumanoidRootPart")
                    vu124 = vu123(vu120)
                    if vu120 then vu120.AnimationPlayed:Connect(vu134) end
                end
                
                if v1.Character then vu136(v1.Character) end
                v1.CharacterAdded:Connect(vu136)
                vu9 = true
                while toggles.LixTech do task.wait(1) end
                vu9 = false
            end)
        end
    end
})

-- Oreo Tech
MiscAutoTab:Toggle({
    Title = "Oreo Tech",
    Desc = "",
    Locked = false,
    Default = false,
    Callback = function(state)
          toggles.OreoTech = state
        if state then
            task.spawn(function()
                local vu4 = game:GetService("Players").LocalPlayer
                local vu5 = workspace.CurrentCamera
                local vu6 = {"rbxassetid://10503381238", "rbxassetid://13379003796"}
                local vu7 = false
                local vu8 = true
                local vu9 = 5
                local vu10 = nil
                local vu11 = (vu4.Character or vu4.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
                
                local function vu16()
                    local v12 = vu4.Character or vu4.CharacterAdded:Wait()
                    local v13 = v12:WaitForChild("HumanoidRootPart")
                    v12:WaitForChild("Humanoid").AutoRotate = false
                    local v14 = v13.CFrame * CFrame.Angles(0, math.rad(180), 0)
                    v13.CFrame = v14
                    local v15 = (vu5.CFrame.Position - v14.Position).Magnitude
                    vu5.CFrame = CFrame.new(v14.Position - v14.LookVector * v15 + Vector3.new(0, 2), v14.Position)
                end
                
                local function vu17()
                    (vu4.Character or vu4.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart").AssemblyLinearVelocity = Vector3.new(0, 57, 0)
                end
                
                vu7 = true
                vu10 = (vu4.Character or vu4.CharacterAdded:Wait()):WaitForChild("Humanoid").AnimationPlayed:Connect(function(p19)
                    if not vu8 then return end
                    for _, v23 in ipairs(vu6) do
                        if p19.Animation.AnimationId == v23 then
                            vu8 = false
                            task.spawn(function()
                                task.wait(0.421)
                                vu17()
                                task.wait(0.13)
                                local v24 = {{Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}}
                                local v25 = vu4.Character:FindFirstChild("Communicate")
                                if v25 then v25:FireServer(unpack(v24)) end
                                vu16()
                                task.wait(0.16)
                                vu16()
                                local v26 = vu11.CFrame.LookVector.Unit
                                vu11.CFrame = vu11.CFrame + v26 * 3.5
                            end)
                            task.delay(vu9, function() vu8 = true end)
                            break
                        end
                    end
                end)
                while toggles.OreoTech do task.wait(1) end
                if vu10 then vu10:Disconnect() end
                vu7 = false
            end)
        end
    end
})

-- LoopDash
MiscAutoTab:Toggle({
    Title = "LoopDash",
    Desc = "",
    Locked = false,
    Default = false,
    Callback = function(state)
       toggles.LoopDash = state
        if state then
            task.spawn(function()
                local v_u_1_ = game:GetService("Players")
                local v_u_2_ = v_u_1_.LocalPlayer
                local v_u_3_ = game:GetService("RunService")
                local v_u_5_ = game:GetService("Workspace")
                local v_u_9_ = {loopReworkAnimDetectId = "10503381238", loopReworkBlockAnimId = "10471478869"}
                local v_u_11_ = {loopRework = true, loopReworkDebounce = false, loopReworkWaitDetect = 3, loopReworkWaitJump = 0, loopReworkWaitRemote = 1, loopReworkLockDuration = 15, loopReworkTargetRadius = 50, loopReworkCooldown = 10, loopReworkResponsiveness = 483, ForceJumpUpwardVelocity = 62}
                local v_u_50_ = {}
                local v_u_51_ = nil
                
                local function v_u_59_()
                    local v56_ = v_u_2_.Character
                    if v56_ then
                        local v57_ = v56_:FindFirstChildOfClass("Humanoid")
                        local v58_ = v56_:FindFirstChild("HumanoidRootPart")
                        if v57_ and v58_ then return v56_, v57_, v58_ end
                    end
                    return nil
                end
                
                function loopReworkFireDashQW()
                    local v60_ = v_u_2_.Character
                    if v60_ then
                        local v_u_61_ = v60_:FindFirstChild("Communicate")
                        if v_u_61_ then
                            pcall(function() v_u_61_:FireServer(unpack({{Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}})) end)
                        end
                    end
                end
                
                function loopReworkFindBestTarget(p63_)
                    local v64_ = p63_ or v_u_11_.loopReworkTargetRadius
                    local v65_ = v_u_5_:FindFirstChild("Live")
                    if not v65_ then return nil end
                    local _, _, v66_ = v_u_59_()
                    if not v66_ then return nil end
                    local v70_ = nil
                    for _, v71_ in ipairs(v65_:GetChildren()) do
                        if v71_ and v71_:IsA("Model") and v71_ ~= v_u_2_.Character then
                            local v72_ = v71_:FindFirstChild("HumanoidRootPart")
                            local v73_ = v71_:FindFirstChildOfClass("Humanoid")
                            if v72_ and v73_ and v73_.Health > 0 then
                                local v74_ = (v72_.Position - v66_.Position).Magnitude
                                if v74_ <= v64_ then v70_ = v72_ v64_ = v74_ end
                            end
                        end
                    end
                    return v70_
                end
                
                function StartHorizontalLockLerp(p_u_93_, p_u_94_, p95_)
                    if not (p_u_93_ and p_u_93_.Parent) then return nil end
                    local _, v96_, v_u_97_ = v_u_59_()
                    if not (v_u_97_ and v96_) then return nil end
                    local v_u_100_ = tick()
                    local v_u_101_ = v_u_3_.RenderStepped:Connect(function(p102_)
                        if p_u_93_ and p_u_93_.Parent and v_u_97_ and v_u_97_.Parent then
                            local v103_ = v_u_97_.Position
                            local v104_ = Vector3.new(p_u_93_.Position.X, v103_.Y, p_u_93_.Position.Z)
                            if (v104_ - v103_).Magnitude >= 0.001 then
                                local v_u_105_ = CFrame.new(v103_, v104_)
                                local alpha = math.clamp(1 - math.exp(-0.02 * 483 * p102_), 0, 1)
                                local v108_ = v_u_97_.CFrame:Lerp(v_u_105_, alpha)
                                v_u_97_.CFrame = CFrame.new(v103_) * CFrame.fromMatrix(Vector3.new(), v108_.RightVector, v108_.UpVector)
                            end
                            if tick() - v_u_100_ >= p_u_94_ then v_u_101_:Disconnect() end
                        else v_u_101_:Disconnect() end
                    end)
                    return function() if v_u_101_ then pcall(function() v_u_101_:Disconnect() end) end end
                end
                
                function loopReworkRunSequence()
                    if v_u_11_.loopReworkDebounce or not v_u_11_.loopRework then return end
                    v_u_11_.loopReworkDebounce = true
                    task.wait(v_u_11_.loopReworkWaitDetect / 10)
                    local _, v_u_130_, v_u_131_ = v_u_59_()
                    if v_u_130_ and v_u_131_ then
                        v_u_130_.AutoRotate = false
                        v_u_131_.Velocity = Vector3.new(v_u_131_.Velocity.X, v_u_11_.ForceJumpUpwardVelocity, v_u_131_.Velocity.Z)
                        task.wait(v_u_11_.loopReworkWaitJump / 10)
                        loopReworkFireDashQW()
                        task.wait(v_u_11_.loopReworkWaitRemote / 10)
                        local target = loopReworkFindBestTarget()
                        if target then v_u_51_ = StartHorizontalLockLerp(target, v_u_11_.loopReworkLockDuration / 10, v_u_11_.loopReworkResponsiveness) end
                        local endTime = tick() + (v_u_11_.loopReworkLockDuration / 10)
                        task.spawn(function()
                            while tick() < endTime and v_u_11_.loopRework do v_u_130_.AutoRotate = false v_u_3_.Heartbeat:Wait() end
                            v_u_130_.AutoRotate = true
                        end)
                    end
                    task.wait(v_u_11_.loopReworkCooldown / 10)
                    v_u_11_.loopReworkDebounce = false
                end
                
                function loopReworkOnAnimationPlayed(p160_)
                    if v_u_11_.loopRework and not v_u_11_.loopReworkDebounce then
                        local animId = tostring(p160_.Animation.AnimationId)
                        if animId:find(v_u_9_.loopReworkAnimDetectId) then task.spawn(loopReworkRunSequence) end
                    end
                end
                
                local function ConnectCharacter()
                    local char = v_u_2_.Character or v_u_2_.CharacterAdded:Wait()
                    local hum = char:WaitForChild("Humanoid")
                    if v_u_50_.anim then v_u_50_.anim:Disconnect() end
                    v_u_50_.anim = hum.AnimationPlayed:Connect(loopReworkOnAnimationPlayed)
                end
                
                ConnectCharacter()
                v_u_50_.charAdded = v_u_2_.CharacterAdded:Connect(ConnectCharacter)
                while toggles.LoopDash do task.wait(1) end
                if v_u_50_.anim then v_u_50_.anim:Disconnect() end
                if v_u_50_.charAdded then v_u_50_.charAdded:Disconnect() end
                local _, hum = v_u_59_()
                if hum then hum.AutoRotate = true end
                if v_u_51_ then v_u_51_() end
            end)
        end
    end
})

-- Supa Tech
MiscAutoTab:Toggle({
    Title = "Supa Tech",
    Desc = "",
    Callback = function(Value)
        print("Supa Legit V2:", Value)
        _G.SupaLegitV2_Enabled = Value
        
        if _G.SupaLegitV2_Connections then
            for _, conn in pairs(_G.SupaLegitV2_Connections) do
                pcall(function()
                    conn:Disconnect()
                end)
            end
            _G.SupaLegitV2_Connections = nil
        end
        
        if not Value then return end
        
        -- Config
        local LEGIT_CONFIG = {
            DASH_DURATION = 0.15,
            FOLLOW_OFFSET = 2.5,
            ANGLE_TILT = math.rad(55),
            STICK_RANGE = 18,
            ANIMATION_IDS = {
                "10503381238",
                "13379003796"
            }
        }
        
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local LocalPlayer = Players.LocalPlayer
        
        local currentCharacter = nil
        local currentHumanoid = nil
        local currentRootPart = nil
        
        local lastTriggerTick = 0
        local cooldownSeconds = 0.3
        local inCooldown = false
        
        local function findClosestModelWithRootPart()
            if not currentRootPart then return nil end
            local closestModel = nil
            local smallestDistance = LEGIT_CONFIG.STICK_RANGE
            for _, descendant in pairs(workspace:GetDescendants()) do
                if descendant:IsA("Model") and descendant:FindFirstChild("HumanoidRootPart") and descendant ~= currentCharacter then
                    local ok, distance = pcall(function()
                        return (currentRootPart.Position - descendant.HumanoidRootPart.Position).Magnitude
                    end)
                    if ok and distance and distance < smallestDistance then
                        closestModel = descendant
                        smallestDistance = distance
                    end
                end
            end
            return closestModel
        end
        
        local function sendDashAndRemoveVelocity()
            pcall(function()
                local payload = {{Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}}
                if currentCharacter and currentCharacter:FindFirstChild("Communicate") then
                    currentCharacter.Communicate:FireServer(unpack(payload))
                end
            end)
        
            local function findNilInstanceByNameClass(name, className)
                for _, inst in pairs(getnilinstances()) do
                    if inst.ClassName == className and inst.Name == name then return inst end
                end
                return nil
            end
        
            pcall(function()
                local payload = {{Goal = "delete bv", BV = findNilInstanceByNameClass("moveme", "BodyVelocity")}}
                if currentCharacter and currentCharacter:FindFirstChild("Communicate") then
                    currentCharacter.Communicate:FireServer(unpack(payload))
                end
            end)
        end
        
        local function performStickDash()
            if not currentCharacter or not currentHumanoid or not currentRootPart then return end
            local targetModel = findClosestModelWithRootPart()
            if not targetModel then return end
            local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
            if not targetRoot then return end
        
            local savedState = {
                WalkSpeed = currentHumanoid.WalkSpeed,
                JumpPower = currentHumanoid.JumpPower,
                PlatformStand = currentHumanoid.PlatformStand,
                AutoRotate = currentHumanoid.AutoRotate
            }
        
            local heartbeatConnection = RunService.Heartbeat:Connect(function()
                if currentRootPart then
                    currentRootPart.Velocity = Vector3.new(0, 0, 0)
                    currentRootPart.RotVelocity = Vector3.new(0, 0, 0)
                end
                if currentHumanoid then currentHumanoid.WalkSpeed = 0 end
            end)
        
            pcall(sendDashAndRemoveVelocity)
            task.wait(0.2)
            pcall(function() currentHumanoid:ChangeState(Enum.HumanoidStateType.Physics) end)
        
            if currentRootPart then
                currentRootPart.CFrame = currentRootPart.CFrame * CFrame.Angles(LEGIT_CONFIG.ANGLE_TILT, 0, 0)
            end
        
            local followDuration = LEGIT_CONFIG.DASH_DURATION
            local startTick = tick()
            local followConnection = RunService.Heartbeat:Connect(function()
                if followDuration > tick() - startTick then
                    local direction = (targetRoot.Position - currentRootPart.Position).Unit
                    local offsetPosition = targetRoot.Position - direction * LEGIT_CONFIG.FOLLOW_OFFSET
                    currentRootPart.CFrame = CFrame.new(offsetPosition) * CFrame.Angles(LEGIT_CONFIG.ANGLE_TILT, 0, 0)
                end
            end)
        
            task.wait(followDuration)
            if heartbeatConnection then heartbeatConnection:Disconnect() end
            if followConnection then followConnection:Disconnect() end
        
            pcall(function()
                currentHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                currentHumanoid.WalkSpeed = savedState.WalkSpeed
                currentHumanoid.JumpPower = savedState.JumpPower
                currentHumanoid.PlatformStand = savedState.PlatformStand
                currentHumanoid.AutoRotate = savedState.AutoRotate
            end)
        end
        
        local function handleAnimationPlayed(animationTrack)
            if not _G.SupaLegitV2_Enabled then return end
            if animationTrack then animationTrack = animationTrack.Animation end
            if animationTrack then
                local animId = tostring(animationTrack.AnimationId or "")
                for _, id in ipairs(LEGIT_CONFIG.ANIMATION_IDS) do
                    if string.find(animId, id, 1, true) then
                        task.delay(0.3, function()
                            if inCooldown then return end
                            lastTriggerTick = tick()
                            inCooldown = true
                            task.spawn(performStickDash)
                            task.wait(4)
                            inCooldown = false
                        end)
                        return
                    end
                end
            end
        end
        
        local function onCharacterAdded(character)
            currentCharacter = character
            currentHumanoid = character:WaitForChild("Humanoid")
            currentRootPart = character:WaitForChild("HumanoidRootPart")
            currentHumanoid.AnimationPlayed:Connect(handleAnimationPlayed)
            local animator = currentHumanoid:FindFirstChildOfClass("Animator")
            if animator then animator.AnimationPlayed:Connect(handleAnimationPlayed) end
        end
        
        _G.SupaLegitV2_Connections = {}
        table.insert(_G.SupaLegitV2_Connections, LocalPlayer.CharacterAdded:Connect(onCharacterAdded))
        if LocalPlayer.Character then
            onCharacterAdded(LocalPlayer.Character)
        end
    end
})

-- Auto DownSlam
MiscAutoTab:Toggle({
    Title = "Auto DownSlam",
    Desc = "",
    Callback = function(value)
        print("Auto DownSlam:", value)
        _G.AutoDownSlamEnabled = value

        local Players = game:GetService("Players")
        local TweenService = game:GetService("TweenService")
        local LocalPlayer = Players.LocalPlayer
        local workspace = game:GetService("Workspace")

        local validIDs = {
            ["rbxassetid://10469639222"] = true,
            ["rbxassetid://13532604085"] = true,
            ["rbxassetid://13295919399"] = true,
            ["rbxassetid://13378751717"] = true,
            ["rbxassetid://14001963401"] = true,
            ["rbxassetid://15240176873"] = true,
            ["rbxassetid://16515448089"] = true,
            ["rbxassetid://17889471098"] = true,
            ["rbxassetid://104895379416342"] = true,
        }

        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid")
        local hrp = char:WaitForChild("HumanoidRootPart")

        local function isNearTarget()
            if not hrp then return false end
            for _, model in ipairs(workspace.Live:GetChildren()) do
                if model:IsA("Model") and model ~= char then
                    local root = model:FindFirstChild("HumanoidRootPart")
                    if root and (root.Position - hrp.Position).Magnitude <= 15 then
                        if Players:GetPlayerFromCharacter(model) or model.Name == "Weakest Dummy" then
                            return true
                        end
                    end
                end
            end
            return false
        end

        local function liftAndJump()
            if not hrp or not humanoid then return end
            if not isNearTarget() then return end

            local tween = TweenService:Create(
                hrp,
                TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { CFrame = hrp.CFrame + Vector3.new(0, 6, 0) }
            )
            tween:Play()

            for _, state in ipairs({
                Enum.HumanoidStateType.PlatformStanding,
                Enum.HumanoidStateType.Freefall,
                Enum.HumanoidStateType.GettingUp,
            }) do
                if humanoid:GetState() == state then
                    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                    task.wait()
                end
            end

            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end

        if value then
            if _G.DownSlamAnimConnection then _G.DownSlamAnimConnection:Disconnect() end
            _G.DownSlamAnimConnection = humanoid.AnimationPlayed:Connect(function(track)
                if _G.AutoDownSlamEnabled and track.Animation and validIDs[track.Animation.AnimationId] then
                    liftAndJump()
                end
            end)
        else
            if _G.DownSlamAnimConnection then
                _G.DownSlamAnimConnection:Disconnect()
                _G.DownSlamAnimConnection = nil
            end
        end
    end
})

-- ===== TAB =====
local MovesetsTab = Window:Tab({
    Title = "Movesets",
    Icon = "Ghost",
})

local TechTab = Window:Tab({
    Title = "Tech",
    Icon = "Ghost",
})

local FixLagTab = Window:Tab({
    Title = "FixLag",
    Icon = "Ghost",
})

local TsbTab = Window:Tab({
    Title = "TSB",
    Icon = "Ghost",
})

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "Ghost",
})

local EmoteTab = Window:Tab({
    Title = "Emote Limited",
    Icon = "Ghost",
})

local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "Ghost",
})

local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "Ghost",
})

local HopTab = Window:Tab({
    Title = "Hop",
    Icon = "Ghost",
})

-- ===== MAIN TAB =====
MainTab:Toggle({
    Title = "Silent Aim",
    Callback = function(Value)
        MasterEnabled = Value
        CombatEnabled = Value
        if not Value then
            CurrentTarget = nil
        end
    end
})

MainTab:Toggle({
    Title = "Cam Lock",
    Desc = "Lock camera on target",
    Callback = function(Value)
        CamlockEnabled = Value
        if not Value then
            CamlockTarget = nil
        end
    end
})

-- ===== TONGHOP TAB =====
TonghopTab:Button({
    Title = "BaeMinhHub",
    Desc = "Friends",
    Callback = function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/ngm2807-sudo/3bb38870095ccba814f13993813410f3/raw/32addd5af4b65ffa18a7002eac6e71b9f01076ed/BaeMinhHub.lua"))()
    end
})

TonghopTab:Button({
    Title = "TthanhHub",
    Desc = "Ghẻ",
    Callback = function()

loadstring(game:HttpGet("https://raw.githubusercontent.com/kaimm2/TSB/refs/heads/main/Tthanh%20Tong%20Hop%20Tech.txt"))()
    end
})

-- ===== MOVESETS TAB =====
MovesetsTab:Button({
    Title = "Sukuna",
    Desc = "Load Sukuna moveset",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/damir512/whendoesbrickdie/main/tspno.txt", true))()
    end
})

MovesetsTab:Button({
    Title = "Gojo",
    Desc = "Load Gojo moveset",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/KJ-The-Strongest-Battlegrounds-battleground-gojo-script-saitama-to-gojo-26980"))()
    end
})

MovesetsTab:Button({
    Title = "Kars",
    Desc = "Load Kars moveset",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/OfficialAposty/RBLX-Scripts/refs/heads/main/UltimateLifeForm.lua"))()
    end
})

MovesetsTab:Button({
    Title = "Wally West",
    Desc = "Load Wally West moveset",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Nova2ezz/west/refs/heads/main/Protected_4638864115822087.lua.txt"))()
    end
})

MovesetsTab:Button({
    Title = "MAFIOSO",
    Desc = "Load Mafioso moveset",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/Lovelymoonlight/Lovelymoonlight/refs/heads/main/Baldy%20to%20mafioso'))()
    end
})

MovesetsTab:Button({
    Title = "Beerus",
    Desc = "Load Beerus moveset",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sparksnaps/Beerus-The-Destroyer/refs/heads/main/Lua"))()
    end
})

MovesetsTab:Button({
    Title = "Madara",
    Desc = "Load Madara moveset",
    Callback = function()
        getgenv().Cutscene = false
        loadstring(game:HttpGet("https://raw.githubusercontent.com/LolnotaKid/SCRIPTSBYVEUX/refs/heads/main/BoombasticLol.lua.txt"))()
    end
})

MovesetsTab:Button({
    Title = "Golden Head",
    Desc = "Load Golden Head moveset",
    Callback = function()
        getgenv().stand = false
        getgenv().ken = false
        getgenv().Spawn = true
        loadstring(game:HttpGet('https://raw.githubusercontent.com/Kenjihin69/Kenjihin69/refs/heads/main/Saitama%20to%20golden%20sigma'))()
    end
})

MovesetsTab:Button({
    Title = "Jun",
    Desc = "Load Jun moveset",
    Callback = function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/GoldenHeads2/f66279000c58a020e894a6db44914838/raw/62e53e1acacec0b38b43cd0f594292c32e09c39b/gistfile1.txt"))()
    end
})

MovesetsTab:Button({
    Title = "Mahito",
    Desc = "Load Mahito moveset",
    Callback = function()
        getgenv().Swordm1 = true
        getgenv().night = false
        getgenv().plushie = false
        getgenv().blackflash = true
        getgenv().chat = false
        loadstring(game:HttpGet('https://raw.githubusercontent.com/Kenjihin69/Kenjihin69/refs/heads/main/Mahito%20v2%20sigma%20tp%20exploit'))()
    end
})

MovesetsTab:Button({
    Title = "Naruto",
    Desc = "Load Naruto moveset",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/LolnotaKid/NarutoBeatUpSasukeAss/refs/heads/main/NarutoCums"))()
    end
})

MovesetsTab:Button({
    Title = "Gabriel",
    Desc = "Load Gabriel moveset",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/damir512/youinsinificants/main/insignificantFuck.txt", true))()
    end
})

MovesetsTab:Button({
    Title = "Void Garou",
    Desc = "Load Void Garou moveset",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/yes1nt/yes/refs/heads/main/Void%20Reaper%20Obfuscated.txt"))()
    end
})

MovesetsTab:Button({
    Title = "Mastery Deku",
    Desc = "Load Mastery Deku moveset",
    Callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/xKextYP5"))()
    end
})

MovesetsTab:Button({
    Title = "SONIC.EXE",
    Desc = "Load SONIC.EXE moveset",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/4zLt8a2P/raw"))()
    end
})

-- ===== TECH TAB =====
TechTab:Button({
    Title = "Supa Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/SupaLegitV2/refs/heads/main/SupaLegitV2.lua",true))()
    end
})

TechTab:Button({
    Title = "Instant Lethal V1",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/Instant-Lethal/refs/heads/main/InstanLethal.lua"))()
    end
})

TechTab:Button({
    Title = "Instant Lethal V2",
    Desc = "Load Instant Lethal V2",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/All-Tech/refs/heads/main/InstantLethalV2.luau"))()
    end
})

TechTab:Button({
    Title = "Surfing Tech",
    Desc = "Load Surfing Tech",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/GarouSurfingTech/refs/heads/main/Protected_2674673126232747.lua"))()
    end
})

TechTab:Button({
    Title = "Loop Dash V2",
    Desc = "Load Loop Dash V2",
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/84e2bd29cccc0f5302267e4dc952cff6816db4af36416cbd477daaa26d60863d.lua"))()
    end
})

TechTab:Button({
    Title = "Mini Supa Tech",
    Desc = "Load MiniSupaTech",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/All-Tech/refs/heads/main/MiniSupaTech.luau"))()
    end
})

TechTab:Button({
    Title = "Auto Tech",
    Desc = "Load Auto Tech",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/NewAutoTech/refs/heads/main/Protected_6389347658054908.lua"))()
    end
})

TechTab:Button({
    Title = "Instant Twisted",
    Desc = "Load Instant Twisted",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/InstantTwistedRevamp/refs/heads/main/Protected_7455521176683315.lua"))()
    end
})

TechTab:Button({
    Title = "Instant Lethal",
    Desc = "Load Instant Lethal",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/InstantLethal/refs/heads/main/Protected_5983112998592296.lua"))()
    end
})

TechTab:Button({
    Title = "Combat Gui",
    Desc = "Load Combat GUI",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/CombatGUI/refs/heads/main/TSBCombatGUI"))()
    end
})

TechTab:Button({
    Title = "Kai Tech",
    Desc = "Load Kai Tech",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/YQANTGV2/YQANTGV2/refs/heads/main/Kai"))()
    end
})

TechTab:Button({
    Title = "Auto Downslam",
    Desc = "Load Auto Downslam",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaimm2/TSB/refs/heads/main/atds"))()
    end
})

TechTab:Button({
    Title = "Gojo Tech Old",
    Desc = "Load Gojo Tech Old",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ngoclinh02042011-stack/Gojo-Tech/refs/heads/main/DuydepzaiGojoTech.lua"))()
    end
})

TechTab:Button({
    Title = "Gojo Tech New",
    Desc = "Load Gojo Tech New",
    Callback = function()
        loadstring(game:HttpGet("https://gojotech.tsbscripts.workers.dev/"))()
    end
})

TechTab:Button({
    Title = "Supa V2 Fix",
    Desc = "Load Supa V2 Fix",
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/2753546c83053761e44664d36ffe5035d6e20fc8aee1d19f0eb7b933974ae537.lua"))()
    end
})

TechTab:Button({
    Title = "Side Dash V1",
    Desc = "Load Side Dash V1",
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/94a29c6b88bfe8c49ea221eaa9225398790c1b7436b0f08caf7517c3002e8782.lua"))()
    end
})

TechTab:Button({
    Title = "Side Dash V2",
    Desc = "Load Side Dash V2",
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/52b3b7317bd590bfe678009b3359e74316d9c731ec1395f3e800718d520501f1.lua"))()
    end
})

TechTab:Button({
    Title = "Auto Tech V2.5",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/All-Tech/refs/heads/main/AutoTech.luau"))()
    end
})

TechTab:Button({
    Title = "Lethal Dash V1",
    Desc = "",
    Callback = function()

getgenv().SCRIPT_KEY = "502d56da-8bf7-410a-b1f3-9a3e6e0f62aa" loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/a96b9a4a030dd50b2b737088b6401b7a7500f4c90a9119c9525a940e5d05c3f7/download"))()
    end
})

TechTab:Button({
    Title = "Supa Cancel",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaimm2/TSB/refs/heads/main/SupaCancel"))()
    end
})

TechTab:Button({
    Title = "Normal Punch Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaimm2/TSB/refs/heads/main/NormalPunchTech"))()
    end
})

TechTab:Button({
    Title = "TwetiQ Tech",
    Desc = "Load TwetiQ Tech",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/bduzr7pS/raw"))()
    end
})

TechTab:Button({
    Title = "Lethal Revamp",
    Desc = "Load Lethal Revamp",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/InstantLethalRevamp/refs/heads/main/Protected_6977817281150270.lua"))()
    end
})

TechTab:Button({
    Title = "Reflex Tech",
    Desc = "Load Reflex Tech",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/ReflexTech/refs/heads/main/Protected_7459802026542834.lua"))()
    end
})

TechTab:Button({
    Title = "Oreo Tech",
    Desc = "Load Oreo Tech",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/OreoTech/refs/heads/main/Protected_6856895483929371.lua"))()
    end
})

TechTab:Button({
    Title = "Supa V3",
    Desc = "Load Supa V3",
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/ea0b7cbd8c395e01ec38271794b2559808d26501bd6e6e30c48660759a7db7b3.lua"))()
    end
})

TechTab:Button({
    Title = "Kiba Tech",
    Desc = "Load Kiba Tech",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kietsonphongthanhnghia-a11y/Uhyeah/refs/heads/main/Protected_1425045629292384.lua.txt"))()
    end
})

TechTab:Button({
    Title = "Instant Twisted New",
    Desc = "Load Instant Twisted New",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Duytsb1609/Instant-Twisted-Sigma/refs/heads/main/instant_Twisted%20(1).lua"))()
    end
})

TechTab:Button({
    Title = "3 in 1 Tech",
    Desc = "Load 3 in 1 Tech",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/NJfMV5ze/raw"))()
    end
})

TechTab:Button({
    Title = "Solitude Tech",
    Desc = "Yqantg",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/86e0da30855e98f4a12efbde49222668b5d711e1ef1b099db7d5eca09bba15ac/download"))()
    end
})

TechTab:Button({
    Title = "CamLock V9",
    Desc = "Yqantg",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/924afb8e0b82b94c3852bd7bdbad2183713eadf7fe084bfbee9869668add0286/download"))()
    end
})

TechTab:Button({
    Title = "Kitty Tech",
    Desc = "Load Kitty Tech",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Nhat473/Kitty-Tech/refs/heads/main/TSB"))()
    end
})

TechTab:Button({
    Title = "Reflex Tech V2",
    Desc = "Load Reflex Tech V2",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/ReflexTech/refs/heads/main/Protected_7459802026542834.lua"))()
    end
})

TechTab:Button({
    Title = "KibaZ Tech",
    Desc = "Load KibaZ Tech",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gamerscripter90/Kibaz/main/kibaztech.lua.txt"))()
    end
})

TechTab:Button({
    Title = "Binding Cloth Dash Tech",
    Desc = "By BaeMinhReal",
    Callback = function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/ngm2807-sudo/aeccf3ce4aef451f61f56d6b21ade701/raw/bindingclothdash.lua"))()
    end
})

TechTab:Button({
    Title = "Supa Tech ( Settings )",
    Desc = "By ThanhDuy",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/SupaLegit-Release/refs/heads/main/SupaLegit.lua"))()
    end
})

TechTab:Button({
    Title = "Auto Kyoto Rework",
    Desc = "Load Auto Kyoto Rework",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/KyotoTechRework/refs/heads/main/Protected_9378660372508532.lua"))()
    end
})

TechTab:Button({
    Title = "Loop Dash V3",
    Desc = "Yqantg",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/774bd154b84449a478cb0d5717df6f56eddf16d5d85a87792d84978a1f75e84a/download"))()
    end
})

TechTab:Button({
    Title = "Auto Uppercut",
    Desc = "Load Auto Uppercut",
    Callback = function()
        loadstring(game:HttpGet("https://arch-http.vercel.app/files/Auto%20Uppercut.lua"))()
    end
})

TechTab:Button({
    Title = "The Fish X (Dash)",
    Desc = "Load The Fish X",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/TheFishX/refs/heads/main/obfuscated_script-1757331576860.lua.txt"))()
    end
})

TechTab:Button({
    Title = "Auto Kyoto (By Mark)",
    Desc = "Load Auto Kyoto by Mark",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Mark22028/Auto-Kyoto-Combo/refs/heads/main/Skibidi%20Sigma%20Combo.txt"))()
    end
})

TechTab:Button({
    Title = "Auto Kyoto Combo",
    Desc = "Load Auto Kyoto Combo",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gamerscripter90/Thestrongesthgg-/main/Kyoto.lua.txt"))()
    end
})

TechTab:Button({
    Title = "KibaZ V1",
    Desc = "Load KibaZ V1",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gamerscripter90/KIBAZ-TECH-/main/Kibaztechv1.lua.txt"))()
    end
})

TechTab:Button({
    Title = "Supa Vole Tech",
    Desc = "Load Supa Vole",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaimm2/TSB/refs/heads/main/SupaVeloTech.lua"))()
    end
})

TechTab:Button({
    Title = "Auto Combo Kyoto (Corex Hub)",
    Desc = "Load Auto Combo Kyoto by Corex",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gamerscripter90/Thestrongesthgg-/main/Kyoto.lua.txt"))()
    end
})

TechTab:Button({
    Title = "Lethal Dash",
    Desc = "By Yqantg",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/57a4d240a2440f0450986c966469092ccfb8d4797392cb8f469fa8b6e605e64d/download"))()
    end
})

TechTab:Button({
    Title = "Hex Tech",
    Desc = "Load Hex Tech",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/Hex-Tech/refs/heads/main/Hex%20Tech.lua"))()
    end
})

TechTab:Button({
    Title = "Auto Combo Kyoto (Saturn Hub)",
    Desc = "Load Auto Combo Kyoto by Saturn",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sigmavexr/AUTO-KYOTO-SATURN-HUB/refs/heads/main/AUTO%20KYOTO"))()
    end
})

TechTab:Button({
    Title = "Skibidi Tech v4",
    Desc = "Load Skibidi Tech v4",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenduchunganh519-source/IL4SK-skibidi/refs/heads/main/IL4SK%20skibidi"))()
    end
})

TechTab:Button({
    Title = "Dripz Tech",
    Desc = "Load Dripz Tech",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ngoclinh02042011-stack/DripzTech/refs/heads/main/DripzTech.txt"))()
    end
})

TechTab:Button({
    Title = "Auto Block V8",
    Desc = "By Yqantg",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/5659752fa0f7c10df56777eafd8f4813f15d3cde1b206f7e10f6b87af4fa9dfd/download"))()
    end
})

TechTab:Button({
    Title = "Auto Block V12",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/CombatGuiNew/refs/heads/main/Auto%20Block%20V12"))()
    end
})

TechTab:Button({
    Title = "Garou Tech",
    Desc = "Load Garou Tech",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/GarouTechs/refs/heads/main/Protected_9831634675356265.lua"))()
    end
})

TechTab:Button({
    Title = "Auto Block V1 (Cps Network)",
    Desc = "Load Auto Block V1",
    Callback = function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/6f502e252308fb97855295005faa73a0.lua"))()
    end
})

TechTab:Button({
    Title = "Garou Damage (2 Garou)",
    Desc = "Load Garou Damage",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/GAROUDAME/refs/heads/main/TSB"))()
    end
})

TechTab:Button({
    Title = "LoopDash V2",
    Desc = "By Yqantg",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/28513f51c0ca2c03d4d7d94f59215d13ce1a2a470bf187f0a685b58ccb4dae98/download"))()
    end
})

TechTab:Button({
    Title = "Twinnie Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Defy-cloud/The-Strongest-Battlegrounds/refs/heads/main/TwinnieTech", true))()
    end
})

TechTab:Button({
    Title = "Instant Lethal V2",
    Desc = "Yqantg",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/a23acf82fb18b827dca096e149ab0272fc74ea9bb8153cd43e44555acb943c86/download"))()
    end
})

TechTab:Button({
    Title = "LoopYen",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/dd205f0487a772434c4bcde88a7d11d52b207c2afda89351d4a4f6f8ecfce48d/download"))()
    end
})

TechTab:Button({
    Title = "Oreo Tech ( Setting )",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Defy-cloud/The-Strongest-Battlegrounds/refs/heads/main/OreoTech"))()
    end
})

TechTab:Button({
    Title = "SupaX Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Defy-cloud/The-Strongest-Battlegrounds/refs/heads/main/SupaxTech", true))()
    end
})

TechTab:Button({
    Title = "Boomy Twisted",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Defy-cloud/The-Strongest-Battlegrounds/refs/heads/main/BoomyTwisted"))()
    end
})

TechTab:Button({
    Title = "M1 Reset",
    Desc = "Load M1 Reset",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-M1-RESET-57657"))()
    end
})

TechTab:Button({
    Title = "Gojo Shuriken ",
    Desc = "By Tthanh",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaimm2/TSB/refs/heads/main/GojoShiruken"))()
    end
})

TechTab:Button({
    Title = "Dripz Tech",
    Desc = "",
    Callback = function()

loadstring(game:HttpGet("https://raw.githubusercontent.com/Defy-cloud/The-Strongest-Battlegrounds/refs/heads/main/DripzTech"))()
    end
})

TechTab:Button({
    Title = "Legit M1 Reset",
    Desc = "",
    Callback = function()

loadstring(game:HttpGet("https://raw.githubusercontent.com/Defy-cloud/Scripts/refs/heads/main/LegitM1Reset"))()
    end
})

-- ===== FIXLAG TAB =====
FixLagTab:Button({
    Title = "Fps Booster V3 (Joshzzz)",
    Desc = "Boost FPS",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/JoshzzAlteregooo/JoshzzFpsBoosterVersion3/refs/heads/main/JoshzzNewFpsBooster"))()
    end
})

FixLagTab:Button({
    Title = "BloxStrap",
    Desc = "Load BloxStrap",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/qwertyui-is-back/Bloxstrap/main/Initiate.lua"))()
    end
})

FixLagTab:Button({
    Title = "Fps Boost (ItLouisPlay)",
    Desc = "Boost FPS",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/ItsLouisPlay-Fps-Booster/refs/heads/main/TSB"))()
    end
})

FixLagTab:Button({
    Title = "Fps Boost (Vikichard)",
    Desc = "Boost FPS",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/VikiChardd/AntiLag_TSB/main/Protect_MeowTBS1999.lua.txt"))()
    end
})

FixLagTab:Button({
    Title = "Low GFX",
    Desc = "Reduce graphics",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Low-GFX-38613"))()
    end
})

FixLagTab:Button({
    Title = "Turbo Lite",
    Desc = "Load Turbo Lite",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TurboLite/Script/main/FixLag.lua"))()
    end
})

FixLagTab:Button({
    Title = "Turbo Lite (Blue)",
    Desc = "Load Turbo Lite Blue",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/MeoLazy/Script/refs/heads/main/FixLag.lua"))()
    end
})

FixLagTab:Button({
    Title = "Fps Boost",
    Desc = "Boost FPS",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/Fps-boost/refs/heads/main/029298383"))()
    end
})

FixLagTab:Button({
    Title = "Fix Lag",
    Desc = "Fix lag",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/Fix-Lag/refs/heads/main/Made%20By%20MinhNhat"))()
    end
})

FixLagTab:Button({
    Title = "Remove Skill",
    Desc = "Remove skill effects",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/louismich4el/ItsLouisPlayz-Scripts/main/TSB%20Anti%20Lag.lua"))()
    end
})

FixLagTab:Button({
    Title = "Kaito FixLag",
    Desc = "Fix lag",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaitofixlag-hub/Fixlag/refs/heads/main/fixlag.txt"))()
    end
})

FixLagTab:Button({
    Title = "Fix lag (Mumya)",
    Desc = "Fix lag",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/dhiPeX7H/raw"))()
    end
})

FixLagTab:Button({
    Title = "Fps Boost v0.5 (Corex Hub)",
    Desc = "Boost FPS",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gamerscripter90/Fps-booster/main/Fpsbooster.lua.txt"))()
    end
})

-- ===== TSB TAB =====
TsbTab:Button({
    Title = "Trash Can",
    Desc = "Load Trash Can",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/yes1nt/yes/refs/heads/main/Trashcan%20Man"))()
    end
})

TsbTab:Button({
    Title = "Aimlock Universal",
    Desc = "Universal aimlock",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/MerebennieOfficial/Bestaimbot/refs/heafs/main/Merebennie"))()
    end
})

TsbTab:Button({
    Title = "Napoleon Hub",
    Desc = "Load Napoleon Hub",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/raydjs/napoleonHub/refs/heads/main/src.lua"))()
    end
})

TsbTab:Button({
    Title = "VexonHub",
    Desc = "Load Vexon Hub",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DiosDi/VexonHub/refs/heads/main/VexonHub"))()
    end
})

TsbTab:Button({
    Title = "AimLock Old",
    Desc = "Old version aimlock",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Mark22028-2ndAcc/Scripts/refs/heads/main/Camlock%20OldV.lua"))()
    end
})

TsbTab:Button({
    Title = "TSB Script (Emerson)",
    Desc = "TSB script by Emerson",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Emerson2-creator/Scripts-Roblox/refs/heads/main/TSBLuna.lua"))()
    end
})

TsbTab:Button({
    Title = "Farm Kill V1",
    Desc = "Auto farm kills V1",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ngoclinh02042011-stack/Farm-Kill-V1/refs/heads/main/FarmKillV1.lua"))()
    end
})

TsbTab:Button({
    Title = "Khanh Ly Auto Farm Vip [Beta]",
    Desc = "Auto farm by Khanh Ly",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/khoavipok/ScriptkhanhlyHUB/refs/heads/main/Khanhly%20strongest%20pranium"))()
    end
})

TsbTab:Button({
    Title = "Phantasm Hub",
    Desc = "Load Phantasm Hub",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ATrainz/Phantasm/refs/heads/main/Games/TSB.lua"))()
    end
})

TsbTab:Button({
    Title = "Invinsible",
    Desc = "Become invisible",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/Invisible/refs/heads/main/TSB"))()
    end
})

TsbTab:Button({
    Title = "Farm Kill",
    Desc = "Auto farm kills",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/FARM-KILL/refs/heads/main/TSB"))()
    end
})

TsbTab:Button({
    Title = "Farm Kill V2",
    Desc = "Auto farm kills V2",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/Farm-Kill-V2/refs/heads/main/TSB"))()
    end
})

TsbTab:Button({
    Title = "Auto Farm",
    Desc = "Auto farm",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/nullrush0/Auto-Farm/refs/heads/main/Lua"))()
    end})

TsbTab:Button({
    Title = "Dovi Hub",
    Desc = "Load Dovi Hub",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Duytsb1609/DoviHub/refs/heads/main/obfuscated_Dovi_HUB_Cracked_by_Merebennie.txt"))()
    end
})

-- ===== MISC TAB =====
MiscTab:Button({
    Title = "No Colldown Dash",
    Desc = "Fah",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/RRc9D0kj/raw"))()
    end
})

MiscTab:Button({
    Title = "Oinan-Thickhoof-Axe",
    Desc = "Get Oinan Thickhoof Axe",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Guestly-Scripts/Items-Scripts/refs/heads/main/Oinan-Thickhoof"))()
    end
})

MiscTab:Button({
    Title = "Erisyphia staff",
    Desc = "Get Erisyphia staff",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/GuestlyTheGreatestGuest/Scripts/refs/heads/main/Erisyphia-Staff-made-by-Guestly"))()
    end
})

MiscTab:Button({
    Title = "M1 Cid effect",
    Desc = "Add M1 effect for Cid",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Duytsb1609/M1-effect/refs/heads/main/Cid%20M1%20Effect.lua"))()
    end
})

MiscTab:Button({
    Title = "M1 Kars effect",
    Desc = "Add M1 effect for Kars",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Duytsb1609/Kars-M1-effect/refs/heads/main/Kars%20M1%20Effect.lua"))()
    end
})

MiscTab:Button({
    Title = "M1 Gojo effect",
    Desc = "Add M1 effect for Gojo",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaimm2/data/refs/heads/main/effectm1"))()
    end
})

MiscTab:Button({
    Title = "Kill Void (Garou Strategy 1)",
    Desc = "Kill void using Garou",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Duytsb1609/Kill-Void/refs/heads/main/Kill%20Void%20(%20Use%20Garou%20Strategy%201%20)"))()
    end
})

MiscTab:Button({
    Title = "Hitbox expander (Sonic)",
    Desc = "Expand hitbox (use Sonic)",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/The-Strongest-Battlegrounds-SION-ELTNAM-ATLASIA-61168"))()
    end
})

MiscTab:Button({
    Title = "Open UI Fling Player",
    Desc = "Fling player UI",
    Callback = function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/ngm2807-sudo/7155874edfab6e1d774d5017ea0b3018/raw/32e909c874a9a5192fd52fd5afe4579e1c74cdb9/flingplayer.lua"))()
    end
})

-- Input for kill target
MiscTab:Input({
    Title = "Enter username to kill",
    Desc = "Empty = nearest player",
    Placeholder = "Username...",
    Callback = function(text)
        nameInput = text
    end
})

MiscTab:Toggle({
    Title = "Auto Kill",
    Desc = "Auto kill target",
    Callback = function(Value)
        killEnabled = Value
    end
})

MiscTab:Toggle({
    Title = "Orbit Target",
    Desc = "Orbit around target",
    Callback = function(Value)
        orbitEnabled = Value
    end
})

-- Auto Kill loop (fixed)
task.spawn(function()
    while task.wait(0.1) do
        if killEnabled then
            if nameInput ~= "" then
                targetPlayer = Players:FindFirstChild(nameInput)
            else
                targetPlayer = getNearestPlayerAK()
            end
            
            if targetPlayer and targetPlayer.Character then
                local char = LocalPlayer.Character
                local thrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                local thum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                local comm = char and char:FindFirstChild("Communicate")
                
                if char and thrp and thum and comm and thum.Health > 0 then
                    local distance = (char.HumanoidRootPart.Position - thrp.Position).Magnitude
                    if distance <= 6 then
                        comm:FireServer({ Goal = "LeftClick", Mobile = true })
                        task.wait(0.15)
                        
                        tapKey(Enum.KeyCode.Q, 0.1)
                        tapKey(Enum.KeyCode.One)
                        tapKey(Enum.KeyCode.Two)
                        tapKey(Enum.KeyCode.Three)
                        tapKey(Enum.KeyCode.Four)
                        
                        task.wait(0.15)
                        tapKey(Enum.KeyCode.G, 0.15)
                        local randomKey = ({Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four})[math.random(1,4)]
                        tapKey(randomKey)
                    end
                end
            end
        end
    end
end)

-- Orbit (fixed)
local radius = 5.5
local heightMin = -1.5
local heightMax = 2
local teleportSpeed = 2

local function randomOffset()
    local dir = Vector3.new(math.random(-100, 100), 0, math.random(-100, 100)).Unit
    local height = math.random() * (heightMax - heightMin) + heightMin
    return dir * radius + Vector3.new(0, height, 0)
end

RunService.RenderStepped:Connect(function()
    if orbitEnabled and targetPlayer and targetPlayer.Character then
        local root = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                for _ = 1, teleportSpeed do
                    char.HumanoidRootPart.CFrame = CFrame.new(root.Position + randomOffset(), root.Position)
                end
            end
        end
    end
end)

-- =====================================================
-- ===== EMOTE TAB (ĐÃ THAY MY BROTHER TỪ FILE 3) =====
-- =====================================================

-- Free slot Emote
EmoteTab:Button({
    Title = "Free slot Emote",
    Desc = "Bruh",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/kVbOxOjb/raw"))()
    end
})

-- Final Stand Emote
EmoteTab:Button({
    Title = "Final Stand",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "final_stand",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        -- Animation
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://113876851900426"
        local track = humanoid:LoadAnimation(anim)
        track:Play()

        -- VFX bind
        task.delay(0.1, function()
            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 100000)
            acc.Parent = character
            acc:SetAttribute("EmoteProperty", true)

            local success, result = pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "Final Stand",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 113876851900426,
                    RealBind = acc,
                })
            end)
        end)

        -- Sound + Aura
        task.delay(9, function()
            if not character or not character.Parent then return end
            
            -- Sound
            local soundIds = {"112446641141594", "98080224862986"}
            for _, id in ipairs(soundIds) do
                local s = Instance.new("Sound")
                s.SoundId = "rbxassetid://" .. id
                s.Volume = 1
                s.Looped = true
                s.Parent = character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
                if s.Parent then
                    s:Play()
                    Debris:AddItem(s, 60)
                end
            end

            -- Aura
            local auraClone = ReplicatedStorage:FindFirstChild("Emotes") and 
                             ReplicatedStorage.Emotes:FindFirstChild("VFX") and
                             ReplicatedStorage.Emotes.VFX:FindFirstChild("VfxMods") and
                             ReplicatedStorage.Emotes.VFX.VfxMods:FindFirstChild("FS") and
                             ReplicatedStorage.Emotes.VFX.VfxMods.FS:FindFirstChild("vfx") and
                             ReplicatedStorage.Emotes.VFX.VfxMods.FS.vfx:FindFirstChild("Aura")
            
            if auraClone then
                auraClone = auraClone:Clone()
                for _, part in pairs(auraClone:GetChildren()) do
                    local targetPart = character:FindFirstChild(part.Name)
                    if not targetPart and part.Name == "HumanoidRootPart" then
                        targetPart = character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
                    end
                    
                    if targetPart then
                        for _, fx in pairs(part:GetChildren()) do
                            if fx:IsA("ParticleEmitter") then
                                fx.LockedToPart = true
                                fx.Parent = targetPart
                                fx:SetAttribute("LimitedAura", true)
                                Debris:AddItem(fx, 65)
                            end
                        end
                    end
                end
                auraClone:Destroy()
            end
        end)
    end
})

-- Inner Rage Emote
EmoteTab:Button({
    Title = "Inner Rage",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "inner_rage",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        -- Color
        local color = Color3.fromRGB(math.random(100, 255), math.random(50, 150), math.random(50, 150))

        -- Animation
        local anim1 = Instance.new("Animation")
        anim1.AnimationId = "rbxassetid://96993907314948"
        local track1 = humanoid:LoadAnimation(anim1)
        track1:Play()

        track1.Stopped:Connect(function()
            local anim2 = Instance.new("Animation")
            anim2.AnimationId = "rbxassetid://127234845846317"
            humanoid:LoadAnimation(anim2):Play()
        end)

        -- Holder
        local holder = Instance.new("Accessory")
        holder.Name = "#EmoteHolder_" .. math.random(1, 100000)
        holder.Parent = character
        CollectionService:AddTag(holder, "emoteendstuff" .. character.Name)

        -- Main VFX
        task.delay(0.1, function()
            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "Energy Explosion",
                    AnimSent = 96993907314948,
                    RealBind = holder,
                    NoInsertion = true,
                    Colour = color,
                })
            end)
        end)

        -- Aura
        task.delay(5.3, function()
            if not holder.Parent then return end
            
            -- Change animation
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                if track.Animation.AnimationId == "rbxassetid://127234845846317" then
                    track:Stop()
                    local anim3 = Instance.new("Animation")
                    anim3.AnimationId = "rbxassetid://117177504280717"
                    humanoid:LoadAnimation(anim3):Play()
                end
            end
        end)
    end
})

-- Shadow Eruption Emote
EmoteTab:Button({
    Title = "Shadow Eruption",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "shadow_eruption",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        -- Sound
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://117425361961655"
        sound.Volume = 1
        sound.Parent = character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
        if sound.Parent then
            sound:Play()
            Debris:AddItem(sound, 10)
        end

        -- Animation
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://121032789756540"
        humanoid:LoadAnimation(anim):Play()

        -- Main VFX
        task.delay(0.1, function()
            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 100000)
            acc.Parent = character
            acc:SetAttribute("EmoteProperty", true)

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "Shadow Eruption",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 121032789756540,
                    RealBind = acc,
                })
            end)
        end)

        -- Loop sound
        task.delay(8.1, function()
            if not character or not character.Parent then return end
            
            local loopSound = Instance.new("Sound")
            loopSound.SoundId = "rbxassetid://128082194939921"
            loopSound.Looped = true
            loopSound.Volume = 1
            loopSound.Parent = character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
            if loopSound.Parent then
                loopSound:Play()
                Debris:AddItem(loopSound, 60)
            end
        end)
    end
})

-- Divine Form Emote
EmoteTab:Button({
    Title = "Divine Form",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "divine_form",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        -- Animation
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://116187503451999"
        humanoid:LoadAnimation(anim):Play()

        -- Main VFX
        task.delay(0.1, function()
            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 100000)
            acc.Parent = character
            acc:SetAttribute("EmoteProperty", true)

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "Divine Form",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 116187503451999,
                    RealBind = acc,
                })
            end)
        end)
    end
})

-- The Strongest Emote
EmoteTab:Button({
    Title = "The Strongest",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "the_strongest",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        -- Sounds
        local soundData = {
            {id = "117787451950766", delay = 0, volume = 2},
            {id = "97998065677521", delay = 0.01, volume = 1.85},
            {id = "99535007576182", delay = 2.29, volume = 2, looped = true},
        }

        for _, data in ipairs(soundData) do
            task.delay(data.delay, function()
                local sound = Instance.new("Sound")
                sound.SoundId = "rbxassetid://" .. data.id
                sound.Volume = data.volume
                sound.Looped = data.looped or false
                sound.Parent = workspace
                sound:Play()
                if not data.looped then
                    Debris:AddItem(sound, 10)
                end
            end)
        end

        -- Animation
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://86505219150915"
        humanoid:LoadAnimation(anim):Play()

        -- VFX
        task.delay(0.1, function()
            local bind = Instance.new("Folder")
            bind.Name = "PrideBind"
            bind.Parent = character
            bind:SetAttribute("EmoteProperty", true)

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "Boss Raid",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 86505219150915,
                    RealBind = bind,
                })
            end)
        end)
    end
})

-- Boundless Rage Emote
EmoteTab:Button({
    Title = "Boundless Rage",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "boundless_rage",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        -- Animation
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://107649573628906"
        humanoid:LoadAnimation(anim):Play()

        -- Main VFX
        task.delay(0.1, function()
            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 100000)
            acc.Parent = character
            acc:SetAttribute("EmoteProperty", true)

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "Boundless Rage",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 107649573628906,
                    RealBind = acc,
                })
            end)
        end)

        -- Loop sound
        task.delay(4, function()
            if not character or not character.Parent then return end
            
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://81055990581650"
            sound.Looped = true
            sound.Volume = 1
            sound.Parent = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
            if sound.Parent then
                sound:Play()
                Debris:AddItem(sound, 60)
            end
        end)
    end
})

-- The Fallen Emote
EmoteTab:Button({
    Title = "The Fallen",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "the_fallen",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        -- Animation
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://133818134745501"
        humanoid:LoadAnimation(anim):Play()

        -- VFX + Sound
        task.delay(0.1, function()
            if not character or not character.Parent then return end

            -- Remove old effect
            local old = character:FindFirstChild("DismantleEffect")
            if old then old:Destroy() end

            -- Accessory bind
            local acc = Instance.new("Accessory")
            acc.Name = "DismantleEffect"
            acc.Parent = character
            acc:SetAttribute("EmoteEffect", true)

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "Pride",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 133818134745501,
                    RealBind = acc,
                    CanRotate = true,
                })
            end)

            -- Sound
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://93369149563360"
            sound.Volume = 2
            sound.Parent = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
            if sound.Parent then
                sound:Play()
                Debris:AddItem(sound, 10)
            end
        end)
    end
})

-- True Aura Emote
EmoteTab:Button({
    Title = "True Aura",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "true_aura",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        -- Animation
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://103668868712897"
        humanoid:LoadAnimation(anim):Play()

        -- VFX
        task.delay(0.1, function()
            if not character or not character.Parent then return end

            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 100000)
            acc.Parent = character
            CollectionService:AddTag(acc, "emoteendstuff" .. character.Name)

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "True Aura",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 103668868712897,
                    RealBind = acc,
                })
            end)

            -- Sound
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://83049960731792"
            sound.Volume = 3
            sound.Parent = character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
            if sound.Parent then
                sound:Play()
                Debris:AddItem(sound, 10)
            end
        end)
    end
})

-- Eternal Seal Emote (Locked/Bug)
EmoteTab:Button({
    Title = "Eternal Seal",
    Desc = "Limited Emote (Bug)",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = true,
    LockedTitle = "Bug",
    Justify = "Between",
    Flag = "eternal_seal",
    Callback = function()
        WindUI:Notify({
            Title = "Eternal Seal",
            Content = "This emote is currently bugged!",
            Duration = 3,
        })
    end
})

-- World Cutting Slash Emote
EmoteTab:Button({
    Title = "World Cutting Slash",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "world_cutting_slash",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        -- Animation
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://120001337057214"
        local track = humanoid:LoadAnimation(anim)
        track:Play()

        -- VFX
        task.delay(0.1, function()
            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 99999)
            acc:SetAttribute("EmoteProperty", true)
            acc.Parent = character

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "HugeSlash",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 120001337057214,
                    RealBind = acc,
                    CanRotate = true,
                })
            end)

            -- Sound
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://103835306879590"
            sound.Volume = 3
            sound.Parent = character:FindFirstChild("Torso") or character.PrimaryPart
            if sound.Parent then
                sound:Play()
                Debris:AddItem(sound, 10)
            end
        end)
    end
})

-- ===== MY BROTHER EMOTE (TỪ FILE 3 - ĐÃ THAY THẾ) =====
EmoteTab:Button({
    Title = "My Brother",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "my_brother",

    Callback = function()
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

        local Replication = ReplicatedStorage:FindFirstChild("Replication")
        if not Replication then
            warn("Replication not found")
            return
        end

        ----------------------------------------------------------------
        -- 🔥 GET RANDOM FRIEND (OFFLINE OR ONLINE)
        ----------------------------------------------------------------
        local function GetRandomFriend()
            local success, pages = pcall(function()
                return Players:GetFriendsAsync(LocalPlayer.UserId)
            end)

            if not success or not pages then
                warn("Failed to fetch friends list")
                return nil
            end

            local allFriends = {}

            repeat
                for _, friend in ipairs(pages:GetCurrentPage()) do
                    table.insert(allFriends, friend)
                end

                if pages.IsFinished then
                    break
                end

                pages:AdvanceToNextPageAsync()
            until false

            if #allFriends == 0 then
                warn("No friends found!")
                return nil
            end

            local randomFriend = allFriends[math.random(1, #allFriends)]
            return randomFriend.Id
        end

        local targetId = GetRandomFriend()
        if not targetId then
            return
        end

        ----------------------------------------------------------------
        -- ROCK SPAWN
        ----------------------------------------------------------------
        local RockTemplate = ReplicatedStorage:FindFirstChild("Emotes") and
                             ReplicatedStorage.Emotes:FindFirstChild("RockThrow")

        if not RockTemplate then
            warn("RockThrow not found")
            return
        end

        local Rock = RockTemplate:Clone()
        Rock:SetAttribute("EmoteProperty", true)
        Rock.Name = "Rock"
        Rock.Parent = Character

        local weld = Rock:WaitForChild("Rock", 2)
        if weld and Character.PrimaryPart then
            weld:SetAttribute("EmoteProperty", true)
            weld.Part0 = Character.PrimaryPart
            weld.Part1 = Rock
            weld.Parent = Character.PrimaryPart
        end

        ----------------------------------------------------------------
        -- SOUND DELAY
        ----------------------------------------------------------------
        task.delay(0.573,function()
            if Rock and Rock.Parent then
                local sound = Instance.new("Sound")
                sound.SoundId = "rbxassetid://91571189388577"
                sound.Volume = 1
                sound.RollOffMaxDistance = 100
                sound.Parent = Rock
                sound:Play()
            end
        end)

        ----------------------------------------------------------------
        -- ANIMATION
        ----------------------------------------------------------------
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://123464270068243"
            Humanoid:LoadAnimation(anim):Play()
        end

        ----------------------------------------------------------------
        -- TORSO SOUNDS
        ----------------------------------------------------------------
        local torso = Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso")
        if torso then
            local s1 = Instance.new("Sound")
            s1.SoundId = "rbxassetid://104813362309681"
            s1.Volume = 1
            s1.Parent = torso
            s1:Play()

            task.delay(0.01,function()
                local s2 = Instance.new("Sound")
                s2.SoundId = "rbxassetid://103206475338370"
                s2.Volume = 0.8
                s2.Parent = torso
                s2:Play()
            end)
        end

        ----------------------------------------------------------------
        -- FAKE REPLICATION (VISUAL ONLY)
        ----------------------------------------------------------------
        task.wait(2.4)

        for _,conn in pairs(getconnections(Replication.OnClientEvent)) do
            if conn.Function then
                pcall(function()
                    conn.Function({
                        Effect = "Best Brother",
                        char = Character,
                        Id = targetId,
                    })
                end)
            end
        end

        ----------------------------------------------------------------
        -- HIDE ROCK
        ----------------------------------------------------------------
        if Rock then
            Rock.Transparency = 1
        end

    end
})

-- Final Spark Emote
EmoteTab:Button({
    Title = "Final Spark",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "final_spark",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        -- Animation
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://129361308786827"
        humanoid:LoadAnimation(anim):Play()

        -- VFX
        task.delay(0.1, function()
            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 99999)
            acc:SetAttribute("EmoteProperty", true)
            acc.Parent = character

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "Final Spark",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 129361308786827,
                    RealBind = acc,
                })
            end)
        end)
    end
})

-- Last Will Emote
EmoteTab:Button({
    Title = "Last Will",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "last_will",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        -- Animation
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://113450724032380"
        humanoid:LoadAnimation(anim):Play()

        -- VFX
        task.delay(0.1, function()
            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 99999)
            acc:SetAttribute("EmoteProperty", true)
            acc.Parent = character

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "Last Will",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 113450724032380,
                    RealBind = acc,
                })
            end)
        end)
    end
})

-- The Fallen Finisher Emote
EmoteTab:Button({
    Title = "The Fallen Finisher",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "fallen_finisher",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        -- Sound 1
        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        if torso then
            local sound1 = Instance.new("Sound")
            sound1.SoundId = "rbxassetid://113267998039039"
            sound1.Volume = 1.65
            sound1.Parent = torso
            sound1:Play()
            Debris:AddItem(sound1, 10)
        end

        -- Sound 2
        local sound2 = Instance.new("Sound")
        sound2.SoundId = "rbxassetid://87401852788032"
        sound2.Volume = 1
        sound2.Parent = workspace
        sound2:Play()
        Debris:AddItem(sound2, 10)

        -- Animation
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://95171537920426"
        humanoid:LoadAnimation(anim):Play()

        -- VFX
        task.delay(0.1, function()
            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 99999)
            acc:SetAttribute("EmoteProperty", true)
            acc.Parent = character

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "slice combo",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 95171537920426,
                    RealBind = acc,
                })
            end)
        end)
    end
})

-- ===== INFO TAB =====
InfoTab:Button({
    Title = "Copy Discord Link",
    Desc = "Copy Discord invite link",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/tgK6PfbsN")
            WindUI:Notify({
                Title = "Copied!",
                Content = "Discord link copied to clipboard",
                Duration = 3,
            })
        end
    end
})

InfoTab:Paragraph({
    Title = "UPDATE SCRIPT:",
    Content = "Update weekly ",
})

-- ===== PLAYER TAB =====
-- Boombox Section
local MusicList = {
    ["Ai là người thương em"] = "138017380471511",
}

local musicNames = {}
for name, _ in pairs(MusicList) do
    table.insert(musicNames, name)
end

local SelectedMusic = "Ai là người thương em"
local CurrentVolume = 0.5
local IsLooped = false
local Sound = nil

local function CreateSound()
    if Sound then
        pcall(function()
            Sound:Stop()
            Sound:Destroy()
        end)
    end

    Sound = Instance.new("Sound")
    Sound.Name = "BoomboxSound"
    Sound.Parent = workspace.CurrentCamera
    Sound.Volume = CurrentVolume
    Sound.Looped = IsLooped
    Sound.SoundId = "rbxassetid://" .. MusicList[SelectedMusic]
    Sound:Stop()
end

CreateSound()

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if Sound then
        Sound.Parent = workspace.CurrentCamera
    end
end)

PlayerTab:Dropdown({
    Title = "Select Music",
    Desc = "Choose music to play",
    Values = musicNames,
    Default = "Ai là người thương em",
    Callback = function(selected)
        SelectedMusic = selected
        if Sound then
            Sound.SoundId = "rbxassetid://" .. MusicList[selected]
            Sound:Stop()
            Sound.TimePosition = 0
        end
    end
})

PlayerTab:Button({
    Title = "Play",
    Desc = "Play selected music",
    Callback = function()
        if not Sound then return end
        Sound:Stop()
        Sound.TimePosition = 0
        Sound:Play()
    end
})

PlayerTab:Button({
    Title = "Stop",
    Desc = "Stop music",
    Callback = function()
        if Sound then
            Sound:Stop()
        end
    end
})

PlayerTab:Toggle({
    Title = "Loop",
    Desc = "Loop current music",
    Callback = function(Value)
        IsLooped = Value
        if Sound then
            Sound.Looped = Value
        end
    end
})

PlayerTab:Slider({
    Title = "Volume",
    Desc = "Adjust volume",
    Min = 0,
    Max = 150,
    Default = 50,
    Callback = function(Value)
        CurrentVolume = Value / 100
        if Sound then
            Sound.Volume = CurrentVolume
        end
    end
})

-- Visual Section
PlayerTab:Button({
    Title = "Golden Shoulder",
    Desc = "Add golden shoulder accessory",
    Callback = function()
        local char = LocalPlayer.Character
        if not char then return end

        local old = char:FindFirstChild("GoldenShoulder")
        if old then old:Destroy() end

        local acc = Instance.new("Accessory")
        acc.Name = "GoldenShoulder"
        acc.Parent = char

        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(1, 1, 1)
        handle.Anchored = false
        handle.Massless = true
        handle.CanCollide = false
        handle.Parent = acc

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshId = "rbxassetid://4307568890"
        mesh.TextureId = "rbxassetid://4307568951"
        mesh.Scale = Vector3.new(1, 1, 1)
        mesh.Parent = handle

        local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightUpperArm")
        if rightArm then
            local weld = Instance.new("Weld")
            weld.Part0 = handle
            weld.Part1 = rightArm
            weld.C0 = CFrame.new(-0.6, -1.3, 0)
            weld.Parent = handle
        end
    end
})

PlayerTab:Input({
    Title = "Kill Sound ID",
    Desc = "Sound ID to play on kill",
    Placeholder = "Enter Sound ID",
    Callback = function(text)
        text = tostring(text):gsub("%s+", "")
        if text == "" then return end
        
        local soundId = "rbxassetid://" .. text
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 1
        sound.Parent = SoundService
        
        local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
        if leaderstats then
            local kills = leaderstats:FindFirstChild("Kills")
            if kills then
                kills:GetPropertyChangedSignal("Value"):Connect(function()
                    local soundClone = sound:Clone()
                    soundClone.Parent = workspace.CurrentCamera
                    soundClone:Play()
                    Debris:AddItem(soundClone, 5)
                end)
            end
        end
    end
})

PlayerTab:Button({
    Title = "Fix Lag MAX (Boost)",
    Desc = "Maximum FPS boost",
    Callback = function()
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then
                v.Enabled = false
            end
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e9
        Lighting.Brightness = 1

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Explosion") or obj:IsA("Highlight") then
                pcall(function()
                    obj.Enabled = false
                    obj:Destroy()
                end)
            end
            if obj:IsA("BasePart") then
                obj.CastShadow = false
                obj.Material = Enum.Material.Plastic
                obj.Reflectance = 0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
        end

        local map = workspace:FindFirstChild("Map")
        if map then
            local treesFolder = map:FindFirstChild("Trees")
            if treesFolder then
                for _, tree in ipairs(treesFolder:GetChildren()) do
                    if tree:IsA("Model") and tree.Name == "Tree" then
                        tree:Destroy()
                    end
                end
            end
        end

        WindUI:Notify({
            Title = "Fix Lag",
            Content = "MAX Boost Enabled",
            Duration = 3,
        })
    end
})

-- ===== HOP TAB =====
local function formatTime(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = math.floor(sec % 60)
    return string.format("%02dh %02dm %02ds", h, m, s)
end

HopTab:Paragraph({
    Title = "Server Info",
    Content = "Loading...",
})

task.spawn(function()
    while true do
        local currentPlayers = #Players:GetPlayers()
        local maxPlayers = Players.MaxPlayers
        local placeId = game.PlaceId
        local jobId = game.JobId
        local uptime = workspace.DistributedGameTime
        
        for _, element in ipairs(HopTab:GetChildren()) do
            if element:IsA("Paragraph") and element.Title == "Server Info" then
                element.Content = "Players: " .. currentPlayers .. "/" .. maxPlayers ..
                    "\nPlaceId: " .. placeId ..
                    "\nSession Time: " .. formatTime(uptime) ..
                    "\nJobId: " .. jobId
                break
            end
        end
        task.wait(1)
    end
end)

HopTab:Button({
    Title = "Copy JobId",
    Desc = "Copy current server JobId",
    Callback = function()
        if setclipboard then
            setclipboard(game.JobId)
            WindUI:Notify({
                Title = "Copied!",
                Content = "JobId copied to clipboard",
                Duration = 2,
            })
        end
    end
})

HopTab:Button({
    Title = "Rejoin Server",
    Desc = "Rejoin current server",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId)
        end)
    end
})

HopTab:Button({
    Title = "Hop Server (Random)",
    Desc = "Join random server",
    Callback = function()
        local function getServers(maxPages)
            local servers = {}
            local cursor = ""
            local pages = 0

            repeat
                pages = pages + 1
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. cursor or "")
                local success, res = pcall(function()
                    return HttpService:JSONDecode(game:HttpGet(url))
                end)

                if not success or not res or not res.data then break end

                for _, srv in ipairs(res.data) do
                    if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then                        table.insert(servers, srv)
                    end
                end

                cursor = res.nextPageCursor
            until not cursor or pages >= (maxPages or 5)

            return servers
        end

        local servers = getServers(6)
        if #servers > 0 then
            local pick = servers[math.random(1, #servers)]
            task.wait(0.2)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, LocalPlayer)
        end
    end
})

HopTab:Button({
    Title = "Anti AFK",
    Desc = "Anti AFK",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/23rycg2Q/raw"))()
    end
})

HopTab:Input({
    Title = "Join by JobID",
    Desc = "Join server using JobId",
    Placeholder = "Paste JobId...",
    Callback = function(text)
        if text and text ~= "" then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, text, LocalPlayer)
        end
    end
})

task.spawn(function()
    local colors = {"#FF0000", "#0066FF", "#000000"}
    local i = 1
    while true do
        Window:SetTitle(string.format("<font color='%s'>✦ ThanhDuyHub | TSB ✦</font>", colors[i]))
        i = i % 3 + 1
        task.wait(0.5)
    end
end)

-- Final notification
WindUI:Notify({
    Title = "ThanhDuy Hub",
    Content = "Loaded successfully!",
    Duration = 3,
})