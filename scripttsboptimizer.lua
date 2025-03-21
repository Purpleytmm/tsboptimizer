-- Global Settings
getgenv().Settings = {
    Limb = { Arms = true, Legs = true },
    AntiLag = { PartsPerTick = 40, ScanInterval = 2 },
    FreecamKey = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}
}

-- Essential variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local canClean = true

-- Fila para debris a serem removidos
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
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and obj:IsDescendantOf(player.Character) then
            return true
        end
    end
    return false
end

-- Verificar se o objeto está na lista de proteção
local function IsProtected(obj)
    local protectedNames = {"frozen", "soul", "meteor", "omni", "boundless", "rage"}
    local lowerName = obj.Name:lower()
    
    for _, name in ipairs(protectedNames) do
        if string.find(lowerName, name) then
            return true
        end
    end
    
    return false
end

-- Verificar se um objeto é um debris flutuante
local function IsAirDebris(obj)
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
    
    -- Verificar se está flutuando (não no chão)
    local rayOrigin = obj.Position
    local rayDirection = Vector3.new(0, -3, 0) -- 3 studs abaixo
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {obj}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    return result == nil -- Se não atingir nada, está flutuando
end

-- Atualizar a fila de debris
local function UpdateDebrisQueue()
    -- Limpar entradas inválidas
    for i = #debrisQueue, 1, -1 do
        if not debrisQueue[i] or not debrisQueue[i].Parent then
            table.remove(debrisQueue, i)
        end
    end
    
    -- Buscar no workspace
    for _, obj in pairs(workspace:GetChildren()) do
        if IsAirDebris(obj) and not table.find(debrisQueue, obj) then
            table.insert(debrisQueue, obj)
        end
    end
    
    -- Procurar na pasta Thrown
    if workspace:FindFirstChild("Thrown") then
        for _, obj in pairs(workspace.Thrown:GetChildren()) do
            if IsAirDebris(obj) and not table.find(debrisQueue, obj) then
                table.insert(debrisQueue, obj)
            end
        end
    end
end

-- Função de limpeza que processa a fila
local function CleanDebris()
    if not canClean then return end
    canClean = false
    
    -- Primeiro atualizar a fila
    UpdateDebrisQueue()
    
    -- Remover exatamente o número configurado
    local count = 0
    local maxToRemove = Settings.AntiLag.PartsPerTick
    
    for i = 1, math.min(#debrisQueue, maxToRemove) do
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
        Print("Removidos " .. count .. " debris (Fila: " .. #debrisQueue .. " restantes)")
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

-- Inicialização
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
    
    -- Iniciar o loop de limpeza
    task.spawn(function()
        while wait(Settings.AntiLag.ScanInterval) do
            CleanDebris()
        end
    end)
    
    -- Criar notificação
    CreateNotification()
    Print("Sistema Anti-Lag XPurple inicializado!")
end

getgenv().executed = true
