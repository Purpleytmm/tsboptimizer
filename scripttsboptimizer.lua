-- Configurações
local CLEAN_INTERVAL = 3 -- Intervalo de limpeza (evita stutters)
local PARTS_PER_FRAME = 2
local FREE_CAM_KEY = Enum.KeyCode.P -- Tecla do Freecam: Shift + P
local CUTSCENE_FOLDER_NAME = "OmniDirectionalPunchCutscene" -- Pasta com os debris da cutscene

-- Lista de nomes protegidos (case-insensitive)
local PROTECTED_NAMES = {
    tree = true, dummy = true, humanoid = true, accessory = true,
    cape = true, aura = true, effect = true, hat = true, wings = true,
    skin = true, flowingwatergfx = true, weakestdummy = true
}

-- Função de verificação sem cache para evitar falsos positivos
local function isProtected(obj)
    local character = obj:FindFirstAncestorOfClass("Model")
    if character and game.Players:GetPlayerFromCharacter(character) then
        return true
    end

    if character and character:FindFirstChild("Humanoid") then
        return true
    end

    if character then
        local modelName = character.Name:lower()
        if PROTECTED_NAMES[modelName] then
            return true
        end
    end

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

-- Verifica se o objeto faz parte da cutscene e, portanto, não deve ser removido
local function isCutsceneDebris(obj)
    local cutsceneFolder = workspace:FindFirstChild(CUTSCENE_FOLDER_NAME)
    if cutsceneFolder and obj:IsDescendantOf(cutsceneFolder) then
        return true
    end
    return false
end

-- Evento que adiciona objetos à fila, se atenderem aos critérios
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
        if isCutsceneDebris(obj) then
            return
        end
        if not isProtected(obj) then
            addToQueue(obj)
        end
    end
end)

local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function()
    local processed = 0
    while processed < PARTS_PER_FRAME and queueIndex <= #debrisQueue do
        local obj = debrisQueue[queueIndex]
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
        queueIndex = queueIndex + 1
        processed = processed + 1
    end
    if queueIndex > #debrisQueue then
        debrisQueue = {}
        queueIndex = 1
    end
end)

-- Limpeza inicial otimizada (evita percorrer toda a árvore sem necessidade)
local function InitialClean()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
            if isCutsceneDebris(obj) then
                -- Pula os debris da cutscene
            elseif not isProtected(obj) then
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
