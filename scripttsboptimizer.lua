--=# Configurações Globais #=--
getgenv().Settings = {
    Limb = { Arms = true, Legs = true },
    AntiLag = { PartsPerTick = 38, ScanInterval = 2, MaxQueueSize = 5000 },
    FreecamKey = { Enum.KeyCode.LeftShift, Enum.KeyCode.P }
}
local Settings = getgenv().Settings  -- Alias local para facilitar o acesso

--=# Variáveis Essenciais #=--
local queue, pointer = {}, 1
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--=# Notificação XPurpleYTmmX #=--
local function ShowNotification()
    -- Proteção contra erros
    local success, errorMsg = pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "XPurpleNotif"
        
        -- Verificar se CoreGui está disponível
        local parent = game:GetService("CoreGui")
        if not pcall(function() local _ = parent.Parent end) then
            parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        end
        gui.Parent = parent
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 250, 0, 60)
        frame.Position = UDim2.new(1, 300, 1, -70)
        frame.BackgroundColor3 = Color3.new(0.08, 0.08, 0.08)
        frame.BorderSizePixel = 0
        frame.Parent = gui
        
        -- Texto da notificação
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -10, 0, 25)
        title.Position = UDim2.new(0, 5, 0, 5)
        title.BackgroundTransparency = 1
        title.TextColor3 = Color3.new(1, 0.4, 1) -- Cor roxa
        title.TextSize = 16
        title.Font = Enum.Font.GothamBold
        title.Text = "XPurple Anti-Lag"
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = frame
        
        local message = Instance.new("TextLabel")
        message.Size = UDim2.new(1, -10, 0, 20)
        message.Position = UDim2.new(0, 5, 0, 30)
        message.BackgroundTransparency = 1
        message.TextColor3 = Color3.new(1, 1, 1)
        message.TextSize = 14
        message.Font = Enum.Font.Gotham
        message.Text = "Iniciado com sucesso!"
        message.TextXAlignment = Enum.TextXAlignment.Left
        message.Parent = frame

        frame:TweenPosition(UDim2.new(1, -260, 1, -70), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5)
        task.delay(5, function()
            frame:TweenPosition(UDim2.new(1, 300, 1, -70), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5, true, function()
                gui:Destroy()
            end)
        end)
    end)
    
    if not success then
        warn("Erro ao mostrar notificação: " .. tostring(errorMsg))
    end
end

--=# Hook Anti-Throw Atualizado #=--
local originalNewIndex
originalNewIndex = hookmetamethod(game, "__newindex", function(self, k, v)
    if not self or typeof(self) ~= "Instance" then
        return originalNewIndex(self, k, v)
    end
    
    if k == "Parent" and (v == workspace.Thrown or (typeof(self) == "Instance" and self:IsA("ParticleEmitter"))) then
        pcall(function() self:Destroy() end)
        return nil
    end
    return originalNewIndex(self, k, v)
end)

--=# Proteção Total de Efeitos (Otimizada) #=--
local function isProtected(obj)
    if not obj or not obj:IsA("Instance") then
        return true -- Se não for um objeto válido, considere protegido para evitar erros
    end

    -- Tenta obter atributo com proteção contra erros
    local hasAttribute = pcall(function() return obj:GetAttribute("XPurple_Protected") end)
    if hasAttribute and obj:GetAttribute("XPurple_Protected") then 
        return true 
    end

    -- Verifica se pertence a um personagem
    local success, isCharacterPart = pcall(function()
        local model = obj:FindFirstAncestorOfClass("Model")
        return model and model:FindFirstChildWhichIsA("Humanoid") ~= nil
    end)
    
    if success and isCharacterPart then
        pcall(function() obj:SetAttribute("XPurple_Protected", true) end)
        return true
    end

    -- Nomes protegidos
    local protectedNames = {
        ["frozen"] = true,
        ["soul"] = true,
        ["frozensoul"] = true,
        ["meteor"] = true
    }
    
    -- Verificar nome com proteção contra erros
    local objName = ""
    pcall(function() objName = obj.Name:lower() end)
    
    return protectedNames[objName] 
        or (objName ~= "" and (string.match(objName, "punch") or string.match(objName, "omni")))
end

--=# Sistema de Limpeza Turbo #=--
local function ChunkedClean()
    local descendants = {}
    
    -- Obter descendentes com proteção contra erros
    pcall(function() descendants = workspace:GetDescendants() end)
    
    for i = 1, #descendants, 15 do
        local obj = descendants[i]
        if obj and obj:IsA("BasePart") and not isProtected(obj) then
            if not obj.Anchored and not obj.CanCollide then
                -- Limitar tamanho da fila para evitar uso excessivo de memória
                if #queue < (Settings.AntiLag.MaxQueueSize or 5000) then
                    table.insert(queue, obj)
                end
            end
        end
        if i % 50 == 0 then 
            task.wait() 
        end
    end
end

--=# Sistema de Membros Atualizado #=--
local function UpdateLimbs(character)
    if not character then return end
    
    for _, side in ipairs({"Left", "Right"}) do
        local arm = character:FindFirstChild(side.."Arm") or character:FindFirstChild(side.." Arm")
        if arm and not Settings.Limb.Arms then 
            pcall(function() arm:Destroy() end)
        end

        local leg = character:FindFirstChild(side.."Leg") or character:FindFirstChild(side.." Leg")
        if leg and not Settings.Limb.Legs then 
            pcall(function() leg:Destroy() end)
        end
    end
end

--=# Implementação de Freecam #=--
local freecamEnabled = false
local function ToggleFreecam()
    freecamEnabled = not freecamEnabled
    if freecamEnabled then
        -- Implementação básica do freecam (pode ser expandida)
        local character = LocalPlayer.Character
        if character then
            character:MoveTo(Camera.CFrame.Position)
            Camera.CameraSubject = nil
        end
    else
        -- Restaurar câmera normal
        local character = LocalPlayer.Character
        if character and character:FindFirstChildWhichIsA("Humanoid") then
            Camera.CameraSubject = character:FindFirstChildWhichIsA("Humanoid")
        end
    end
end

--=# Detector de Input para Freecam #=--
local keyStates = {}
Input.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    keyStates[input.KeyCode] = true
    
    -- Verificar se todas as teclas de freecam estão pressionadas
    local allKeysPressed = true
    for _, key in ipairs(Settings.FreecamKey) do
        if not keyStates[key] then
            allKeysPressed = false
            break
        end
    end
    
    if allKeysPressed then
        ToggleFreecam()
    end
end)

Input.InputEnded:Connect(function(input)
    keyStates[input.KeyCode] = nil
end)

--=# Loop Principal Otimizado #=--
RunService.Heartbeat:Connect(function()
    -- Processar Anti-Lag
    local partsToProcess = math.min(Settings.AntiLag.PartsPerTick, #queue)
    for i = 1, partsToProcess do
        if queue[pointer] then
            pcall(function() queue[pointer]:Destroy() end)
            pointer = pointer + 1
        else
            table.clear(queue)
            pointer = 1
            break
        end
    end

    -- Atualizar Membros do personagem local
    if LocalPlayer and LocalPlayer.Character then 
        UpdateLimbs(LocalPlayer.Character) 
    end
    
    -- Atualizar Freecam
    if freecamEnabled and LocalPlayer and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            local moveDir = humanoid.MoveDirection
            local camCF = Camera.CFrame
            Camera.CFrame = camCF + (camCF.LookVector * moveDir.Z + camCF.RightVector * moveDir.X) * 0.5
        end
    end
end)

--=# Inicialização #=--
ShowNotification()
LocalPlayer.CharacterAdded:Connect(UpdateLimbs)

-- Verificações de segurança para workspace.Thrown
if workspace then
    local thrown = workspace:FindFirstChild("Thrown")
    if thrown then
        thrown.ChildAdded:Connect(function(obj)
            task.spawn(function() -- Usar task.spawn para evitar problemas de yield
                pcall(function() obj:Destroy() end)
            end)
        end)
    else
        -- Tentar criar o Thrown se não existir
        pcall(function()
            local newThrown = Instance.new("Folder")
            newThrown.Name = "Thrown"
            newThrown.Parent = workspace
            
            newThrown.ChildAdded:Connect(function(obj)
                task.spawn(function()
                    pcall(function() obj:Destroy() end)
                end)
            end)
        end)
    end
end

-- Loop de limpeza principal
task.spawn(function()
    while true do
        local success, errorMsg = pcall(function()
            task.wait(Settings.AntiLag.ScanInterval)
            ChunkedClean()
            collectgarbage("step", 200) -- Otimização de memória
        end)
        
        if not success then
            warn("Erro no loop de limpeza: " .. tostring(errorMsg))
            task.wait(1) -- Pausa mais longa em caso de erro
        end
    end
end)

print("XPurple Anti-Lag iniciado com sucesso!")
