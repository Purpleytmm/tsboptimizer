--=# Configurações Principais #=--
local PARTS_PER_TICK = 6
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
    -- Verificação RÁPIDA de personagem
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Humanoid") then
        return true
    end

    -- Proteção de partes do corpo
    if bodyParts[obj.Name:lower()] then
        return true
    end

    -- Controle MULTI-INSTÂNCIA de linhas brancas
    if obj.Name:lower() == "whiteline" then
        local cutsceneModel = obj:FindFirstAncestorWhichIsA("Model")
        if cutsceneModel then
            registerCutscene(cutsceneModel)
            if not cutsceneRegistry[cutsceneModel].firstLineProtected then
                cutsceneRegistry[cutsceneModel].firstLineProtected = true
                return true -- Mantém primeira linha
            end
            return false -- Remove linhas extras
        end
    end

    -- Filtro de efeitos indesejados
    local lowerName = obj.Name:lower()
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
        if i % 75 == 0 then task.wait() end -- Alívio de CPU
    end
end

--=# Processamento Principal #=--
game:GetService("RunService").Heartbeat:Connect(function()
    for _ = 1, PARTS_PER_TICK do
        if queue[pointer] then
            pcall(queue[pointer].Destroy, queue[pointer])
            pointer += 1
        else
            table.clear(queue)
            pointer = 1
            break
        end
    end
end)

--=# Freecam ULTRA LEVE #=--
local camera = workspace.CurrentCamera
local input = game:GetService("UserInputService")

input.InputBegan:Connect(function(input)
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
