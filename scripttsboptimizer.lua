--=# Configurações do Usuário #=--
getgenv().Settings = {}
getgenv().Settings.Limb = {}
getgenv().Settings.Limb.Arms = true
getgenv().Settings.Limb.Legs = true

--=# Configurações do Lag Reducer #=--
local PARTS_PER_TICK = 80 -- Aumentado para processar mais partes por tick
local SCAN_INTERVAL = 0.5 -- Reduzido para verificar com mais frequência
local KEY_COMBO = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}

--=# Cache de Serviços #=--
local RunService = game:GetService("RunService")
local InputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local workspaceRef = workspace
local camera = workspace.CurrentCamera

--=# Registros e Tabelas de Referência #=--
local cutsceneRegistry = {}
local omniPunchFirstLineFlag = false
local bodyParts = {
    head = true, torso = true, humanoidrootpart = true,
    leftarm = true, rightarm = true, leftleg = true, rightleg = true
}
local allowedEmotes = {
    car = true, plane = true, scooter = true
}
local effectsToRemove = {
    afterimage = true, 
    flowingwater = true, 
    _trail = true,
    consecutive = true,
    machinegun = true,
    ["machine gun"] = true,
    barrage = true,
    explosion = true,
    wave = true
}

--=# Sistema de Limpeza #=--
local queue = {}
local pointer = 1
local processingActive = false

--=# Sistema de Respawn/Refresh #=--
if not getgenv().executed then
    local function respawn(plr)
        if not plr or not plr.Character then return end
        local char = plr.Character
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then 
            humanoid:ChangeState(15) 
        end
        char:ClearAllChildren()
        local newChar = Instance.new("Model")
        newChar.Parent = workspaceRef
        plr.Character = newChar
        task.wait()
        plr.Character = char
        newChar:Destroy()
    end

    local function refresh(plr)
        if not plr or not plr.Character then return end
        local Human = plr.Character:FindFirstChildOfClass("Humanoid", true)
        local pos = (Human and Human.RootPart) and Human.RootPart.CFrame or nil
        local camPos = workspaceRef.CurrentCamera.CFrame
        respawn(plr)
        task.spawn(function()
            task.wait(0.1)
            workspaceRef.CurrentCamera.CFrame = camPos
        end)
    end

    -- Hook para __namecall
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        if self.Name == "Communicate" and method == "FireServer" then
            if type(args[1]) == "table" and args[1].Goal == "Reset" then
                task.spawn(function()
                    respawn(LocalPlayer)
                end)
            end
        end
        return oldNamecall(self, ...)
    end)

    -- Hook para __newindex (destroi objetos arremessados e emissores de partículas)
    local oldNewIndex
    oldNewIndex = hookmetamethod(game, "__newindex", function(self, k, v)
        if k == "Parent" then
            -- Verifica se o objeto está sendo movido para workspace.Thrown ou é um emissor de partículas
            if v == workspaceRef.Thrown or (self:IsA("ParticleEmitter") and (
               self.Name:lower():find("consecutive") or 
               self.Name:lower():find("barrage") or 
               self.Name:lower():find("machine") or
               self.Name:lower():find("multi"))) then
                task.spawn(function()
                    self:Destroy()
                end)
                return nil
            end
        end
        return oldNewIndex(self, k, v)
    end)

    -- Destrói objetos que entram no workspace.Thrown
    if workspaceRef:FindFirstChild("Thrown") then
        workspaceRef.Thrown.ChildAdded:Connect(function(instance)
            task.defer(function() -- Usar defer para melhor desempenho
                if instance and instance.Parent then
                    instance:Destroy()
                end
            end)
        end)
    end

    local function Process()
        if not LocalPlayer.Character then return end
        local hrp = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
        hrp.ChildAdded:Connect(function(child)
            local Dodge = false
            if child.Name == "dodgevelocity" then
                task.spawn(function()
                    Dodge = true
                    local glow = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScreenGui"):WaitForChild("MagicHealth"):WaitForChild("Health"):WaitForChild("Glow")
                    for i = 1.975, 0, -1 do
                        if not Dodge then break end
                        glow.ImageColor3 = Color3.fromRGB(255, 255, 255)
                        task.wait(1)
                        glow.ImageColor3 = Color3.fromRGB(0, 0, 0)
                    end
                    Dodge = false
                end)
            elseif (child.Name == "moveme" or child.Name == "Sound") and Dodge then
                task.spawn(function()
                    Dodge = false
                    local textLabel = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScreenGui"):WaitForChild("MagicHealth"):WaitForChild("TextLabel")
                    for i = 3.975, 0, -1 do
                        textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                        task.wait(1)
                        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    end
                end)
            end
        end)
    end

    Process()
    LocalPlayer.CharacterAdded:Connect(Process)

    -- Remover membros conforme configurado
    RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        if char:FindFirstChild("Left Arm") and char:FindFirstChild("Right Arm") then
            if not getgenv().Settings.Limb.Arms then
                local leftArm = char:FindFirstChild("Left Arm")
                local rightArm = char:FindFirstChild("Right Arm")
                if leftArm then leftArm:Destroy() end
                if rightArm then rightArm:Destroy() end
            end
            if not getgenv().Settings.Limb.Legs then
                local leftLeg = char:FindFirstChild("Left Leg")
                local rightLeg = char:FindFirstChild("Right Leg")
                if leftLeg then leftLeg:Destroy() end
                if rightLeg then rightLeg:Destroy() end
            end
        end
    end)
end

--=# Funções do Lag Reducer #=--
local function registerCutscene(cutsceneModel)
    if cutsceneModel and not cutsceneRegistry[cutsceneModel] then
        cutsceneRegistry[cutsceneModel] = {
            firstLineProtected = false,
            connection = cutsceneModel.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    cutsceneRegistry[cutsceneModel] = nil
                end
            end)
        }
    end
end

-- Rastreamento para linhas brancas do Omni Punch
local whiteLinesAllowed = true
workspaceRef.DescendantAdded:Connect(function(obj)
    if obj.Name:lower() == "whiteline" then
        local model = obj:FindFirstAncestorOfClass("Model")
        if model and model.Name:lower():find("omni") then
            if not whiteLinesAllowed then
                task.defer(function()
                    if obj and obj.Parent then
                        obj:Destroy()
                    end
                end)
            end
            whiteLinesAllowed = false
            task.delay(5, function()
                whiteLinesAllowed = true
            end)
        end
    end
    
    -- Destruir explicitamente objetos de consecutive punches
    local name = obj.Name:lower()
    if (name:find("consecutive") or name:find("barrage") or name:find("machine gun") or name:find("machinegun")) 
       and (obj:IsA("BasePart") or obj:IsA("ParticleEmitter")) then
        task.defer(function()
            if obj and obj.Parent then
                obj:Destroy()
            end
        end)
    end
    
    -- Destruir debris explicitamente
    if name:find("debris") and not name:find("foul") and not name:find("ball") then
        local model = obj:FindFirstAncestorOfClass("Model")
        local modelName = model and model.Name:lower() or ""
        if not (modelName:find("metal") or modelName:find("brutal") or modelName:find("omni")) then
            task.defer(function()
                if obj and obj.Parent then
                    obj:Destroy()
                end
            end)
        end
    end
end)

local function isProtected(obj, lowerName, model)
    -- Verifica se o objeto pertence a um personagem
    if model and model:FindFirstChildOfClass("Humanoid") then
        return true
    end

    -- Proteção para partes do corpo
    if bodyParts[lowerName] then
        return true
    end

    -- Proteção para emotes
    for keyword in next, allowedEmotes do
        if lowerName:find(keyword) then
            return true
        end
    end
    
    -- Proteção específica para Foul Ball (Metal Bat/Brutal Demon)
    local modelName = model and model.Name:lower() or ""
    if lowerName:find("ball") or lowerName:find("foul") or
       modelName:find("ball") or modelName:find("foul") or
       lowerName:find("metal bat") or lowerName:find("brutal demon") or
       modelName:find("metal bat") or modelName:find("brutal demon") then
        return true
    end

    -- Tratamento de linhas brancas (whiteline)
    if lowerName == "whiteline" then
        -- Caso seja um Omni Punch, trata com regra especial
        if model and model.Name:lower():find("omni") then
            if not omniPunchFirstLineFlag then
                omniPunchFirstLineFlag = true
                task.delay(5, function() 
                    omniPunchFirstLineFlag = false
                end)
                return true -- Apenas a primeira linha é protegida
            end
            return false -- Todas as demais são removidas
        end
        
        -- Para outras cutscenes não-Omni
        if model then
            registerCutscene(model)
            local registry = cutsceneRegistry[model]
            if registry and not registry.firstLineProtected then
                registry.firstLineProtected = true
                return true
            else
                return false
            end
        end
    end

    -- Proteção especial para Meteor e Frozen Soul
    if lowerName:find("meteor") then return true end
    if lowerName:find("frozen") and lowerName:find("soul") then return true end

    -- REJEITAR qualquer coisa com "consecutive", "barrage", "machine gun" no nome
    if lowerName:find("consecutive") or lowerName:find("barrage") or 
       lowerName:find("machine gun") or lowerName:find("machinegun") then
        return false
    end

    -- Rejeitar partes do Omni Directional Punch
    if (lowerName:find("omni") and lowerName:find("punch")) or
       (modelName:find("omni") and modelName:find("punch") and not lowerName:find("hitfx")) then
        return false
    end

    -- Verificação de debris - MAIS AGRESSIVA AGORA
    if lowerName:find("debris") then
        -- Proteção apenas para debris específicos
        if (modelName:find("metal") or modelName:find("brutal") or
            modelName:find("foul") or modelName:find("ball")) and
           (lowerName:find("foul") or lowerName:find("ball")) then
            return true
        end
        
        -- Se for debris de Omni, protege apenas hitfx
        if model and model.Name:lower():find("omni") and lowerName:find("hitfx") then 
            return true 
        end
        
        return false -- Remove TODOS os outros debris
    end

    -- Remover efeitos indesejados (ampliado)
    for effect in next, effectsToRemove do
        if lowerName:find(effect) then 
            return false 
        end
    end

    -- Remover multi-punches
    if lowerName:find("punch") or lowerName:find("hit") then
        if lowerName:find("multi") or lowerName:find("rapid") or lowerName:find("barrage") then
            return false
        end
        
        -- Exceção para hitfx específicos
        if lowerName:find("hitfx") and (modelName:find("metal") or modelName:find("foul") or modelName:find("ball")) then
            return true
        end
    end

    -- Padrão: proteger
    return true
end

-- Função otimizada para processar a fila
local function processQueue()
    if #queue == 0 or processingActive then return end
    
    processingActive = true
    local startTime = os.clock()
    local processed = 0
    
    while pointer <= #queue and processed < PARTS_PER_TICK do
        local obj = queue[pointer]
        if obj and obj.Parent then
            pcall(function() 
                obj:Destroy() 
            end)
        end
        pointer = pointer + 1
        processed = processed + 1
        
        -- Verifica tempo para evitar lag spikes
        if os.clock() - startTime > 0.008 then
            break
        end
    end
    
    if pointer > #queue then
        table.clear(queue)
        pointer = 1
    end
    
    processingActive = false
    collectgarbage("step", 5) -- Limpeza incremental de memória
end

-- Função otimizada para verificação em chunks
local function chunkedClean()
    if processingActive then return end
    
    processingActive = true
    local startTime = os.clock()
    local currentIndex = 1
    local processingLimit = 100 -- Reduzido para ser mais leve
    
    -- Obter descendentes por partes
    local function getNextDescendants()
        local result = {}
        local count = 0
        for _, child in ipairs(workspaceRef:GetChildren()) do
            if count >= processingLimit then break end
            if not child:IsA("Camera") and child ~= LocalPlayer.Character then
                if child:IsA("BasePart") and shouldProcess(child) then
                    count = count + 1
                    table.insert(result, child)
                elseif child:IsA("Model") then
                    for _, part in ipairs(child:GetDescendants()) do
                        if count >= processingLimit then break end
                        if part:IsA("BasePart") and shouldProcess(part) then
                            count = count + 1
                            table.insert(result, part)
                        end
                    end
                end
            end
        end
        return result
    end
    
    -- Verifica se devemos processar esta parte
    local function shouldProcess(obj)
        return not obj.Anchored and not obj.CanCollide
    end
    
    -- Processa objetos em chunks
    local descendants = getNextDescendants()
    
    for _, obj in ipairs(descendants) do
        local lowerName = obj.Name:lower()
        local model = obj:FindFirstAncestorOfClass("Model")
        
        if not isProtected(obj, lowerName, model) then
            queue[#queue + 1] = obj
        end
        
        -- Verifica tempo para evitar lag spikes
        if os.clock() - startTime > 0.02 then
            break
        end
    end
    
    processingActive = false
end

--=# Conexão do Freecam #=--
InputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == KEY_COMBO[2] and input:IsModifierKeyDown(KEY_COMBO[1]) then
        if camera.CameraType == Enum.CameraType.Custom then
            camera.CameraType = Enum.CameraType.Scriptable
        else
            camera.CameraType = Enum.CameraType.Custom
        end
    end
end)

--=# Sistema de Detecção Específica #=--
-- Monitoramento especial para consecutive punches
workspaceRef.ChildAdded:Connect(function(child)
    local name = child.Name:lower()
    
    -- Remover modelos de consecutive punches
    if (name:find("consecutive") or name:find("barrage") or 
        name:find("machine gun") or name:find("machinegun")) and child:IsA("Model") then
        task.defer(function()
            if child and child.Parent then
                child:Destroy()
            end
        end)
    end
end)

--=# Inicialização dos Sistemas #=--
-- Processamento da fila a cada heartbeat
RunService.Heartbeat:Connect(processQueue)

-- Limpeza em chunks com intervalo definido
task.spawn(function()
    while true do
        chunkedClean()
        processQueue() -- Garante que a fila seja processada após cada limpeza
        collectgarbage("step", 10) -- Limpeza de memória incremental
        task.wait(SCAN_INTERVAL)
    end
end)

--=# Otimização da Memória #=--
collectgarbage("setpause", 120)
collectgarbage("setstepmul", 250)

-- Limpeza periódica completa de memória
task.spawn(function()
    while true do
        task.wait(10)
        collectgarbage("collect")
    end
end)

getgenv().executed = true
