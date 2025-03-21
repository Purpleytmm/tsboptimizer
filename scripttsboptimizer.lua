-- Global Settings
getgenv().Settings = {
    Limb = { Arms = true, Legs = true },
    AntiLag = { PartsPerTick = 38, ScanInterval = 2 },
    FreecamKey = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}
}

-- Essential variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local canClean = true

-- Helper function
local function Print(...)
    local message = "[XPurpleYT]: "
    for i, v in ipairs({...}) do
        message = message .. tostring(v) .. " "
    end
    warn(message)
end

-- Notification Function
local function CreateNotification()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XPurpleNotification"
    
    local success = pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
    end)
    
    if not success then
        screenGui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end
    
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
        if mainFrame and mainFrame.Parent then
            mainFrame:TweenPosition(
                UDim2.new(1, 300, 0.8, 0),
                Enum.EasingDirection.In,
                Enum.EasingStyle.Quad,
                0.5,
                false,
                function()
                    if screenGui and screenGui.Parent then
                        screenGui:Destroy()
                    end
                end
            )
        end
    end)
end

-- Lista de proteção simples
local protectedNames = {
    "frozen", "soul", "meteor", "omni"
}

-- Função simplificada para limpar debris
local function CleanGame()
    if not canClean then return end
    canClean = false
    
    local debrisToClean = {}
    
    -- Buscar partes que são debris (sem hitbox, não ancoradas)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            -- Ignorar partes que são de personagens
            local isCharacterPart = false
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and obj:IsDescendantOf(player.Character) then
                    isCharacterPart = true
                    break
                end
            end
            
            -- Verificar se nome não está na lista de proteção
            local isProtected = false
            local lowerName = obj.Name:lower()
            for _, name in ipairs(protectedNames) do
                if string.find(lowerName, name) then
                    isProtected = true
                    break
                end
            end
            
            -- Se não for parte de personagem, não for protegida, não for ancorada e não tiver hitbox
            if not isCharacterPart and not isProtected and not obj.Anchored and not obj.CanCollide then
                table.insert(debrisToClean, obj)
            end
        end
    end
    
    -- Limitar a quantidade de partes removidas por tick
    local count = 0
    local maxToRemove = Settings.AntiLag.PartsPerTick
    
    for i = 1, math.min(#debrisToClean, maxToRemove) do
        if debrisToClean[i] and debrisToClean[i].Parent then
            debrisToClean[i]:Destroy()
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

-- Check if this is the first run
if not getgenv().executed then
    Print("Initializing XPurple Anti-Lag...")
    
    -- Key input handling
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        keysDown[input.KeyCode] = true
        
        -- Check for freecam key combination
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
    
    -- Limb management - MODIFIED: don't interfere with animations
    RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        -- Only modify limbs if the character isn't in an animation
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Running then
            -- Only modify limbs if no animations are playing
            if char:FindFirstChild("Left Arm") and char:FindFirstChild("Right Arm") then
                if not Settings.Limb.Arms then
                    pcall(function()
                        char:FindFirstChild("Left Arm"):Destroy()
                        char:FindFirstChild("Right Arm"):Destroy()
                    end)
                end
                
                if not Settings.Limb.Legs then
                    pcall(function()
                        char:FindFirstChild("Left Leg"):Destroy()
                        char:FindFirstChild("Right Leg"):Destroy()
                    end)
                end
            end
        end
        
        -- Freecam controls
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
    
    -- Fix running/emotes when character spawns
    LocalPlayer.CharacterAdded:Connect(function(char)
        local humanoid = char:WaitForChild("Humanoid", 10)
        if humanoid then
            local animate = char:WaitForChild("Animate", 10)
            if animate then
                wait(1)
                local runScript = animate:FindFirstChild("run")
                if runScript then
                    runScript.Disabled = false
                end
            end
        end
    end)
    
    -- Start cleanup loop
    task.spawn(function()
        while true do
            CleanGame()
            task.wait(Settings.AntiLag.ScanInterval)
        end
    end)
    
    -- Create notification after everything is set up
    CreateNotification()
    Print("Sistema Anti-Lag XPurple inicializado!")
end

getgenv().executed = true
