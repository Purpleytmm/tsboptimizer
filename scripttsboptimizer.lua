local CLEAN_INTERVAL = 5 -- Segundos (performance máxima)
local queue = {}

-- Verificação RÁPIDA de proteção (players, árvores, dummy)
local function isProtected(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    return model and (
        model:FindFirstChild("Humanoid") or 
        model.Name:lower():find("weakestdummy") or 
        model.Name:lower():find("tree")
    )
end

-- Adiciona debris à fila automaticamente
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide and not isProtected(obj) then
        table.insert(queue, obj)
    end
end)

-- Remove 5 debris/frame (zero lag)
task.spawn(function()
    while task.wait() do
        for i = 1, math.min(5, #queue) do
            pcall(queue[1].Destroy, queue[1])
            table.remove(queue, 1)
        end
    end
end)

-- Limpeza FULL inicial + periódica (otimizada)
local function fastClean()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide and not isProtected(obj) then
            table.insert(queue, obj)
        end
    end
end

fastClean()
while task.wait(CLEAN_INTERVAL) do
    fastClean()
end
