-- Configurações ULTRA-OTIMIZADAS
local PARTS_PER_TICK = 3    
local SCAN_INTERVAL = 1    
local KEY_COMBO = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}

--[[ 
    PROTEGE:
    - Personagens (mesmo que só tenham torso/cabeça)
    - Efeitos do Omni Punch
    - Nomes contendo: 'punch', 'omni', 'hit', 'fx', 'gfx'
]]
local function isProtected(obj)
    -- Verificação ultra-rápida de personagem
    local root = obj:FindFirstAncestor("HumanoidRootPart")
    if root and root.Parent:IsA("Model") then
        return true
    end

    -- Verificação de nome por padrão (evita lista fixa)
    local name = obj.Name:lower()
    if  name:find("punch") or 
        name:find("omni") or 
        name:find("hit") or 
        name:find("fx") or 
        name:find("gfx") then
        return true
    end

    -- Proteção hierárquica rápida
    local parent = obj.Parent
    while parent do
        if parent:IsA("Model") then
            local parentName = parent.Name:lower()
            if parentName:find("effect") or parentName:find("aura") then
                return true
            end
        end
        parent = parent.Parent
    end
    
    return false
end

-- Sistema de fila LOW MEMORY
local queue = {}
local pointer = 1

-- Varredura inicial otimizada para "batata"
local function chunkedClean()
    local descendants = workspace:GetDescendants()
    for i = 1, #descendants, 10 do  -- Processa em blocos de 10
        local obj = descendants[i]
        if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
            if not isProtected(obj) then
                queue[#queue+1] = obj
            end
        end
        if i % 50 == 0 then wait() end  -- Alívio para CPUs fracas
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

-- Detecção low-CPU de novos objetos
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

-- Inicialização leve
spawn(chunkedClean)
