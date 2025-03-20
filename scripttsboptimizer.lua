-- Configurações
local CLEAN_INTERVAL = 3 -- Intervalo de limpeza (aumentado para reduzir stutters)
local PARTS_PER_FRAME = 5 -- Partes processadas por frame (evita picos de CPU)
local FREE_CAM_KEY = Enum.KeyCode.P -- Tecla do Freecam: Shift + P

-- Lista de objetos protegidos (case-insensitive)
local PROTECTED_NAMES = {
    tree = true, dummy = true, humanoid = true, accessory = true,
    cape = true, aura = true, effect = true, hat = true, wings = true,
    skin = true, flowingwatergfx = true, weakestdummy = true
}

-- Cache de objetos protegidos
local protectedCache = {}
local modelCache = {}

-- Verificação ultra-otimizada
local function isProtected(obj)
    if protectedCache[obj] ~= nil then
        return protectedCache[obj]
    end

    -- Verifica se é parte de um Model com Humanoid (Players)
    local model = obj:FindFirstAncestorOfClass("Model")
    if model then
        if modelCache[model] ~= nil then
            protectedCache[obj] = modelCache[model]
            return modelCache[model]
        end

        if model:FindFirstChild("Humanoid") then
            protectedCache[obj] = true
            modelCache[model] = true
            return true
        end

        -- Verifica se é árvore ou dummy
        local modelName = model.Name:lower()
        if PROTECTED_NAMES[modelName] then
            protectedCache[obj] = true
            modelCache[model] = true
            return true
        end
    end

    -- Verifica por nome do objeto (acessórios, etc.)
    local objName = obj.Name:lower()
    protectedCache[obj] = PROTECTED_NAMES[objName] or false
    return protectedCache[obj]
end

-- Sistema de fila para processamento suave
local debrisQueue = {}
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
        if not isProtected(obj) then
            debrisQueue[#debrisQueue + 1] = obj
        end
    end
end)

-- Processamento leve usando Heartbeat
game:GetService("RunService").Heartbeat:Connect(function()
    for i = 1, math.min(PARTS_PER_FRAME, #debrisQueue) do
        local obj = debrisQueue[1]
        if obj and obj.Parent then
            pcall(obj.Destroy, obj)
        end
        table.remove(debrisQueue, 1)
    end
end)

-- Limpeza inicial otimizada
local function InitialClean()
    local objects = workspace:GetDescendants()
    for i = 1, #objects do
        local obj = objects[i]
        if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
            if not isProtected(obj) then
                debrisQueue[#debrisQueue + 1] = obj
            end
        end
    end
end

-- Freecam (Shift + P)
local camera = workspace.CurrentCamera
local freecamActive = false
local freecamPos, freecamCF

local function toggleFreecam()
    freecamActive = not freecamActive
    if freecamActive then
        freecamPos = camera.CFrame.Position
        freecamCF = camera.CFrame
        camera.CameraType = Enum.CameraType.Scriptable
    else
        camera.CameraType = Enum.CameraType.Custom
        camera.CFrame = freecamCF
    end
end

-- Ativa/desativa Freecam com Shift + P
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == FREE_CAM_KEY and input:IsModifierKeyDown(Enum.ModifierKey.Shift) then
        toggleFreecam()
    end
end)

-- Loop principal com cooldown
while true do
    InitialClean()
    if #debrisQueue == 0 then
        task.wait(CLEAN_INTERVAL) -- Espera se não houver debris
    else
        task.wait(0.1) -- Processa a fila continuamente
    end
end
