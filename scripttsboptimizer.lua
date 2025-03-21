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

-- FUNÇÃO SUPER SIMPLES: Verificar se objeto é debris
local function IsDebris(obj)
    -- Não é uma BasePart? Ignorar
    if not obj:IsA("BasePart") then return false end
    
    -- É parte de personagem? Ignorar
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and obj:IsDescendantOf(player.Character) then
            return false
        end
    end
    
    -- É um modelo com Humanoid? Ignorar
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then
        return false
    end
    
    -- Tem nome protegido? Ignorar
    local protectedNames = {"frozen", "soul", "meteor", "omni"}
    local lowerName = obj.Name:lower()
    for _, name in ipairs(protectedNames) do
        if string.find(lowerName, name) then
            return false
        end
    end
    
    -- Se NÃO é ancorado E NÃO tem colisão, é um debris
    if not obj.Anchored and not obj.CanCollide then
        return true
    end
    
    return false
end

-- Scan do jogo para encontrar debris
local function ScanForDebris()
    -- Limpar objetos não existentes da fila
    for i = #debrisQueue, 1, -1 do
        if not debrisQueue[i] or not debrisQueue[i].Parent then
            table.remove(debrisQueue, i)
        end
    end
    
    -- Procurar por novos debris no workspace
    for _, obj in pairs(workspace:GetChildren()) do
        if IsDebris(obj) and not table.find(debrisQueue, obj) then
            table.insert(debrisQueue, obj)
        end
    end
    
    -- Procurar na pasta Thrown
    if workspace:FindFirstChild("Thrown") then
        for _, obj in pairs(workspace.Thrown:GetChildren()) do
            if not table.find(debrisQueue, obj) then
                table.insert(debrisQueue, obj)
            end
        end
    end
    
    -- Procurar por objetos específicos (partes de efeitos)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
            local name = obj.Name:lower()
            if string.find(name, "effect") or string.find(name, "particle") or 
               string.find(name, "debris") or string.find(name, "fx") then
                if not table.find(debrisQueue, obj) then
                    table.insert(debrisQueue, obj)
                end
            end
        end
    end
end

-- Função de limpeza que processa a fila
local function CleanDebris()
    -- Primeiro atualizar a fila
    ScanForDebris()
    
    -- Agora processá-la, removendo exatamente o número configurado
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
    
    -- Iniciar o loop de limpeza
    task.spawn(function()
        -- Primeira limpeza após 3 segundos
        wait(3)
        
        while true do
            CleanDebris()
            wait(Settings.AntiLag.ScanInterval)
        end
    end)
    
    -- Monitor para pasta Thrown
    if workspace:FindFirstChild("Thrown") then
        workspace.Thrown.ChildAdded:Connect(function(instance)
            wait(0.1)
            if instance and instance.Parent then
                if not table.find(debrisQueue, instance) then
                    table.insert(debrisQueue, instance)
                end
            end
        end)
    end
    
    -- Criar notificação
    CreateNotification()
    Print("Sistema Anti-Lag XPurple inicializado!")
end

getgenv().executed = true
