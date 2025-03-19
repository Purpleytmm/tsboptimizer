-- Configuração
local CLEAN_INTERVAL = 10 -- Segundos (CPU quase zero)
local PARTS_PER_FRAME = 3 -- 3 partes/frame (equilíbrio performance/eficiência)

-- Verificação direta de proteção
local function isProtected(obj)
    -- Verifica se é parte de um jogador
    local player = game.Players:GetPlayerFromCharacter(obj.Parent)
    if player then return true end

    -- Verifica ancestrais (árvores, cutscenes, dummy)
    local model = obj:FindFirstAncestorWhichIsA("Model")
    if model then
        return model:FindFirstChild("Humanoid") or 
               model.Name:lower():find("tree") or 
               model.Name:find("SeriousPunch") or 
               model.Name:find("WeakestDummy")
    end
    
    return false
end

-- Sistema de fila
local queue = {}
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide and not isProtected(obj) then
        table.insert(queue, obj)
    end
end)

-- Processa 3 partes/frame
task.spawn(function()
    while task.wait(0.3) do -- Intervalo reduzido para melhor eficiência
        for i = 1, math.min(PARTS_PER_FRAME, #queue) do
            pcall(queue[1].Destroy, queue[1])
            table.remove(queue, 1)
        end
    end
end)

-- Limpeza inicial
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide and not isProtected(obj) then
        obj:Destroy()
    end
end
