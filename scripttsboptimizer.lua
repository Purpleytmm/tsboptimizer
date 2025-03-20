-- Configurações de Freecam
local FREE_CAM_KEY = Enum.KeyCode.P -- Freecam: Shift + P
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

-------------------------------------------------
-- Sistema de Debris (Remoção Imediata)
-------------------------------------------------

--[[ 
    Proteção Total (Players/Árvores/Dummies)
--]]
local function isProtected(obj)
    local player = game.Players:GetPlayerFromCharacter(obj.Parent)
    if player then return true end

    local model = obj:FindFirstAncestorOfClass("Model")
    if model then
        return model:FindFirstChild("Humanoid") or 
               model.Name:lower():find("tree") or 
               model.Name:lower():find("dummy")
    end

    return false
end

-- Remove objetos adicionados que não sejam protegidos
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide and not isProtected(obj) then
        if obj and obj.Destroy then
            obj:Destroy()
        end
    end
end)

-- Limpeza inicial de objetos não protegidos
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide and not isProtected(obj) then
        obj:Destroy()
    end
end
