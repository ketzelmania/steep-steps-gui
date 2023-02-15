local CAS = game:GetService("ContextActionService")
local Actions = {
    All = "All",
    Jump = "Jump",
    Dash = "Dash",
    GetLadder = "GetLadder",
    FlingLadder = "FlingLadder",
    Noclip = "Noclip",
    PlaceLadder = "PlaceLadder"
}

pcall(function()
    _G.FogConn:Disconnect()
    _G.PlayerAddedConn:Disconnect()
    _G.WalkVelocityConn:Disconnect()
    _G.ActionVariables.NoclipYLock:Destroy()
    _G.ActionVariables.NoclipConnection:Disconnect()

    for i in pairs(Actions) do
        CAS:UnbindAction(i)
    end
end)

--\\ put "--[[" below and execute to disable everything
--

--|| SETTINGS ||--

local DashVelocity = 100
local JumpVelocity = 50
local AdditiveJump = false

local WalkSpeedBonusMultiplier = 0
local CFrameWalkOnly = false
local CFrameWalkEnabled = true

local FlingVelocity = 150
local FlingRotationalVelocity = 50
local FlingTime = 0.6

local LadderCollectTime = 0.5
local RemovingFog = false


--|| KEYCODES ||--

local ActionKeyCodes = {
    Jump = Enum.KeyCode.Space,
    Dash = Enum.KeyCode.Q,
    GetLadder = Enum.KeyCode.V,
    FlingLadder = Enum.KeyCode.E,
    Noclip = Enum.KeyCode.LeftAlt,
    PlaceLadder = Enum.KeyCode.F
}


--|| ACTIONS ||--

local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Player.Character:WaitForChild("Humanoid")

_G.PlayerAddedConn = Player.CharacterAdded:Connect(function()
    Character = Player.Character
    Humanoid = Character:WaitForChild("Humanoid")

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
end)

local BindFunctions = {
    Jump = function()
        local CV = Player.Character.Torso.AssemblyLinearVelocity
        
        Player.Character.Torso.AssemblyLinearVelocity = Vector3.new(CV.X,JumpVelocity,CV.Z)
    end,
    Dash = function()
        local Torso = Character:FindFirstChild("Torso")
        if not Torso then return end

        Torso.AssemblyLinearVelocity += (Player.Character.Humanoid.MoveDirection + Vector3.new(0,0,0)) * DashVelocity
    end,
    GetLadder = function()
        local OriginalToolUnequipped

        if not workspace.live:FindFirstChild(Player.Name):FindFirstChild("Ladder") then
            Humanoid:EquipTool(Player.Backpack.Ladder)
            OriginalToolUnequipped = true
        end

        local OriginalPosition = Character.PrimaryPart.CFrame

        local PlayerLadderFolder = workspace:WaitForChild("playerPlaced")
        local PlayerLadder

        for i,v in pairs(PlayerLadderFolder:GetChildren()) do
            if string.find(v.Name, Player.Name) then
                PlayerLadder = v
            end
        end

        if not PlayerLadder then return end

        local NoCollideConn = game:GetService("RunService").Stepped:Connect(function()
            for i,v in pairs(Character:GetDescendants()) do
                if v:IsA("BasePart") or v:IsA("Part") or v:IsA("MeshPart") then
                    v.CanCollide = false
                end
            end
        end)

        local totalDT = 0
        repeat
            Character:PivotTo(PlayerLadder.PrimaryPart.CFrame * CFrame.new(0,0,2))
            totalDT += task.wait()
        until
            totalDT > 0.2

        pcall(function()
            workspace.live.Cogniscient.Ladder.Event:FireServer("Destroy", PlayerLadder)
        end)

        totalDT = 0
        repeat
            Character:PivotTo(PlayerLadder.PrimaryPart.CFrame * CFrame.new(0,0,2))
            totalDT += task.wait()
        until
            not PlayerLadder or not PlayerLadder.Parent or totalDT > LadderCollectTime

        Character:PivotTo(OriginalPosition)
        Character:FindFirstChild("Torso").AssemblyLinearVelocity = Vector3.new()

        NoCollideConn:Disconnect()

        if OriginalToolUnequipped then
            Humanoid:UnequipTools()
        end
    end,
    FlingLadder = function()
        local Mouse = Player:GetMouse()
        local Target = Mouse.Target
        if not Target then return end
        if not Target:IsDescendantOf(workspace:WaitForChild("playerPlaced")) then return end
        
        local LadderModel = Target:FindFirstAncestorOfClass("Model")
        
        local OriginalPosition = Player.Character.PrimaryPart.CFrame
        local DesiredVelocityDirection = OriginalPosition.LookVector
        
        local totalDT = 0
        
        repeat
            pcall(function()
                totalDT += task.wait()
                Player.Character:PivotTo(LadderModel.PrimaryPart.CFrame)
                Player.Character.Torso.AssemblyLinearVelocity = DesiredVelocityDirection * FlingVelocity
                Player.Character.Torso.AssemblyAngularVelocity = Vector3.new(0,0,FlingRotationalVelocity)
            end)
        until
            totalDT >= FlingTime
        
        task.wait(0.05)
        Player.Character.Torso.AssemblyLinearVelocity = Vector3.new()
        Player.Character:PivotTo(OriginalPosition)
        task.wait(0.1)
    end,
    Noclip = function()
        _G.ActionVariables.NoclipToggled = not _G.ActionVariables.NoclipToggled
        
        if _G.ActionVariables.NoclipToggled then
            
            do
                local CV = Character.Torso.AssemblyLinearVelocity
                Character.Torso.AssemblyLinearVelocity = Vector3.new(CV.X, 0, CV.Z)
            end
            
            _G.ActionVariables.NoclipYLock.Parent = workspace
            _G.ActionVariables.YLockPosition = Character.PrimaryPart.Position.Y - 5
            
            _G.ActionVariables.NoclipConnection = game:GetService("RunService").Stepped:Connect(function()
                
                for i,v in pairs(Character:GetDescendants()) do
                    if v:IsA("BasePart") or v:IsA("Part") or v:IsA("MeshPart") then
                        v.CanCollide = false
                    end
                end
                
                _G.ActionVariables.NoclipYLock.CFrame = CFrame.new(Character.PrimaryPart.Position.X,_G.ActionVariables.YLockPosition,Character.PrimaryPart.Position.Z)
                
            end)
        else
            pcall(function()
                _G.ActionVariables.NoclipConnection:Disconnect()
            end)
            
            _G.ActionVariables.NoclipYLock.Parent = nil
        end
    end,
    PlaceLadder = function()
        local PlayerLadderFolder = workspace:WaitForChild("playerPlaced")
        local PlayerLadder

        for i,v in pairs(PlayerLadderFolder:GetChildren()) do
            if string.find(v.Name, Player.Name) then
                PlayerLadder = v
            end
        end

        if PlayerLadder then return end

        local Mouse = Player:GetMouse()
        local MousePos = Mouse.Hit.Position
        if not MousePos then return end

        local DesiredLadderPosition = CFrame.new(MousePos.X, MousePos.Y + 6, MousePos.Z)
        local DesiredLadderCFrame = Character.PrimaryPart.CFrame - Character.PrimaryPart.CFrame.Position + DesiredLadderPosition.Position

        local CharacterOffset = DesiredLadderCFrame * CFrame.new(0,0,4)
        local OriginalPosition = Character.PrimaryPart.CFrame

        if Player.Backpack:FindFirstChild("Ladder") then
            Humanoid:EquipTool(Player.Backpack.Ladder)
        end
        
        local NoCollideConn = game:GetService("RunService").Stepped:Connect(function()
            for i,v in pairs(Character:GetDescendants()) do
                if v:IsA("BasePart") or v:IsA("Part") or v:IsA("MeshPart") then
                    v.CanCollide = false
                end
            end
        end)

        do
            local totalDT = 0

            repeat
                Character:PivotTo(CharacterOffset)
                Character.Torso.AssemblyLinearVelocity = Vector3.new()
                totalDT += task.wait()
            until
                totalDT > 0.2
        end

        Character.Ladder.Event:FireServer("Create")
        repeat
            task.wait()
            Character:PivotTo(CharacterOffset)
            Character.Torso.AssemblyLinearVelocity = Vector3.new()

            local PlayerLadder

            for i,v in pairs(PlayerLadderFolder:GetChildren()) do
                if string.find(v.Name, Player.Name) then
                    PlayerLadder = v
                end
            end
        until
            PlayerLadder

        NoCollideConn:Disconnect()

        Character:PivotTo(OriginalPosition)
    end
}

--|| GUI INSTANTIATION ||--

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Steep Steps", "Synapse")

do
    --\\ ladder section
    local LadderTab = Window:NewTab("Ladder")
    local RetrieveSection = LadderTab:NewSection("Retrieve Ladder")

    RetrieveSection:NewButton("Get Ladder", "Teleports you to your ladder and picks it up.", function()
        BindFunctions.GetLadder()
    end)

    RetrieveSection:NewTextBox("Get Ladder Bind", "Utilizes Enum.KeyCode.", function(txt)
        ActionKeyCodes.GetLadder = Enum.KeyCode[txt] or Enum.KeyCode.End
        AssignBinds(Actions.GetLadder)
    end)

    RetrieveSection:NewSlider("Get Ladder Time", "Changes timeout (ms).", 1000, 0, function(s)
        LadderCollectTime = s/1000
    end)

    local FlingSection = LadderTab:NewSection("Fling Ladder")

    FlingSection:NewTextBox("Fling Ladder Bind", "Flings the ladder at your mouse.", function(txt)
        ActionKeyCodes.FlingLadder = Enum.KeyCode[txt] or Enum.KeyCode.End
        AssignBinds(Actions.FlingLadder)
    end)

    FlingSection:NewSlider("Fling Velocity", "Changes torso fling velocity.", 1000, 0, function(s)
        FlingVelocity = s
    end)

    FlingSection:NewSlider("Fling RotVel", "Changes torso rotational velocity.", 500, 0, function(s)
        FlingRotationalVelocity = s
    end)

    FlingSection:NewSlider("Fling Time", "Changes the duration (ms).", 1000, 0, function(s)
        FlingTime = s/1000
    end)

    local PlaceSection = LadderTab:NewSection("Place Ladder")

    PlaceSection:NewTextBox("Place Ladder Bind", "Places ladder at mouse.", function(txt)
        ActionKeyCodes.PlaceLadder = Enum.KeyCode[txt] or Enum.KeyCode.End
        AssignBinds(Actions.PlaceLadder)
    end)

    --\\

    --\\ player section

    local PlayerTab = Window:NewTab("Player")
    local JumpSection = PlayerTab:NewSection("Jump")

    JumpSection:NewTextBox("Jump Keybind", "Applies an upwards velocity to the torso.", function(txt)
        ActionKeyCodes.Jump = Enum.KeyCode[txt] or Enum.KeyCode.End
        AssignBinds(Actions.Jump)
    end)

    JumpSection:NewSlider("Jump Velocity", "Changes jump velocity.", 250, 0, function(s)
        JumpVelocity = s
    end)

    JumpSection:NewToggle("Additive Jump Velocity", "Toggles adding (+=) and setting (=) JumpVel.", function(state)
        AdditiveJump = state
    end)

    local DashSection = PlayerTab:NewSection("Dash")
    
    DashSection:NewTextBox("Dash Keybind", "Applies a horizontal velocity to the torso.", function(txt)
        ActionKeyCodes.Dash = Enum.KeyCode[txt] or Enum.KeyCode.End
        AssignBinds(Actions.Dash)
    end)

    DashSection:NewSlider("Dash Velocity", "Changes dash velocity.", 500, 50, function(s)
        DashVelocity = s
    end)

    local WalkSection = PlayerTab:NewSection("Movement")

    WalkSection:NewSlider("Walk Speed Bonus", "Changes CFrame multiplier.", 150, 0, function(s)
        WalkSpeedBonusMultiplier = s
    end)

    WalkSection:NewToggle("CFrame Walk Only", "Toggles regular horizontal velocity.", function(state)
        CFrameWalkOnly = state
    end)

    WalkSection:NewToggle("CFrame Walk Enabled", "Toggles CFrame walking.", function(state)
        CFrameWalkEnabled = state
    end)

    WalkSection:NewTextBox("Noclip Keybind", "Toggles collision and locks Y.", function(txt)
        ActionKeyCodes.Noclip = Enum.KeyCode[txt] or Enum.KeyCode.End
        AssignBinds(Actions.Noclip)
    end)

    local TeleportSection = PlayerTab:NewSection("Teleport")
    
    TeleportSection:NewTextBox("Teleport to Meter", "Teleports to a checkpoint. Enter meter number.", function(txt)
        local Checkpoints = {
            [0] = "start",
            [100] = "castle",
            [200] = "town",
            [300] = "bluehouse",
            [400] = "castle2",
            [500] = "watchtower",
            [600] = "village",
            [700] = "castle700m",
            [800] = "wizardtower",
            [900] = "mushroomvillage",
            [1000] = "floatingisland"
        }

        if not tonumber(txt) then return end

        for i,v in pairs(workspace.NPCs:GetChildren()) do
            if v.Name == "Spawnpoint" and v.spawnpointID.Value == Checkpoints[tonumber(txt)] then
                local totaldt = 0

                repeat
                    game.Players.LocalPlayer.Character:PivotTo(v.Interact.CFrame)
                    totaldt += task.wait()
                until
                    totaldt > 1
        
                fireclickdetector(v.Interact.talk)
        
                break
            end
        end
    end)

    --\\

    --\\ misc section

    local MiscTab = Window:NewTab("Misc")
    local MiscSection = MiscTab:NewSection("Misc")

    MiscSection:NewButton("Unbind All", "Unbinds everything.", function()
        for i in pairs(Actions) do
            CAS:UnbindAction(i)
        end
    end)

    MiscSection:NewToggle("Remove Fog Loop", "Toggles remove fog loop.", function(state)
        RemovingFog = state
    end)

    local OtherScripts = MiscTab:NewSection("Other Scripts")

    OtherScripts:NewButton("Unnamed ESP", "Opens Unnamed ESP.", function()
        pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua'))() end)
    end)

    OtherScripts:NewButton("Infinite Yield", "Open Infinite Yield", function()
        pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end)
    end)
end

--|| MISC ||--

_G.WalkVelocityConn = game:GetService("RunService").RenderStepped:Connect(function(dt)
    if CFrameWalkOnly then
        Character.Torso.AssemblyLinearVelocity = Vector3.new(0, Character.Torso.AssemblyLinearVelocity.Y, 0)
        return
    end
    Character:PivotTo(Character.PrimaryPart.CFrame + Humanoid.MoveDirection * dt * WalkSpeedBonusMultiplier * (CFrameWalkEnabled and 1 or 0))
end)

_G.FogConn = game:GetService("RunService").RenderStepped:Connect(function()
    if not RemovingFog then return end

    pcall(function()
        game.Lighting.Fog:Destroy()
    end)
    game.Lighting.FogEnd = 10000
    game.Lighting.FogStart = 10000
    
    Player.CameraMaxZoomDistance = 10000
    Player.CameraMinZoomDistance = 0
end)


_G.ActionVariables = {
    NoclipToggled = false,
    NoclipConnection = nil,
    NoclipYLock = Instance.new("Part"),
    YLockPosition = 0,
}

_G.ActionVariables.NoclipYLock = Instance.new("Part")
_G.ActionVariables.NoclipYLock.Parent = nil
_G.ActionVariables.NoclipYLock.Size = Vector3.new(4,1,4)
_G.ActionVariables.NoclipYLock.Anchored = true
_G.ActionVariables.NoclipYLock.Transparency = 0.5
_G.ActionVariables.NoclipYLock.Color = Color3.new(0,.5,0)
_G.ActionVariables.NoclipYLock.Material = Enum.Material.Cobblestone

function AssignBinds(ActionType)
    if ActionType == Actions.All then
        for i,v in pairs(BindFunctions) do
            CAS:BindAction(i, function(_, UIS)
                if UIS ~= Enum.UserInputState.Begin then return end
                v()
            end, false, ActionKeyCodes[i])
        end
    else
        CAS:BindAction(ActionType, function(_, UIS)
            if UIS ~= Enum.UserInputState.Begin then return end
            BindFunctions[ActionType]()
        end, false, ActionKeyCodes[ActionType])
    end
end

AssignBinds(Actions.All)

--]]