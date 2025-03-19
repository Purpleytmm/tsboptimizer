-- Configurações
local CLEAN_INTERVAL = 5 -- Tempo entre limpezas
local PARTS_PER_FRAME = 10 -- 10 partes/frame (rápido e eficiente)
local FREE_CAM_KEY = Enum.KeyCode.P -- Tecla do Freecam: Shift + P

-- Lista de Acessórios Protegidos (atualize com os nomes do seu jogo!)
local PROTECTED_ACCESSORIES = {
    "Worn Cape", "Mahoraga Well", "Cloak", "Aura", "Effect",
    "Accessory", "Hat", "Wings", "Skin", "Cosmetic", "Cape"
}

--[[ 
    VERIFICA SE O OBJETO É PROTEGIDO (Players/Dummies/Árvores/Acessórios)
--]]
local function isProtected(obj)
    -- Verifica se é parte de um Player
    local player = game.Players:GetPlayerFromCharacter(obj.Parent)
    if player then return true end

    -- Verifica se é um Acessório
    local name = obj.Name:lower()
    for _, keyword in pairs(PROTECTED_ACCESSORIES) do
        if name:find(keyword:lower()) then
            return true
        end
    end

    -- Verifica Dummies/Árvores
    local model = obj:FindFirstAncestorOfClass("Model")
    if model then
        local modelName = model.Name:lower()
        return model:FindFirstChild("Humanoid") or 
               modelName:find("tree") or 
               modelName:find("dummy")
    end
    
    return false
end

--[[ 
    FREECAM (Shift + P) - Funciona durante cutscenes!
--]]
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

--[[ 
    SISTEMA DE LIMPEZA (Otimizado para Low-End)
--]]
local queue = {}
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide and not isProtected(obj) then
        -- Remove Efeitos do Flowing Water (após verificação)
        if obj.Name:lower():find("flowingwater") then
            obj:Destroy()
        else
            table.insert(queue, obj)
        end
    end
end)

-- Processamento leve (10 partes/frame)
task.spawn(function()
    while task.wait(0.1) do
        for i = 1, math.min(PARTS_PER_FRAME, #queue) do
            if queue[1] then
                pcall(queue[1].Destroy, queue[1])
                table.remove(queue, 1)
            end
        end
    end
end)

--[[ 
    INICIALIZAÇÃO (Remove debris existentes)
--]]
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide and not isProtected(obj) then
        -- Remove Efeitos do Flowing Water (após verificação)
        if obj.Name:lower():find("flowingwater") then
            obj:Destroy()
        else
            obj:Destroy()
        end
    end
end
