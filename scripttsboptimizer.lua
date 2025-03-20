-- Configurações ULTRA-OTIMIZADAS
local PARTS_PER_TICK = 2
local SCAN_INTERVAL = 2
local KEY_COMBO = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}

-- Função de proteção TOTAL de personagens
local function isProtected(obj)
    -- Verificação ULTRA-RÁPIDA de personagem (nova técnica)
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model.PrimaryPart and model:FindFirstChild("Humanoid") then
        return true
    end

    -- Protege partes do corpo por nome (mesmo em modelos diferentes)
    local bodyParts = {
        head = true, torso = true, leftarm = true, rightarm = true,
        leftleg = true, rightleg = true, humanoidrootpart = true
    }
    if bodyParts[obj.Name:lower()] then
        return true
    end

    -- Verificação de efeitos (mantém o punch)
    local name = obj.Name:lower()
    return  name:find("punch") or 
            name:find("omni") or 
            name:find("hit") or 
            name:find("fx") or 
            name:find("gfx")
end

-- Sistema de fila LOW MEMORY
local queue = {}
local pointer = 1

-- Varredura inicial otimizada
local function chunkedClean()
    local descendants = workspace:GetDescendants()
    for i = 1, #descendants, 10 do
        local obj = descendants[i]
        if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
            if not isProtected(obj) then
                queue[#queue+1] = obj
            end
        end
        if i % 50 == 0 then wait() end
    end
end

-- Processamento MÍNIMO
game:GetService("RunService").Heartbeat:Connect(function()
    for _ = 1, PARTS_PER_TICK do
        if queue[pointer] then
            pcall(function() queue[pointer]:Destroy() end)
            pointer += 1
        else
            queue = {}
            pointer = 1
            break
        end
    end
end)

-- Detecção low-CPU
spawn(function()
    while wait(SCAN_INTERVAL) do
        chunkedClean()
    end
end)

-- Freecam ULTRA SIMPLES
local camera = workspace.CurrentCamera
local input = game:GetService("UserInputService")

input.InputBegan:Connect(function(input)
    if input.KeyCode == KEY_COMBO[2] and input:IsModifierKeyDown(KEY_COMBO[1]) then
        camera.CameraType = camera.CameraType == Enum.CameraType.Custom 
            and Enum.CameraType.Scriptable 
            or Enum.CameraType.Custom
    end
end)

spawn(chunkedClean)
