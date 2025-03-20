--=# Função de Proteção Atualizada #=--
local function isProtected(obj)
    -- Verificação de personagem
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Humanoid") then
        return true
    end

    -- Proteção de partes do corpo
    if bodyParts[obj.Name:lower()] then
        return true
    end

    -- Novo: Protege qualquer objeto ancorado ou no chão
    if obj:IsA("BasePart") and (obj.Anchored or obj.Position.Y < 5) then
        return true
    end

    -- Controle de linhas brancas
    if obj.Name:lower() == "whiteline" then
        local cutsceneModel = obj:FindFirstAncestorWhichIsA("Model")
        if cutsceneModel then
            if not cutsceneRegistry[cutsceneModel] then
                cutsceneRegistry[cutsceneModel] = true
                return true
            end
            return false
        end
    end

    -- Filtro de efeitos
    local lowerName = obj.Name:lower()
    return not (lowerName:find("afterimage") or lowerName:find("flowingwater"))
end

--=# Sistema de Limpeza Corrigido #=--
local function CleanWorld()
    local descendants = workspace:GetDescendants()
    for i = 1, #descendants, 15 do
        local obj = descendants[i]
        if obj:IsA("BasePart") and not isProtected(obj) then
            table.insert(cleanupQueue, obj)
        end
        if i % 75 == 0 then task.wait() end
    end
end
