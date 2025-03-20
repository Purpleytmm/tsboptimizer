-- Configurações
local CLEAN_INTERVAL = 2 -- Limpeza a cada 2 segundos

-- Lista de Proteção (Players/Dummies/Árvores/Acessórios)
local PROTECTED_NAMES = {
    "Worn Cape", "Mahoraga Well", "Tree", "Dummy", "Humanoid", 
    "Accessory", "Hat", "Cloak", "Aura", "Effect"
}

-- Verifica se o objeto é protegido
local function isProtected(obj)
    -- Players e Humanoids
    if obj:FindFirstAncestorOfClass("Model") and obj:FindFirstAncestorOfClass("Humanoid") then
        return true
    end

    -- Acessórios (capas, asas, etc.)
    if obj:IsA("Accessory") then
        return true
    end

    -- Verifica por nome
    local name = obj.Name:lower()
    for _, keyword in pairs(PROTECTED_NAMES) do
        if name:find(keyword:lower()) then
            return true
        end
    end

    -- Verifica ancestrais (árvores, dummies)
    local model = obj:FindFirstAncestorOfClass("Model")
    if model then
        local modelName = model.Name:lower()
        return modelName:find("tree") or modelName:find("dummy")
    end
    
    return false
end

-- Remove TUDO que não é protegido
local function CleanDebris()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
            if not isProtected(obj) then
                pcall(obj.Destroy, obj)
            end
        end
    end
end

-- Loop principal (2 segundos)
while task.wait(CLEAN_INTERVAL) do
    CleanDebris()
end
