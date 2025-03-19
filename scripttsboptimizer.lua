local CLEAN_INTERVAL = 5 -- Intervalo aumentado para reduzir CPU
local PARTS_PER_FRAME = 2 -- Reduzido para processamento mínimo

local debrisQueue = {}

-- Verificação otimizada de ancestry (sem funções extras)
local function shouldKeep(obj)
    -- Verifica Flowing Water primeiro (prioridade máxima)
    if obj.Name:lower():find("flowing") or obj.Name:lower():find("afterimage") then
        return true
    end
    
    -- Verificação combinada de player + árvore
    local model = obj:FindFirstAncestorOfClass("Model")
    if model then
        return model:FindFirstChild("Humanoid") or model.Name:lower():find("tree")
    end
    
    return false
end

-- Limpeza ultra-otimizada
local function cleanDebris()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
            if not shouldKeep(obj) then
                table.insert(debrisQueue, obj)
            end
        end
    end
end

-- Processamento mega leve (1 parte/frame)
task.spawn(function()
    while task.wait(0.5) do -- Adicionado delay extra
        for i = 1, math.min(PARTS_PER_FRAME, #debrisQueue) do
            pcall(function()
                debrisQueue[1]:Destroy()
            end)
            table.remove(debrisQueue, 1)
        end
    end
end)

-- Loop principal super espaçado
while task.wait(CLEAN_INTERVAL) do
    cleanDebris()
end
