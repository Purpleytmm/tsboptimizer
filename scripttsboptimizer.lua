local CLEAN_INTERVAL = 2 -- Tempo entre ciclos (balanceado)
local PARTS_PER_FRAME = 10 -- Partes/frame (rápido sem lag)
local queue = {}

-- Protege Weakest Dummy, Players e Árvores
local function isProtected(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    if model then
        return model:FindFirstChild("Humanoid") 
            or model.Name:lower():find("weakestdummy")
            or model.Name:lower():find("tree")
    end
    return false
end

-- Remove After Images, Tableflip, ODP, etc.
local function isDebris(obj)
    return not obj.Anchored 
        and not obj.CanCollide 
        and (obj.Name:lower():find("afterimage") 
            or obj.Name:lower():find("flowingwater") 
            or obj.Name:lower():find("tableflip"))
end

-- Coleta debris
local function collectDebris()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and isDebris(obj) and not isProtected(obj) then
            table.insert(queue, obj)
        end
    end
end

-- Processamento rápido e seguro
task.spawn(function()
    while task.wait(0.1) do
        for i = 1, PARTS_PER_FRAME do
            if queue[1] then
                pcall(queue[1].Destroy, queue[1])
                table.remove(queue, 1)
            end
        end
    end
end)

-- Loop principal
while task.wait(CLEAN_INTERVAL) do
    collectDebris()
end
