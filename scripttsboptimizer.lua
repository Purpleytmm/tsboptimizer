local CLEAN_INTERVAL = 3 -- Tempo entre limpezas (aumente se precisar)
local PARTS_PER_FRAME = 5 -- Partes deletadas por frame

local debrisQueue = {}

-- Verifica se é parte de um jogador
local function isPlayerPart(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    return model and model:FindFirstChild("Humanoid")
end

-- Verifica se é parte de uma árvore (cache simples)
local function isTree(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    return model and model.Name:lower():find("tree") ~= nil
end

-- Limpeza otimizada
local function cleanDebris()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
            if not isPlayerPart(obj) and not isTree(obj) then
                table.insert(debrisQueue, obj)
            end
        end
    end
end

-- Processamento leve (evita sobrecarregar o executor)
task.spawn(function()
    while task.wait() do
        if #debrisQueue > 0 then
            for i = 1, math.min(PARTS_PER_FRAME, #debrisQueue) do
                pcall(function()
                    debrisQueue[1]:Destroy()
                end)
                table.remove(debrisQueue, 1)
            end
        end
    end
end)

-- Loop principal com intervalo ajustável
while task.wait(CLEAN_INTERVAL) do
    cleanDebris()
end
