-- Script otimizado para JJSploit - versão ultra-leve
-- Remove efeitos do TableFlip, Incinerate, OmniDirectionalPunch e Garou

local checkInterval = 0.5 -- Intervalo entre verificações (aumentado para economizar recursos)
local lastCheck = 0

-- Função principal extremamente simplificada
local function removeLag()
    local currentTime = tick()
    if currentTime - lastCheck < checkInterval then return end
    lastCheck = currentTime
    
    -- Nomes a serem verificados (em minúsculo)
    local debrisNames = {"debris", "chunk", "rubble"}
    local moveNames = {"tableflip", "incinerate"}
    local lineNames = {"line", "whiteline"}
    local waterNames = {"flowingwater", "watereffect", "afterimage"}
    
    -- Encontra efeitos a serem removidos
    for _, v in pairs(workspace:GetDescendants()) do
        -- Pula se não for uma parte
        if not v:IsA("BasePart") then continue end
        
        local name = v.Name:lower()
        local parent = v.Parent
        local parentName = parent and parent.Name:lower() or ""
        
        -- Verifica e remove os efeitos
        pcall(function()
            -- TableFlip ou Incinerate debris - remove apenas os que não estão no chão
            for _, debrisName in pairs(debrisNames) do
                if name:find(debrisName) then
                    for _, moveName in pairs(moveNames) do
                        if parentName:find(moveName) and v.Position.Y > 1 then
                            v:Destroy()
                            return
                        end
                    end
                end
            end
            
            -- OmniDirectionalPunch linhas brancas
            for _, lineName in pairs(lineNames) do
                if name:find(lineName) and parentName:find("omni") then
                    v:Destroy()
                    return
                end
            end
            
            -- Garou efeitos de água
            for _, waterName in pairs(waterNames) do
                if name:find(waterName) and (parentName:find("garou") or parentName:find("water")) then
                    v:Destroy()
                    return
                end
            end
        end)
    end
end

-- Conexão mais leve (usando stepped em vez de heartbeat)
game:GetService("RunService").Stepped:Connect(removeLag)

print("✓ Script anti-lag carregado - Versão ultra-leve para JJSploit")
