local CLEAN_INTERVAL = 10 -- Intervalo grande para reduzir lag
local MAX_PER_FRAME = 3 -- Máximo de partes processadas por frame

local queue = {}

-- Verifica se é parte de jogador ou árvore
local function isProtected(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    return (model and (model:FindFirstChild("Humanoid") or model.Name:lower():find("tree")))
end

-- Remove SPECIFICAMENTE os efeitos que você quer
local function isUnwantedEffect(obj)
    local name = obj.Name:lower()
    return name:find("flowingwater") or name:find("flowingwatergfx") or name:find("tableflip")
end

-- Limpeza otimizada por fila
local function clean()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
            if isUnwantedEffect(obj) or (not isProtected(obj)) then
                table.insert(queue, obj)
            end
        end
    end
end

-- Processamento suave (evita lag)
task.spawn(function()
    while task.wait() do
        for i = 1, MAX_PER_FRAME do
            if #queue > 0 then
                pcall(queue[1].Destroy, queue[1])
                table.remove(queue, 1)
            end
        end
    end
end)

-- Loop principal
while task.wait(CLEAN_INTERVAL) do
    clean()
end
