-- Configurações
local CLEAN_INTERVAL = 3 -- Intervalo de limpeza (evita stutters)
local PARTS_PER_FRAME = 5 -- Partes processadas por frame
local FREE_CAM_KEY = Enum.KeyCode.P -- Tecla do Freecam: Shift + P

-- Lista de nomes protegidos (case-insensitive)
local PROTECTED_NAMES = {
    tree = true, dummy = true, humanoid = true, accessory = true,
    cape = true, aura = true, effect = true, hat = true, wings = true,
    skin = true, flowingwatergfx = true, weakestdummy = true
}

-- Função de verificação sem cache para evitar falsos positivos
local function isProtected(obj)
    -- Verifica se o objeto faz parte de um personagem
    local character = obj:FindFirstAncestorOfClass("Model")
    if character and game.Players:GetPlayerFromCharacter(character) then
        return true
    end

    -- Se o objeto pertencer a um modelo com Humanoid, proteja-o
    if character and character:FindFirstChild("Humanoid") then
        return true
    end

    -- Verifica se o nome do modelo está na lista de protegidos
    if character then
        local modelName = character.Name:lower()
        if PROTECTED_NAMES[modelName] then
            return true
        end
    end

    -- Verifica o próprio nome do objeto
    local objName = obj.Name:lower()
    if PROTECTED_NAMES[objName] then
        return true
    end

    return false
end

-- Fila otimizada usando ponteiro para evitar table.remove
local debrisQueue = {}
local queueIndex = 1

local function addToQueue(obj)
    table.insert(debrisQueue, obj)
end

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
        if not isProtected(obj) then
            addToQueue(obj)
        end
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    local processed = 0
    while processed < PARTS_PER_FRAME and queueIndex <= #debrisQueue do
        local obj = debrisQueue[queueIndex]
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
        queueIndex = queueIndex + 1
        processed = processed + 1
    end
    -- Quando todos os itens forem processados, reinicia a fila
    if queueIndex > #debrisQueue then
        debrisQueue = {}
        queueIndex = 1
    end
end)

-- Limpeza inicial sem percorrer toda a árvore a cada frame
local function InitialClean()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
            if not isProtected(obj) then
                addToQueue(obj)
            end
        end
    end
end

InitialClean()
while task.wait(CLEAN_INTERVAL) do
    InitialClean()
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

game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == FREE_CAM_KEY and input:IsModifierKeyDown(Enum.ModifierKey.Shift) then
        toggleFreecam()
    end
end)
