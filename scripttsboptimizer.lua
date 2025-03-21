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

-- Sistema de fila para debris
local debrisQueue = {}

-- Helper function with direct console output
local function Print(...)
    local message = "[XPurpleYT]: "
    for i, v in ipairs({...}) do
        message = message .. tostring(v) .. " "
    end
    warn(message) -- Using warn to make it more visible in console
end

-- Notification Function
local function CreateNotification()
    Print("Creating notification...")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XPurpleNotification"
    
    -- Force creation in PlayerGui if CoreGui fails
    local success = pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
    end)
    
    if not success then
        screenGui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end
    
    -- Main notification frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 250, 0, 70)
    mainFrame.Position = UDim2.new(1, 300, 0.8, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Corner rounding
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = mainFrame
    
    -- Title
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
    
    -- Text
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
    
    -- Animation to slide in from right
    mainFrame:TweenPosition(
        UDim2.new(1, -260, 0.8, 0),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.5,
        true
    )
    
    -- Remove after delay
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
    
    Print("Notification created")
end

-- Expanded protection check function
local function IsProtected(obj)
    -- Protected object names (expanded list)
    local protectedNames = {
        "frozen", "soul", "frozensoul", "meteor", 
        "omnidirectionalpunchcutscene", "omnidirectionalpunch", "omnidirectionalpunchfolder",
        "final stand", "finalstand", "boundless", "rage", "boundlessrage",
        "emote", "animate", "animation", "run", "sprint", "cutscene", "special", "attack"
    }
    
    local name = obj.Name:lower()
    for _, protectedName in ipairs(protectedNames) do
        if string.find(name, protectedName) then
            return true
        end
    end
    
    -- Check parent too (helps with nested cutscene objects)
    if obj.Parent and typeof(obj.Parent) == "Instance" then
        name = obj.Parent.Name:lower()
        for _, protectedName in ipairs(protectedNames) do
            if string.find(name, protectedName) then
                return true
            end
        end
    end
    
    return false
end

-- Melhor verificação se um objeto é realmente um debris
local function IsDebris(part)
    -- Verifica se é uma BasePart
    if not part:IsA("BasePart") then
        return false
    end
    
    -- Verificar se é parte de um personagem
    local isCharacterPart = false
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and part:IsDescendantOf(player.Character) then
            isCharacterPart = true
            break
        end
    end
    if isCharacterPart then
        return false
    end
    
    -- Não remover partes protegidas
    if IsProtected(part) then
        return false
    end
    
    -- IMPORTANTE: Não remover partes ancoradas ou com colisão
    if part.Anchored or part.CanCollide then
        return false
    end
    
    -- Checar se tem attachments ou outros elementos importantes
    if part:FindFirstChildOfClass("Attachment") or 
       part:FindFirstChildOfClass("BillboardGui") then
        return false
    end
    
    -- Verifica se está flutuando
    local rayOrigin = part.Position
    local rayDirection = Vector3.new(0, -10, 0) -- Verificar apenas 10 studs abaixo
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {part}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    -- Se não atingir nada, está provavelmente flutuando
    return result == nil
end

-- Sistema de scan para encontrar debris
local function ScanForDebris()
    -- Limpar a fila de objetos que não existem mais
    for i = #debrisQueue, 1, -1 do
        if not debrisQueue[i] or not debrisQueue[i].Parent then
            table.remove(debrisQueue, i)
        end
    end
    
    -- Scan workspace direto
    for _, obj in pairs(workspace:GetChildren()) do
        if IsDebris(obj) and not table.find(debrisQueue, obj) then
            table.insert(debrisQueue, obj)
        end
    end
    
    -- Scan pastas comuns de debris
    local commonFolders = {"Thrown", "Debris", "Effects", "FX"}
    for _, folderName in ipairs(commonFolders) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, obj in pairs(folder:GetChildren()) do
                if IsDebris(obj) and not table.find(debrisQueue, obj) then
                    table.insert(debrisQueue, obj)
                end
            end
        end
    end
    
    Print("Fila de debris: " .. #debrisQueue .. " itens")
end

-- Improved debris cleaning system with queue
local function CleanGame()
    if not canClean then return end
    canClean = false
    
    -- Primeiro, escanear por novos debris
    ScanForDebris()
    
    -- Agora processar a fila, apenas removendo o número permitido por tick
    local count = 0
    local maxPartsPerTick = Settings.AntiLag.PartsPerTick
    
    while count < maxPartsPerTick and #debrisQueue > 0 do
        local part = table.remove(debrisQueue, 1)
        
        if part and part.Parent then
            pcall(function() 
                part:Destroy() 
                count = count + 1
            end)
        end
    end
    
    canClean = true
    if count > 0 then
        Print("Removidos " .. count .. " itens de lag (Fila: " .. #debrisQueue .. ")")
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
        if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Running and
           humanoid:GetState() ~= Enum.HumanoidStateType.Climbing and
           humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
            
            -- Check if we can modify limbs
            local animator = humanoid:FindFirstChildOfClass("Animator")
            local isPlaying = false
            
            if animator then
                for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                    if track.IsPlaying then
                        isPlaying = true
                        break
                    end
                end
            end
            
            -- Only modify limbs if no animations are playing
            if not isPlaying then
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
        -- Wait for character to be fully loaded
        local humanoid = char:WaitForChild("Humanoid", 10)
        if humanoid then
            -- Make sure animation scripts are not interfered with
            local animate = char:WaitForChild("Animate", 10)
            if animate then
                -- Wait for all animation scripts to load
                wait(1)
                
                -- Fix run animations if needed
                local runScript = animate:FindFirstChild("run")
                if runScript then
                    runScript.Disabled = false
                end
                
                -- Fix emote animations if needed
                local emoteScript = char:FindFirstChild("EmoteScript") or animate:FindFirstChild("emote")
                if emoteScript then
                    emoteScript.Disabled = false
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
    
    -- Monitor Thrown folder if it exists
    if workspace:FindFirstChild("Thrown") then
        workspace.Thrown.ChildAdded:Connect(function(instance)
            task.wait(0.1) -- Pequeno delay para verificar se é parte de uma cutscene
            
            -- Adicionar à fila se não for protegido
            if not IsProtected(instance) and IsDebris(instance) then
                table.insert(debrisQueue, instance)
            end
        end)
    end
    
    -- Create notification after everything is set up
    CreateNotification()
    Print("Sistema Anti-Lag XPurple inicializado!")
end

getgenv().executed = true
