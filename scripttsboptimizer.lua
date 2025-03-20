-- Global Settings
if not getgenv().Settings then
    getgenv().Settings = {}
end

local defaultSettings = {
    Limb = { Arms = true, Legs = true },
    AntiLag = { PartsPerTick = 38, ScanInterval = 2 },
    FreecamKey = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}
}

for key, value in pairs(defaultSettings) do
    if getgenv().Settings[key] == nil then
        getgenv().Settings[key] = value
    end
end
local Settings = getgenv().Settings

-- Essential variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local canClean = true

-- Helper function
local function Print(...)
    print("[XPurpleYT]:", ...)
end

-- Respawn functions
local function respawn(plr)
    if not plr or not plr.Character then return end
    local char = plr.Character
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:ChangeState(15)
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
    if not plr or not plr.Character then return end
    local Human = plr.Character:FindFirstChildOfClass("Humanoid")
    local pos = Human and Human.RootPart and Human.RootPart.CFrame
    local pos1 = workspace.CurrentCamera.CFrame
    respawn(plr)
    task.spawn(function()
        workspace.CurrentCamera.CFrame = pos1
    end)
end

-- Notification
local function CreateNotification()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XPurpleNotification"
    
    -- Use CoreGui if possible, fallback to PlayerGui
    local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
    local parent = (success and coreGui) or LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not parent then
        Print("Nenhum parent GUI encontrado!")
        return
    end
    screenGui.Parent = parent
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 250, 0, 70)
    mainFrame.Position = UDim2.new(1, 300, 0.8, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "XPurple Anti-Lag"
    title.TextColor3 = Color3.fromRGB(255, 100, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = mainFrame
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -20, 0, 20)
    text.Position = UDim2.new(0, 10, 0, 35)
    text.BackgroundTransparency = 1
    text.Text = "Iniciado com sucesso!"
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.Font = Enum.Font.Gotham
    text.TextSize = 14
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = mainFrame
    
    mainFrame:TweenPosition(
        UDim2.new(1, -260, 0.8, 0),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.5,
        true
    )
    
    task.delay(5, function()
        mainFrame:TweenPosition(
            UDim2.new(1, 300, 0.8, 0),
            Enum.EasingDirection.In,
            Enum.EasingStyle.Quad,
            0.5,
            false,
            function()
                if screenGui then
                    screenGui:Destroy()
                end
            end
        )
    end)
end

-- Debris cleaning system
local function IsDebris(part)
    if not part or not part:IsA("BasePart") then return false end
    
    local character = part:FindFirstAncestorOfClass("Model")
    if character and character:FindFirstChildOfClass("Humanoid") then
        return false
    end
    
    if not part.Anchored and part.CanCollide == false then
        local lowerName = part.Name:lower()
        local ignoreNames = {"frozen", "soul", "meteor", "punch", "omni"}
        for _, name in ipairs(ignoreNames) do
            if string.find(lowerName, name) then
                return false
            end
        end
        return true
    end
    return false
end

local function CleanGame()
    if not canClean then return end
    canClean = false
    local count = 0
    
    -- Clean direct children in workspace
    for _, obj in ipairs(workspace:GetChildren()) do
        if IsDebris(obj) then
            obj:Destroy()
            count = count + 1
        end
    end
    
    -- Clean debris in container objects
    for _, container in ipairs(workspace:GetChildren()) do
        if container:IsA("Folder") or container:IsA("Model") then
            for _, obj in ipairs(container:GetChildren()) do
                if IsDebris(obj) then
                    obj:Destroy()
                    count = count + 1
                end
            end
        end
    end
    
    -- Clean "Thrown" folder specifically
    local thrownFolder = workspace:FindFirstChild("Thrown")
    if thrownFolder then
        for _, obj in ipairs(thrownFolder:GetChildren()) do
            obj:Destroy()
            count = count + 1
        end
    end
    
    canClean = true
    if count > 0 then
        Print("Removidos " .. count .. " itens de lag")
    end
end

-- Freecam system
local freecamEnabled = false
local originalCameraSubject = nil
local keysDown = {}

local function ToggleFreecam()
    freecamEnabled = not freecamEnabled
    if freecamEnabled then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            originalCameraSubject = Camera.CameraSubject
            Camera.CameraSubject = nil
        end
        Print("Freecam ativado")
    else
        Camera.CameraSubject = originalCameraSubject
        Print("Freecam desativado")
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    keysDown[input.KeyCode] = true
    local allKeysPressed = true
    for _, keyCode in ipairs(Settings.FreecamKey) do
        if not keysDown[keyCode] then
            allKeysPressed = false
            break
        end
    end
    if allKeysPressed then
        ToggleFreecam()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    keysDown[input.KeyCode] = nil
end)

-- Process character functions
local function Process()
    if not LocalPlayer.Character then return end
    local char = LocalPlayer.Character
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    
    hrp.ChildAdded:Connect(function(child)
        local Dodge = false
        if child.Name == "dodgevelocity" then
            task.spawn(function()
                Dodge = true
                local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                local magicHealthGui = playerGui and playerGui:FindFirstChild("ScreenGui")
                local health = magicHealthGui and magicHealthGui:FindFirstChild("MagicHealth")
                local glow = health and health:FindFirstChild("Health") and health.Health:FindFirstChild("Glow")
                if not glow then return end
                for i = 2, 0, -1 do
                    if not Dodge then break end
                    glow.ImageColor3 = Color3.fromRGB(255,255,255)
                    task.wait(1)
                    glow.ImageColor3 = Color3.fromRGB(0,0,0)
                end
                Dodge = false
            end)
        elseif child.Name == "moveme" or (child.Name == "Sound" and Dodge) then
            task.spawn(function()
                Dodge = false
                local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                local magicHealthGui = playerGui and playerGui:FindFirstChild("ScreenGui")
                local health = magicHealthGui and magicHealthGui:FindFirstChild("MagicHealth")
                local textLabel = health and health:FindFirstChild("TextLabel")
                if not textLabel then return end
                for i = 4, 0, -1 do
                    textLabel.TextColor3 = Color3.fromRGB(255,50,50)
                    task.wait(1)
                    textLabel.TextColor3 = Color3.fromRGB(255,255,255)
                end
            end)
        end
    end)
end

-- Initialization and loops
if not getgenv().executed then
    -- Hook for reset (using metamethods)
    local oldNameCall
    oldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if self.Name == "Communicate" and method == "FireServer" and args[1] and args[1]["Goal"] == "Reset" then
            task.spawn(function()
                respawn(LocalPlayer)
            end)
        end
        return oldNameCall(self, ...)
    end)
    
    local oldNewIndex
    oldNewIndex = hookmetamethod(game, "__newindex", function(self, k, v)
        if k == "Parent" and (v == workspace:FindFirstChild("Thrown") or self:IsA("ParticleEmitter")) then
            self:Destroy()
            return nil
        end
        return oldNewIndex(self, k, v)
    end)
    
    if workspace:FindFirstChild("Thrown") then
        workspace.Thrown.ChildAdded:Connect(function(instance)
            task.wait()
            instance:Destroy()
        end)
    end
    
    if LocalPlayer.Character then
        Process()
    end
    LocalPlayer.CharacterAdded:Connect(Process)
    
    RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        -- Manage limbs
        if char:FindFirstChild("Left Arm") and char:FindFirstChild("Right Arm") then
            if not Settings.Limb.Arms then
                local leftArm = char:FindFirstChild("Left Arm")
                local rightArm = char:FindFirstChild("Right Arm")
                if leftArm then leftArm:Destroy() end
                if rightArm then rightArm:Destroy() end
            end
            if not Settings.Limb.Legs then
                local leftLeg = char:FindFirstChild("Left Leg")
                local rightLeg = char:FindFirstChild("Right Leg")
                if leftLeg then leftLeg:Destroy() end
                if rightLeg then rightLeg:Destroy() end
            end
        end
        
        -- Freecam movement
        if freecamEnabled then
            local moveSpeed = 1
            local cf = Camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                Camera.CFrame = cf + cf.LookVector * moveSpeed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                Camera.CFrame = cf - cf.LookVector * moveSpeed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                Camera.CFrame = cf - cf.RightVector * moveSpeed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                Camera.CFrame = cf + cf.RightVector * moveSpeed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                Camera.CFrame = cf + cf.UpVector * moveSpeed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                Camera.CFrame = cf - cf.UpVector * moveSpeed
            end
        end
    end)
    
    -- Periodically clean debris
    task.spawn(function()
        while task.wait(Settings.AntiLag.ScanInterval) do
            CleanGame()
        end
    end)
    
    CreateNotification()
    Print("Sistema Anti-Lag XPurple inicializado!")
end

getgenv().executed = true
