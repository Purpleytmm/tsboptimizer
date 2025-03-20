--=# Configurações Globais #=--
getgenv().Settings = {
    Limb = { Arms = true, Legs = true },
    AntiLag = { PartsPerTick = 38, ScanInterval = 2 },
    FreecamKey = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}
}

--=# Variáveis Essenciais #=--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local debris = {}
local canClean = true

--=# Funções Auxiliares #=--
local function Print(...)
    print("[XPurpleYT]:", ...)
end

--=# Funções de Respawn do Script Original #=--
local function respawn(plr)
    local char = plr.Character
    if char:FindFirstChildOfClass("Humanoid") then char:FindFirstChildOfClass("Humanoid"):ChangeState(15) end
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

--=# Notificação #=--
local function CreateNotification()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XPurpleNotification"
    
    -- Tentar usar CoreGui, mas cair para PlayerGui se não for possível
    local parent = (pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui")) 
                   or LocalPlayer:FindFirstChildOfClass("PlayerGui") 
    screenGui.Parent = parent
    
    -- Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 250, 0, 70)
    mainFrame.Position = UDim2.new(1, 300, 0.8, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Arredondar cantos
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = mainFrame
    
    -- Título
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
    
    -- Texto
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
    
    -- Animação de entrada
    mainFrame:TweenPosition(
        UDim2.new(1, -260, 0.8, 0),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.5
    )
    
    -- Remover após 5 segundos
    task.delay(5, function()
        mainFrame:TweenPosition(
            UDim2.new(1, 300, 0.8, 0),
            Enum.EasingDirection.In,
            Enum.EasingStyle.Quad,
            0.5,
            false,
            function()
                screenGui:Destroy()
            end
        )
    end)
end

--=# Sistema de Limpeza Aprimorado #=--
local function IsDebris(part)
    -- Verifica se é um objeto que deve ser limpo
    if not part or not part:IsA("BasePart") then return false end
    
    -- Ignorar partes de personagens
    local character = part:FindFirstAncestorOfClass("Model")
    if character and character:FindFirstChildOfClass("Humanoid") then
        return false
    end
    
    -- Principais características de detritos
    if not part.Anchored and part.CanCollide == false then
        -- Verifica nomes a ignorar
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
    
    -- Limpar objetos diretos no workspace
    local count = 0
    for _, obj in pairs(workspace:GetChildren()) do
        if IsDebris(obj) then
            obj:Destroy()
            count = count + 1
        end
    end
    
    -- Limpar detritos em pastas principais (mais profundas)
    for _, container in pairs(workspace:GetChildren()) do
        if container:IsA("Folder") or container:IsA("Model") then
            for _, obj in pairs(container:GetChildren()) do
                if IsDebris(obj) then
                    obj:Destroy()
                    count = count + 1
                end
            end
        end
    end
    
    -- Limpar pasta "Thrown" especificamente
    if workspace:FindFirstChild("Thrown") then
        for _, obj in pairs(workspace.Thrown:GetChildren()) do
            obj:Destroy()
            count = count + 1
        end
    end
    
    canClean = true
    if count > 0 then
        Print("Removidos " .. count .. " itens de lag")
    end
end

--=# Sistema Freecam #=--
local freecamEnabled = false
local originalCameraSubject = nil
local keysDown = {}

local function ToggleFreecam()
    freecamEnabled = not freecamEnabled
    
    if freecamEnabled then
        -- Ativar freecam
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            originalCameraSubject = Camera.CameraSubject
            Camera.CameraSubject = nil
        end
        Print("Freecam ativado")
    else
        -- Desativar freecam
        Camera.CameraSubject = originalCameraSubject
        Print("Freecam desativado")
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Rastrear teclas pressionadas
    keysDown[input.KeyCode] = true
    
    -- Verificar combinação de teclas para freecam
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

--=# Funções de Processamento do Personagem #=--
local function Process()
    LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    LocalPlayer.Character.HumanoidRootPart.ChildAdded:Connect(function(child)
        local Dodge = false
        if (child.Name == "dodgevelocity") then
            task.spawn(function()
                Dodge = true
                local Glow = LocalPlayer.PlayerGui.ScreenGui.MagicHealth.Health.Glow
                for i = 1.975, 0, -1 do
                    if Dodge == false then break end
                    Glow.ImageColor3 = Color3.fromRGB(255,255,255)
                    task.wait(1)
                    Glow.ImageColor3 = Color3.fromRGB(0,0,0)
                end
                Dodge = false
            end)
        elseif (child.Name == "moveme" or child.Name == "Sound" and Dodge) then
            task.spawn(function()
                Dodge = false
                local Text = LocalPlayer.PlayerGui.ScreenGui.MagicHealth.TextLabel
                for i = 3.975, 0, -1 do
                    Text.TextColor3 = Color3.fromRGB(255,50,50)
                    task.wait(1)
                    Text.TextColor3 = Color3.fromRGB(255,255,255)
                end
            end)
        end
    end)
end

--=# Inicialização e Loops #=--
if not getgenv().executed then
    -- Hook para reset
    local nameCallHook
    nameCallHook = hookmetamethod(game, "__namecall", function(self, ...)
        local method, args = getnamecallmethod(), {...}
        if self.Name == "Communicate" and method == "FireServer" and args[1]["Goal"] == "Reset" then
            task.spawn(function()
                respawn(LocalPlayer)
            end)
        end
        return nameCallHook(self, ...)
    end)

    -- Hook para anti-thrown e anti-particle
    local newIndexHook
    newIndexHook = hookmetamethod(game, "__newindex", function(self, k, v)
        local char = self:FindFirstAncestorWhichIsA("Model")
        local player = Players:GetPlayerFromCharacter(char)
        if k == "Parent" and (v == workspace.Thrown or self:IsA("ParticleEmitter")) then
            self:Destroy()
            return nil
        end
        return newIndexHook(self, k, v)
    end)

    -- Monitorar Thrown
    if workspace:FindFirstChild("Thrown") then
        workspace.Thrown.ChildAdded:Connect(function(instance)
            task.wait()
            instance:Destroy()
        end)
    end

    -- Inicializar processo para personagem atual
    if LocalPlayer.Character then
        Process()
    end
    
    -- Conectar para personagens futuros
    LocalPlayer.CharacterAdded:Connect(Process)

    -- Loop principal para limbs
    RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        -- Gerenciamento de membros
        if char:FindFirstChild("Left Arm") and char:FindFirstChild("Right Arm") then
            if not Settings.Limb.Arms then
                char:FindFirstChild("Left Arm"):Destroy()
                char:FindFirstChild("Right Arm"):Destroy()
            end
            if not Settings.Limb.Legs then
                char:FindFirstChild("Left Leg"):Destroy()
                char:FindFirstChild("Right Leg"):Destroy()
            end
        end
        
        -- Freecam
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
    
    -- Loop de limpeza direta (sem fila)
    task.spawn(function()
        while task.wait(Settings.AntiLag.ScanInterval) do
            CleanGame()
        end
    end)
    
    CreateNotification()
    Print("Sistema Anti-Lag XPurple inicializado!")
end

getgenv().executed = true
