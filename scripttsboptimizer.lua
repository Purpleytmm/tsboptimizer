-- Configurações
local CLEAN_INTERVAL = 5 -- Segundos (performance)
local PARTS_PER_FRAME = 5 -- Debris/frame (leve)
local FREE_CAM_KEY = Enum.KeyCode.P -- Freecam: Shift + P

--[[ 
    PROTEÇÃO TOTAL (Players/Árvores/Dummies)
--]]
local function isProtected(obj)
    -- Verifica se é parte de um Player
    local player = game.Players:GetPlayerFromCharacter(obj.Parent)
    if player then return true end

    -- Verifica Dummies/NPCs e Árvores
    local model = obj:FindFirstAncestorOfClass("Model")
    if model then
        return model:FindFirstChild("Humanoid") or 
               model.Name:lower():find("tree") or 
               model.Name:lower():find("dummy") -- Adicionado proteção para dummies
    end
    
    return false
end

--[[ 
    FREECAM (Shift + P) - 100% Funcional
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

game:GetService("UserInputService").InputBegan:Connect(function(input, _)
    if input.KeyCode == FREE_CAM_KEY and input:IsModifierKeyDown(Enum.ModifierKey.Shift) then
        toggleFreecam()
    end
end)

--[[ 
    SISTEMA DE DEBRIS (Otimizado)
--]]
local queue = {}
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide and not isProtected(obj) then
        table.insert(queue, obj)
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        for i = 1, math.min(PARTS_PER_FRAME, #queue) do
            pcall(queue[1].Destroy, queue[1])
            table.remove(queue, 1)
        end
    end
end)

--[[ 
    LIMPEZA INICIAL
--]]
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide and not isProtected(obj) then
        obj:Destroy()
    end
end
