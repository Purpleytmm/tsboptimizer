-- Global Settings
getgenv().Settings = {
    Limb = {
        Arms = true,
        Legs = true
    },
    AntiLag = {
        PartsPerTick = 45,
        ScanInterval = 2
    },
    FreecamKey = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}
}

-- Shared Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = workspace

-- Registry Systems
local cutsceneRegistry = {}
local executed = getgenv().executed

-- Body parts protection list
local bodyParts = {
    head = true, torso = true, humanoidrootpart = true,
    leftarm = true, rightarm = true, leftleg = true, rightleg = true
}

-- Protection system
local function isAncestorProtected(obj)
    local current = obj
    while current and current ~= game do
        local lowerName = string.lower(current.Name)
        if lowerName == "omnidirectionalpunchcutscene" or lowerName == "omnidirectionalpunchfolder" then
            return true
        end
        current = current.Parent
    end
    return false
end

local function isProtected(obj)
    if not obj or not obj.Name then return false end
    
    local lowerName = string.lower(obj.Name)
    
    -- Protect specific names
    if lowerName == "frozen" or lowerName == "soul" or lowerName == "meteor" or lowerName == "frozensoul" then
        return true
    end
    
    -- Protect by ancestors
    if isAncestorProtected(obj) then return true end
    
    -- Character model protection
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Humanoid") then return true end
    
    -- Body parts protection
    if bodyParts[lowerName] then return true end
    
    -- White line in cutscenes
    if lowerName == "whiteline" then
        local cutsceneModel = obj:FindFirstAncestorWhichIsA("Model")
        if cutsceneModel then
            if not cutsceneRegistry[cutsceneModel] then
                cutsceneRegistry[cutsceneModel] = true
                return true
            end
            return false
        end
    end
    
    return not (lowerName:find("afterimage") or lowerName:find("flowingwater"))
end

-- Cleanup queue
local cleanupQueue = {}
local queuePointer = 1

local function CleanWorld()
    local descendants = Workspace:GetDescendants()
    for i = 1, #descendants do
        local obj = descendants[i]
        if obj:IsA("BasePart") and not isProtected(obj) and not obj.Anchored and not obj:FindFirstChildWhichIsA("Hitbox") then
            table.insert(cleanupQueue, obj)
        end
        if i % 75 == 0 then task.wait() end
    end
end

-- Character System
local function UpdateLimbs(character)
    if not character then return end
    
    pcall(function()
        if not Settings.Limb.Arms then
            if character:FindFirstChild("Left Arm") then character["Left Arm"]:Destroy() end
            if character:FindFirstChild("Right Arm") then character["Right Arm"]:Destroy() end
        end
        if not Settings.Limb.Legs then
            if character:FindFirstChild("Left Leg") then character["Left Leg"]:Destroy() end
            if character:FindFirstChild("Right Leg") then character["Right Leg"]:Destroy() end
        end
    end)
end

-- Respawn System
local function respawn(plr)
    local char = plr.Character
    if char:FindFirstChildOfClass("Humanoid") then 
        char:FindFirstChildOfClass("Humanoid"):ChangeState(15) 
    end
    char:ClearAllChildren()
    local newChar = Instance.new("Model")
    newChar.Parent = workspace
    plr.Character = newChar
    task.wait()
    plr.Character = char
    newChar:Destroy()
end

local function refresh(plr)
    local Human = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid", true)
    local pos = Human and Human.RootPart and Human.RootPart.CFrame
    local pos1 = workspace.CurrentCamera.CFrame
    respawn(plr)
    task.spawn(function()
        workspace.CurrentCamera.CFrame = wait() and pos1
    end)
end

-- Character Processing
local function ProcessCharacter(char)
    char:WaitForChild("HumanoidRootPart")
    UpdateLimbs(char)
    
    char.HumanoidRootPart.ChildAdded:Connect(function(child)
        if child.Name == "dodgevelocity" then
            task.spawn(function()
                local Dodge = true
                local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if PlayerGui then
                    local ScreenGui = PlayerGui:FindFirstChild("ScreenGui")
                    if ScreenGui then
                        local MagicHealth = ScreenGui:FindFirstChild("MagicHealth")
                        if MagicHealth then
                            local Health = MagicHealth:FindFirstChild("Health")
                            if Health then
                                local Glow = Health:FindFirstChild("Glow")
                                if Glow then
                                    for i = 1.975, 0, -1 do
                                        if not Dodge then break end
                                        Glow.ImageColor3 = Color3.fromRGB(255, 255, 255)
                                        task.wait(1)
                                        Glow.ImageColor3 = Color3.fromRGB(0, 0, 0)
                                    end
                                    Dodge = false
                                end
                            end
                        end
                    end
                end
            end)
        elseif (child.Name == "moveme" or child.Name == "Sound") then
            task.spawn(function()
                local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if PlayerGui then
                    local ScreenGui = PlayerGui:FindFirstChild("ScreenGui")
                    if ScreenGui then
                        local MagicHealth = ScreenGui:FindFirstChild("MagicHealth")
                        if MagicHealth then
                            local Text = MagicHealth:FindFirstChild("TextLabel")
                            if Text then
                                for i = 3.975, 0, -1 do
                                    Text.TextColor3 = Color3.fromRGB(255, 50, 50)
                                    task.wait(1)
                                    Text.TextColor3 = Color3.fromRGB(255, 255, 255)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
end

-- Hook Systems
local oldIndex
oldIndex = hookmetamethod(game, "__newindex", function(self, k, v)
    if k == "Parent" then
        if v == Workspace.Thrown or self:IsA("ParticleEmitter") then
            pcall(function() self:Destroy() end)
            return nil
        end
    end
    return oldIndex(self, k, v)
end)

local oldCall
oldCall = hookmetamethod(game, "__namecall", function(self, ...)
    local method, args = getnamecallmethod(), {...}
    if self.Name == "Communicate" and method == "FireServer" and args[1]["Goal"] == "Reset" then
        task.spawn(function()
            respawn(LocalPlayer)
        end)
    end
    return oldCall(self, ...)
end)

-- Thrown Object Handling
Workspace:WaitForChild("Thrown").ChildAdded:Connect(function(obj)
    task.wait()
    if obj:IsA("BasePart") and not obj.Anchored and not obj:FindFirstChildWhichIsA("Hitbox") and not isProtected(obj) then
        pcall(function() obj:Destroy() end)
    end
end)

-- Main Loop
RunService.Heartbeat:Connect(function()
    for _ = 1, Settings.AntiLag.PartsPerTick do
        if cleanupQueue[queuePointer] then
            pcall(function() 
                if cleanupQueue[queuePointer] and cleanupQueue[queuePointer].Parent then
                    cleanupQueue[queuePointer]:Destroy() 
                end
            end)
            queuePointer = queuePointer + 1
        else
            if #cleanupQueue > 0 then
                table.clear(cleanupQueue)
            end
            queuePointer = 1
            break
        end
    end

    if LocalPlayer.Character then
        UpdateLimbs(LocalPlayer.Character)
    end
end)

-- Freecam Toggle
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Settings.FreecamKey[2] and UserInputService:IsKeyDown(Settings.FreecamKey[1]) then
        local currentCamera = Workspace.CurrentCamera
        if currentCamera then
            currentCamera.CameraType = (currentCamera.CameraType == Enum.CameraType.Custom) and Enum.CameraType.Scriptable or Enum.CameraType.Custom
        end
    end
end)

-- Initialization
if not executed then
    LocalPlayer.CharacterAdded:Connect(ProcessCharacter)
    
    if LocalPlayer.Character then
        ProcessCharacter(LocalPlayer.Character)
    end
    
    task.spawn(function()
        while task.wait(Settings.AntiLag.ScanInterval) do
            CleanWorld()
        end
    end)
    
    collectgarbage("setpause", 150)
    collectgarbage("setstepmul", 250)
    
    getgenv().executed = true
end
