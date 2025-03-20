--=# Configurações Principais #=--
local PARTS_PER_TICK = 35
local SCAN_INTERVAL = 1
local KEY_COMBO = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}

--=# Sistema de Registro de Cutscenes #=--
local cutsceneRegistry = {}
local function registerCutscene(cutsceneModel)
    if not cutsceneRegistry[cutsceneModel] then
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

--=# Função de Proteção 2.0 #=--
local bodyParts = {
    head = true, torso = true, humanoidrootpart = true,
    leftarm = true, rightarm = true, leftleg = true, rightleg = true
}

local function isProtected(obj)
    local lowerName = obj.Name:lower()
    
    -- Verificação RÁPIDA de personagem
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Humanoid") then
        return true
    end

    -- Proteção de partes do corpo
    if bodyParts[lowerName] then
        return true
    end
    
    -- PERMISSÃO ESPECIAL: Meteor
    if lowerName:find("meteor") then
        return true
    end

    -- PERMISSÃO ESPECIAL: Frozen Soul
    if lowerName:find("frozen") and lowerName:find("soul") then
        return true
    end
    
    -- PERMISSÃO ESPECIAL: Omni Directional Punch
    -- Protege todos os objetos relacionados a esse ataque
    if lowerName:find("omni") and lowerName:find("punch") then
        return true
    end
    
    -- Proteção adicional para debris do ODP
    if lowerName:find("debris") then
        -- Verifica se está dentro de um modelo relacionado ao Omni Directional Punch
        if model and model.Name:lower():find("omni") then
            return true
        end
    end

    -- Controle MULTI-INSTÂNCIA de linhas brancas
    if lowerName == "whiteline" then
        local cutsceneModel = obj:FindFirstAncestorWhichIsA("Model")
        if cutsceneModel then
            -- Para cutscenes de Omni Directional Punch, trate especificamente
            if cutsceneModel.Name:lower():find("omni") then
                registerCutscene(cutsceneModel)
                if not cutsceneRegistry[cutsceneModel].firstLineProtected then
                    cutsceneRegistry[cutsceneModel].firstLineProtected = true
                    return true -- Mantém apenas a primeira linha branca
                end
                return false -- Remove as demais linhas
            end
            
            -- Para outras cutscenes, mantém o comportamento original
            registerCutscene(cutsceneModel)
            if not cutsceneRegistry[cutsceneModel].firstLineProtected then
                cutsceneRegistry[cutsceneModel].firstLineProtected = true
                return true -- Mantém primeira linha
            end
            return false -- Remove linhas extras
        end
    end

    -- Filtro de efeitos indesejados
    if lowerName:find("afterimage") 
       or lowerName:find("flowingwater")
       or lowerName:find("_trail") then
        return false
    end

    -- Mantém efeitos essenciais
    return lowerName:find("punch") or lowerName:find("hitfx")
end

--=# Sistema de Limpeza Otimizado #=--
local queue = {}
local pointer = 1

local function chunkedClean()
    local descendants = workspace:GetDescendants()
    for i = 1, #descendants, 15 do -- Processamento em blocos
        local obj = descendants[i]
        if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
            if not isProtected(obj) then
                table.insert(queue, obj)
            end
        end
        if i % 75 == 0 then
            task.wait() -- Alívio de CPU
        end
    end
end

--=# Processamento Principal #=--
game:GetService("RunService").Heartbeat:Connect(function()
    for _ = 1, PARTS_PER_TICK do
        if queue[pointer] then
            pcall(queue[pointer].Destroy, queue[pointer])
            pointer = pointer + 1
        else
            table.clear(queue)
            pointer = 1
            break
        end
    end
end)

--=# Freecam ULTRA LEVE #=--
local camera = workspace.CurrentCamera
local inputService = game:GetService("UserInputService")

inputService.InputBegan:Connect(function(input)
    if input.KeyCode == KEY_COMBO[2] and input:IsModifierKeyDown(KEY_COMBO[1]) then
        camera.CameraType = camera.CameraType == Enum.CameraType.Custom 
            and Enum.CameraType.Scriptable 
            or Enum.CameraType.Custom
    end
end)

--=# Execução Automática #=--
task.spawn(function()
    while task.wait(SCAN_INTERVAL) do
        chunkedClean()
    end
end)

--=# Otimização Final #=--
collectgarbage("setpause", 100)
collectgarbage("setstepmul", 200)

