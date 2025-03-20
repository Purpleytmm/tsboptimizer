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

local function IsLagPart(part)
    -- Verifica se é um parte que deve ser limpa
    if not part:IsA("BasePart") then return false end
    
    -- Partes de personagens devem ser preservadas
    local character = part:FindFirstAncestorOfClass("Model")
    if character and character:FindFirstChildOfClass("Humanoid") then
        return false
    end
    
    -- Partes ancoradas ou com colisão geralmente são importantes
    if part.Anchored or part.CanCollide then 
        return false 
    end
    
    -- Nomes de partes que devemos preservar
    local namesToKeep = {"frozen", "soul", "frozensoul", "meteor", "punch", "omni"}
    local lowerName = part.Name:lower()
    for _, name in ipairs(namesToKeep) do
        if string.find(lowerName, name) then
            return false
        end
    end
    
    return true
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

--=# Sistema de Limpeza #=--
local function CleanGame()
    if not canClean then return end
    canClean = false
    
    -- Limite a coleta para evitar lag
    local maxItems = 1000
    local count = 0
    
    -- Limpar workspace
    for _, obj in pairs(workspace:GetDescendants()) do
        if IsLagPart(obj) and count < maxItems then
            table.insert(debris, obj)
            count = count + 1
        end
        
        -- Algumas vezes cede o processamento para evitar travamentos
        if count % 100 == 0 then
            task.wait()
        end
    end
    
    -- Limpar pasta "Thrown" especificamente
    if workspace:FindFirstChild("Thrown") then
        for _, obj in pairs(workspace.Thrown:GetChildren()) do
            table.insert(debris, obj)
        end
    end
    
    canClean = true
    Print("Escaneou " .. count .. " itens para limpeza")
end

--=# Processamento de Debris #=--
local function ProcessDebris()
    local processCount = 0
    local maxPerFrame = Settings.AntiLag.PartsPerTick
    
    for i = #debris, 1, -1 do
        if processCount >= maxPerFrame then break end
        
        local obj = debris[i]
        if obj and obj:IsDescendantOf(game) then
            obj:Destroy()
        end
        
        table.remove(debris, i)
        processCount = processCount + 1
    end
    
    if processCount > 0 then
        Print("Removidos " .. processCount .. " detritos")
    end
end

--=# Sistema de Membros #=--
local function UpdateLimbs(character)
    if not character then return end
    
    for _, side in pairs({"Right", "Left"}) do
        -- Braços
        local arm = character:FindFirstChild(side.."Arm") or character:FindFirstChild(side.." Arm")
        if arm and not Settings.Limb.Arms then
            arm:Destroy()
            Print("Removido: " .. arm.Name)
        end
        
        -- Pernas
        local leg = character:FindFirstChild(side.."Leg") or character:FindFirstChild(side.." Leg")
        if leg and not Settings.Limb.Legs then
            leg:Destroy()
            Print("Removido: " .. leg.Name)
        end
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

--=# Anti-Particle System #=--
local function CreateAntiParticleSystem()
    -- Hook para impedir a criação de partículas
    local oldNewindex = nil
    oldNewindex = hookmetamethod(game, "__newindex", function(self, index, value)
        -- Anti-throw (detritos)
        if index == "Parent" and self and typeof(self) == "Instance" then
            if workspace:FindFirstChild("Thrown") and value == workspace.Thrown then
                self:Destroy()
                Print("Bloqueado item sendo jogado")
                return
            end
            
            -- Anti-particle
            if self:IsA("ParticleEmitter") or self:IsA("Trail") or self:IsA("Beam") or self:IsA("Smoke") then
                self:Destroy()
                Print("Bloqueado efeito de partícula")
                return
            end
        end
        
        return oldNewindex(self, index, value)
    end)
    
    -- Hook para neutralizar emissores existentes
    for _, particle in pairs(workspace:GetDescendants()) do
        if particle:IsA("ParticleEmitter") or particle:IsA("Trail") or particle:IsA("Beam") or particle:IsA("Smoke") then
            particle.Enabled = false
            particle:Destroy()
        end
    end
    
    Print("Sistema anti-partículas instalado")
end

--=# Monitoramento de Thrown #=--
local function WatchThrownFolder()
    -- Garantir que a pasta Thrown exista
    if not workspace:FindFirstChild("Thrown") then
        local thrownFolder = Instance.new("Folder")
        thrownFolder.Name = "Thrown"
        thrownFolder.Parent = workspace
        Print("Pasta Thrown criada")
    end
    
    -- Monitorar novos objetos na pasta Thrown
    workspace.Thrown.ChildAdded:Connect(function(child)
        child:Destroy()
        Print("Objeto em Thrown removido: " .. child.Name)
    end)
    
    -- Limpar objetos existentes na pasta Thrown
    for _, child in pairs(workspace.Thrown:GetChildren()) do
        child:Destroy()
    end
    
    Print("Monitoramento da pasta Thrown iniciado")
end

--=# Inicialização #=--
CreateNotification()
CreateAntiParticleSystem()
WatchThrownFolder()

-- Conectar ao personagem atual e futuros
if LocalPlayer.Character then
    UpdateLimbs(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1) -- Esperar um pouco para garantir que todos os membros estejam carregados
    UpdateLimbs(character)
end)

-- Loops principais de limpeza
RunService.Heartbeat:Connect(function()
    ProcessDebris() -- Processar a fila de detritos em cada frame
    
    -- Atualizar freecam se ativo
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

-- Loop de escaneamento
task.spawn(function()
    while true do
        CleanGame()
        task.wait(Settings.AntiLag.ScanInterval)
    end
end)

Print("Sistema Anti-Lag XPurple inicializado!")
