--=# Configurações Principais #=--
local PARTS_PER_TICK = 40
local SCAN_INTERVAL = 0.75
local KEY_COMBO = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}

--=# Cache de Serviços #=--
local RunService = game:GetService("RunService")
local InputService = game:GetService("UserInputService")
local workspace = workspace
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
    ["machine gun"] = true
}

--=# Sistema de Limpeza #=--
local queue = {}
local pointer = 1

--=# Funções Otimizadas #=--
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

-- Rastreamento global estrito para linhas brancas do Omni Punch
local whiteLinesAllowed = true
workspace.DescendantAdded:Connect(function(obj)
    if obj.Name:lower() == "whiteline" then
        local model = obj:FindFirstAncestorOfClass("Model")
        if model and model.Name:lower():find("omni") then
            if not whiteLinesAllowed then
                task.defer(function() -- Remover em task separada para evitar erros
                    if obj and obj.Parent then
                        obj:Destroy()
                    end
                end)
            end
            whiteLinesAllowed = false -- Após a primeira linha, não permite mais
            
            -- Reset automático após 5 segundos (duração típica de cutscene)
            task.delay(5, function()
                whiteLinesAllowed = true
            end)
        end
    end
end)

local function isProtected(obj, lowerName, model)
    -- Verifica se o objeto pertence a um personagem
    if model and model:FindFirstChild("Humanoid") then
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

    -- Tratamento RIGOROSO de linhas brancas (whiteline)
    if lowerName == "whiteline" then
        -- Caso seja um Omni Punch, trata com regra especial global
        if model and model.Name:lower():find("omni") then
            -- A lógica principal está no evento DescendantAdded
            -- Apenas mantém a proteção para a primeira linha
            if not omniPunchFirstLineFlag then
                omniPunchFirstLineFlag = true
                
                -- Reset após tempo para permitir futuras cutscenes
                task.delay(7,5, function() 
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
            
            if not registry.firstLineProtected then
                registry.firstLineProtected = true
                return true -- Primeira linha protegida
            else
                return false -- Linhas subsequentes removidas
            end
        end
    end

    -- Proteção especial para Meteor e Frozen Soul
    if lowerName:find("meteor") then return true end
    if lowerName:find("frozen") and lowerName:find("soul") then return true end

    -- Remover efeitos de golpes consecutivos e machine gun blows
    if lowerName:find("consecutive") or lowerName:find("machine gun") or lowerName:find("machinegun") then
        return false
    end

    -- Remover partes do Omni Directional Punch (exceto a primeira linha branca)
    if lowerName:find("omni") and lowerName:find("punch") then return false end

    -- Verificação de debris
    if lowerName:find("debris") then
        -- Proteção para debris do Foul Ball
        if modelName:find("metal") or modelName:find("brutal") or
           modelName:find("foul") or modelName:find("ball") then
            return true
        end
        
        -- Se o modelo for relacionado a Omni, protege
        if model and model.Name:lower():find("omni") then return true end
        
        return false -- Remove outros debris
    end

    -- Remover efeitos indesejados
    for effect in next, effectsToRemove do
        if lowerName:find(effect) then return false end
    end

    -- Remover efeitos de multi-golpes
    if lowerName:find("punch") then
        -- Remove gráficos de golpes consecutivos mas mantém hitfx normais
        if lowerName:find("multi") or lowerName:find("rapid") or lowerName:find("barrage") then
            return false
        end
        
        -- Mantém efeitos de golpes principais
        if lowerName:find("hitfx") then
            return true
        end
    end

    -- Padrão: proteger
    return true
end

local function processQueue()
    local start = os.clock()
    local limit = PARTS_PER_TICK
    
    while pointer <= #queue and limit > 0 do
        local obj = queue[pointer]
        if obj and obj.Parent then -- Verificar se o objeto ainda existe
            pcall(function() obj:Destroy() end)
        end
        pointer = pointer + 1
        limit = limit - 1
        
        -- Prevenir congelamento em casos extremos
        if os.clock() - start > 0.008 then -- ~8ms threshold
            break
        end
    end
    
    if pointer > #queue then
        table.clear(queue)
        pointer = 1
    end
end

local function chunkedClean()
    local descendants = workspace:GetDescendants()
    local processingIndex = 1
    local processingLimit = 150 -- Processa 150 objetos por frame
    
    -- Função auxiliar para processamento incremental
    local function processChunk()
        local endIndex = math.min(processingIndex + processingLimit, #descendants)
        
        for i = processingIndex, endIndex do
            local obj = descendants[i]
            if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
                local lowerName = obj.Name:lower()
                local model = obj:FindFirstAncestorOfClass("Model")
                
                if not isProtected(obj, lowerName, model) then
                    queue[#queue + 1] = obj
                end
            end
        end
        
        processingIndex = endIndex + 1
        return processingIndex <= #descendants
    end
    
    -- Loop de processamento em múltiplos frames
    while processChunk() do
        RunService.Heartbeat:Wait()
    end
end

--=# Conexão do Freecam #=--
InputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == KEY_COMBO[2] and input:IsModifierKeyDown(KEY_COMBO[1]) then
        camera.CameraType = (camera.CameraType == Enum.CameraType.Custom)
            and Enum.CameraType.Scriptable
            or Enum.CameraType.Custom
    end
end)

--=# Inicialização de Loops #=--
RunService.Heartbeat:Connect(processQueue)

task.spawn(function()
    while true do
        chunkedClean()
        task.wait(SCAN_INTERVAL)
    end
end)

--=# Otimização da Memória #=--
collectgarbage("setpause", 110)
collectgarbage("setstepmul", 200)
