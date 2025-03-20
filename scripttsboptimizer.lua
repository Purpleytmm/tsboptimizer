-- Configurações
local CLEAN_INTERVAL = 2 -- Limpeza a cada 2 segundos
local PROTECTED_NAMES = { -- Atualize com os nomes do seu jogo!
    "Tree", "Dummy", "Humanoid", "Accessory", 
    "Cape", "Aura", "Effect", "Hat", "Wings", 
    "Skin",  "WeakestDummy"
}

-- Verificação Ultra-Otimizada (FIXED)
local function isProtected(obj)
    -- Players: Verifica se é parte de um Model com Humanoid
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Humanoid") then
        return true
    end

    -- Árvores e Dummies
    if model then
        local modelName = model.Name:lower()
        if modelName:match("tree") or modelName:match("dummy") then
            return true
        end
    end

    -- Verificação por Nome (Acessórios)
    local name = obj.Name:lower()
    for _, keyword in pairs(PROTECTED_NAMES) do
        if name:match(keyword:lower()) then
            return true
        end
    end

    return false
end

-- Sistema de Limpeza Direto
local function CleanDebris()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
            if not isProtected(obj) then
                pcall(obj.Destroy, obj)
            end
        end
    end
end

-- Loop Principal
while task.wait(CLEAN_INTERVAL) do
    CleanDebris()
end
