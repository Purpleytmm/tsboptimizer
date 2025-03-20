-- Simple cleanup script with minimal overhead
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = workspace

-- Configuration
getgenv().Settings = {
    Limb = {
        Arms = true,
        Legs = true
    },
    AntiLag = {
        PartsPerTick = 35 -- Reduced from 45 to prevent stutters
        ScanInterval = 2  -- Increased from 2 to reduce scanning frequency
    },
    FreecamKey = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}
}

-- Protected names (lowercase for efficiency)
local protectedNames = {
    ["frozen"] = true,
    ["soul"] = true,
    ["meteor"] = true,
    ["frozensoul"] = true,
    ["head"] = true,
    ["torso"] = true,
    ["humanoidrootpart"] = true,
    ["leftarm"] = true,
    ["rightarm"] = true,
    ["leftleg"] = true,
    ["rightleg"] = true
}

-- Protected phrases for ancestors
local protectedPhrases = {
    "omnidirectional",
    "punch",
    "cutscene"
}

-- Simple protection check
local function isProtected(obj)
    -- Check if object itself is protected
    if protectedNames[string.lower(obj.Name)] then
        return true
    end
    
    -- Check if object is part of a character
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then
        return true
    end
    
    -- Check if object is part of a protected cutscene
    local lowName = string.lower(obj.Name)
    for _, phrase in ipairs(protectedPhrases) do
        if lowName:find(phrase) then
            return true
        end
    end
    
    -- Check ancestors for protected names
    local parent = obj.Parent
    local checkCount = 0
    while parent and checkCount < 3 do -- Limit ancestor checks to prevent deep recursion
        local parentName = string.lower(parent.Name)
        for _, phrase in ipairs(protectedPhrases) do
            if parentName:find(phrase) then
                return true
            end
        end
        parent = parent.Parent
        checkCount = checkCount + 1
    end
    
    return false
end

-- Character functions
local function UpdateLimbs(character)
    if not character then return end
    
    if not Settings.Limb.Arms then
        if character:FindFirstChild("Left Arm") then
            character["Left Arm"]:Destroy()
        end
        if character:FindFirstChild("Right Arm") then
            character["Right Arm"]:Destroy()
        end
    end
    
    if not Settings.Limb.Legs then
        if character:FindFirstChild("Left Leg") then
            character["Left Leg"]:Destroy()
        end
        if character:FindFirstChild("Right Leg") then
            character["Right Leg"]:Destroy()
        end
    end
end

local function ProcessCharacter(character)
    if not character then return end
    local rootPart = character:WaitForChild("HumanoidRootPart", 3)
    if not rootPart then return end
    
    UpdateLimbs(character)
    
    rootPart.ChildAdded:Connect(function(child)
        if child.Name == "dodgevelocity" then
            local gui = LocalPlayer:FindFirstChild("PlayerGui")
            if not gui then return end
            
            local screenGui = gui:FindFirstChild("ScreenGui")
            if not screenGui then return end
            
            local magicHealth = screenGui:FindFirstChild("MagicHealth")
            if not magicHealth then return end
            
            local health = magicHealth:FindFirstChild("Health")
            if not health then return end
            
            local glow = health:FindFirstChild("Glow")
            if glow then
                glow.ImageColor3 = Color3.new(1, 1, 1)
                task.delay(1.975, function()
                    glow.ImageColor3 = Color3.new(0, 0, 0)
                end)
            end
        end
    end)
end

-- Respawn function
local function respawn(player)
    local char = player.Character
    if not char then return end
    
    if char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid"):ChangeState(15)
    end
    char:ClearAllChildren()
    
    local newChar = Instance.new("Model")
    newChar.Parent = workspace
    player.Character = newChar
    task.wait()
    player.Character = char
    newChar:Destroy()
end

-- Direct cleaning instead of queuing
local function CleanDebris()
    local toRemove = {}
    local count = 0
    
    -- First, collect debris to remove (faster than destroying during iteration)
    for _, obj in pairs(Workspace.Thrown:GetChildren()) do
        if obj:IsA("BasePart") and not isProtected(obj) then
            count = count + 1
            toRemove[count] = obj
        end
        if count >= Settings.AntiLag.PartsPerTick then break end
    end
    
    -- Then destroy collected objects
    for i = 1, count do
        pcall(function()
            toRemove[i]:Destroy()
        end)
    end
end

-- Minimal hooks
local oldIndex
oldIndex = hookmetamethod(game, "__newindex", function(self, k, v)
    if k == "Parent" and v == Workspace.Thrown then
        pcall(function() self:Destroy() end)
        return nil
    end
    return oldIndex(self, k, v)
end)

local oldCall
oldCall = hookmetamethod(game, "__namecall", function(self, ...)
    local method, args = getnamecallmethod(), {...}
    if self.Name == "Communicate" and method == "FireServer" and args[1] and args[1]["Goal"] == "Reset" then
        task.spawn(function()
            respawn(LocalPlayer)
        end)
    end
    return oldCall(self, ...)
end)

-- Simplified cleanup for thrown objects
Workspace:WaitForChild("Thrown").ChildAdded:Connect(function(obj)
    if obj:IsA("BasePart") and not isProtected(obj) then
        task.delay(0.1, function() -- Small delay to ensure the object is fully set up
            pcall(function() 
                if obj and obj.Parent then
                    obj:Destroy()
                end
            end)
        end)
    end
end)

-- Main cleanup loop
task.spawn(function()
    while task.wait(0.5) do -- Run more frequently but do less per cycle
        CleanDebris()
    end
end)

-- Character handling
LocalPlayer.CharacterAdded:Connect(ProcessCharacter)
if LocalPlayer.Character then
    ProcessCharacter(LocalPlayer.Character)
end

-- Freecam feature
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Settings.FreecamKey[2] and UserInputService:IsKeyDown(Settings.FreecamKey[1]) then
        local camera = Workspace.CurrentCamera
        if camera then
            camera.CameraType = (camera.CameraType == Enum.CameraType.Custom) and 
                Enum.CameraType.Scriptable or Enum.CameraType.Custom
        end
    end
end)

-- Memory optimization
task.spawn(function()
    while wait(30) do
        collectgarbage("collect")
    end
end)

print("Cleanup script loaded successfully")
