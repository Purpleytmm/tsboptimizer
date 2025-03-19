-- Configurações
local CLEAN_INTERVAL = 5 -- Segundos (performance)
local PARTS_PER_FRAME = 3 -- 3 partes/frame (equilíbrio perfeito)
local FREE_CAM_KEY = Enum.KeyCode.P -- Tecla: Shift + P

--[[ 
    PROTEÇÃO TOTAL (Players/Dummies/Árvores)
--]]
local function isProtected(obj)
    -- Players
    local player = game.Players:GetPlayerFromCharacter(obj.Parent)
    if player then return true end

    -- Dummies/NPCs e Árvores
    local model = obj:FindFirstAncestorOfClass("Model")
    return model and (
        model:FindFirstChild("Humanoid") or 
        model.Name:lower():find("tree") or 
        model.Name:lower():find("dummy")
    )
end

--[[ 
    FREECAM (Shift + P) - Funciona SEMPRE
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
    SISTEMA DE DEBRIS (3/frame)
--]]
local queue = {}
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide and not isProtected(obj) then
        table.insert(queue, obj)
    end
end)

task.spawn(function()
    while task.wait(0.15) do -- Delay mínimo para evitar lag
        for i = 1, PARTS_PER_FRAME do
            if queue[1] then
                pcall(queue[1].Destroy, queue[1])
                table.remove(queue, 1)
            end
        end
    end
end)

-- Limpeza INICIAL (rápida e segura)
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide and not isProtected(obj) then
        obj:Destroy()
    end
end
