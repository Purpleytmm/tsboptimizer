-- Script otimizado para JJSploit - Remove TODOS os efeitos mencionados
-- Versão ultra-leve e eficiente que foca em todas as partes

local checkDelay = 0.3 -- Intervalo entre verificações para economizar recursos

-- Tabelas de termos para correspondência
local targetEffects = {
    -- Formato: {nomes do movimento, nomes do efeito}
    tableflipDebris = {{"tableflip", "table"}, {"debris", "chunk", "rubble", "part", "parts"}},
    incinerateDebris = {{"incinerate", "incin"}, {"debris", "chunk"}},
    omniLines = {{"omni", "directional", "punch", "odp"}, {"line", "white", "beam", "trail"}},
    garouWater = {{"garou"}, {"water", "flow", "after", "image", "effect", "flowingwater"}}
}

-- Função que verifica se um texto contém qualquer termo de uma lista
local function hasAnyTerm(text, terms)
    if not text then return false end
    text = text:lower()
    for _, term in pairs(terms) do
        if text:find(term) then
            return true
        end
    end
    return false
end

-- Função principal extremamente simplificada
local function cleanAllEffects()
    for _, obj in pairs(workspace:GetDescendants()) do
        -- Verifica apenas objetos que podem ser efeitos visuais
        if obj:IsA("BasePart") or obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("ParticleEmitter") then
            pcall(function()
                local objName = obj.Name:lower()
                
                -- Encontra 2 níveis de pais para verificar contexto
                local parent = obj.Parent
                local parentName = parent and parent.Name:lower() or ""
                local grandParent = parent and parent.Parent
                local grandParentName = grandParent and grandParent.Name:lower() or ""
                
                -- 1. Remover debris do TableFlip
                if hasAnyTerm(objName, targetEffects.tableflipDebris[2]) and 
                   (hasAnyTerm(parentName, targetEffects.tableflipDebris[1]) or 
                    hasAnyTerm(grandParentName, targetEffects.tableflipDebris[1])) then
                    
                    -- Verifica se está no ar (Y > 1)
                    if not obj:IsA("BasePart") or obj.Position.Y > 1 then
                        obj:Destroy()
                    end
                end
                
                -- 2. Remover debris do Incinerate
                if hasAnyTerm(objName, targetEffects.incinerateDebris[2]) and 
                   (hasAnyTerm(parentName, targetEffects.incinerateDebris[1]) or 
                    hasAnyTerm(grandParentName, targetEffects.incinerateDebris[1])) then
                    
                    -- Verifica se está no ar (Y > 1)
                    if not obj:IsA("BasePart") or obj.Position.Y > 1 then
                        obj:Destroy()
                    end
                end
                
                -- 3. Remover linhas brancas do Omni Directional Punch
                if hasAnyTerm(objName, targetEffects.omniLines[2]) and 
                   (hasAnyTerm(parentName, targetEffects.omniLines[1]) or 
                    hasAnyTerm(grandParentName, targetEffects.omniLines[1])) then
                    
                    obj:Destroy()
                end
                
                -- 4. Remover efeitos de água do Garou
                if hasAnyTerm(objName, targetEffects.garouWater[2]) and 
                   (hasAnyTerm(parentName, targetEffects.garouWater[1]) or 
                    hasAnyTerm(grandParentName, targetEffects.garouWater[1])) then
                    
                    obj:Destroy()
                end
            end)
        end
    end
end

-- Executa o limpador em intervalos regulares em vez de a cada frame
while true do
    pcall(cleanAllEffects)
    wait(checkDelay)
end
