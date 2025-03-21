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

-- Sistema de fila para remoção gradual
local debrisQueue = {}

-- Debug function
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

-- Verificar se objeto é parte de um personagem
local function IsCharacterPart(obj)
    -- Verificar se o objeto está em um personagem de jogador
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and obj:IsDescendantOf(player.Character) then
            return true
        end
    end
    
    -- Verificar se o objeto está em um modelo com Humanoid
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then
        return true
    end
    
    return false
end

-- Lista de proteção expandida
local protectedNames = {
    "frozen", "soul", "meteor", "omni", "boundless", "rage", "final", "stand"
}

-- Tempo especial para debris do Omni (30 segundos)
local omniDebrisTime = 20

-- Função para verificar se um objeto está protegido pelo nome
local function IsProtected(obj)
    local lowerName = obj.Name:lower()
    for _, name in ipairs(protectedNames) do
        if string.find(lowerName, name) then
            return true
        end
    end
    
    -- Verificar parent também
    if obj.Parent then
        local parentName = obj.Parent.Name:lower()
        for _, name in ipairs(protectedNames) do
            if string.find(parentName, name) then
                return true
            end
        end
    end
    
    return false
end

-- Verifica se um objeto é um debris que deve ser removido
local function IsDebris(obj)
    -- Só consideramos partes
    if not obj:IsA("BasePart") then 
        return false 
    end
    
    -- Não remover partes ancoradas ou com hitbox
    if obj.Anchored or obj.CanCollide then
        return false
    end
    
    -- Não remover partes de personagens
    if IsCharacterPart(obj) then
        return false
    end
    
    -- Não remover objetos protegidos
    if IsProtected(obj) then
        return false
    end
    
    return true
end

-- Função para escanear e atualizar a fila de debris
local function UpdateDebrisQueue()
    -- Remover objetos inválidos da fila
    for i = #debrisQueue, 1, -1 do
        if not debrisQueue[i] or not debrisQueue[i].Parent then
            table.remove(debrisQueue, i)
        end
    end
    
    -- Adicionar novos debris à fila
    for _, obj in pairs(workspace:GetChildren()) do
        if IsDebris(obj) and not table.find(debrisQueue, obj) then
            table.insert(debrisQueue, obj)
        end
    end
    
    -- Checar pasta Thrown
    if workspace:FindFirstChild("Thrown") then
        for _, obj in pairs(workspace.Thrown:GetChildren()) do
            if not IsProtected(obj) and not table.find(debrisQueue, obj) then
                table.insert(debrisQueue, obj)
            end
        end
    end
    
    -- Verificar debris do Omni especificamente - remover após 30 segundos
    for _, obj in pairs(workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if (string.find(name, "omni") or string.find(name, "punch")) and 
           obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
            
            -- Marcar para remoção após o tempo
            if not obj:GetAttribute("OmniCleanTime") then
                obj:SetAttribute("OmniCleanTime", tick() + omniDebrisTime)
            elseif tick() > obj:GetAttribute("OmniCleanTime") then
                -- Tempo expirou, adicionar à fila se ainda não estiver lá
                if not table.find(debrisQueue, obj) then
                    table.insert(debrisQueue, obj)
                end
            end
        end
    end
end

-- Função de limpeza de debris da fila
local function ProcessDebrisQueue()
    if not canClean then return end
    canClean = false
    
    -- Primeiro atualizar a fila
    UpdateDebrisQueue()
    
    -- Processar a fila, removendo até X elementos por vez
    local count = 0
    local maxToRemove = Settings.AntiLag.PartsPerTick
    
    while count < maxToRemove and #debrisQueue > 0 do
        local debris = table.remove(debrisQueue, 1)
        
        if debris and debris.Parent then
            pcall(function()
                debris:Destroy()
                count = count + 1
            end)
        end
    end
    
    canClean = true
    if count > 0 then
        Print("Removidos " .. count .. " itens de lag (Fila: " .. #debrisQueue .. " restantes)")
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
    
    -- Limb management
    RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        -- Só gerencia os próprios membros baseado nas configurações do usuário
        if Settings.Limb.Arms == false then
            local leftArm = char:FindFirstChild("Left Arm")
            local rightArm = char:FindFirstChild("Right Arm")
            if leftArm then leftArm.Transparency = 1 end
            if rightArm then rightArm.Transparency = 1 end
        end
        
        if Settings.Limb.Legs == false then
            local leftLeg = char:FindFirstChild("Left Leg")
            local rightLeg = char:FindFirstChild("Right Leg")
            if leftLeg then leftLeg.Transparency = 1 end
            if rightLeg then rightLeg.Transparency = 1 end
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
    
    -- Start queue processing loop
    task.spawn(function()
        while wait(Settings.AntiLag.ScanInterval) do
            ProcessDebrisQueue()
        end
    end)
    
    -- Monitor Thrown folder para adicionar itens à fila
    if workspace:FindFirstChild("Thrown") then
        workspace.Thrown.ChildAdded:Connect(function(instance)
            task.wait(0.1)
            if instance and instance.Parent and not IsProtected(instance) then
                if not table.find(debrisQueue, instance) then
                    table.insert(debrisQueue, instance)
                end
            end
        end)
    end
    
    -- Monitoramento especial para debris do Omni Directional Punch
    workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if string.find(name, "omni") or string.find(name, "punch") then
                -- Se for debris do Omni, marca para remoção após 30 segundos
                if not obj.Anchored and not obj.CanCollide and not IsCharacterPart(obj) then
                    obj:SetAttribute("OmniCleanTime", tick() + omniDebrisTime)
                    -- Será verificado na próxima atualização da fila
                end
            end
        end
    end)
    
    -- Create notification after everything is set up
    CreateNotification()
    Print("Sistema Anti-Lag XPurple inicializado!")
end

getgenv().executed = true
