-- Script ULTRA-LEVE para JJSploit - otimizado para minimizar queda de FPS
-- Remove efeitos sem impactar o desempenho

local maxPerFrame = 10 -- Número máximo de objetos processados por frame
local updateDelay = 0,5 -- Intervalo entre verificações (segundos)

-- Lista de nomes exatos para procurar (muito específica para reduzir verificações)
local exactMatches = {
    "Debris", "debris", "Rubble", "rubble", "Chunk", "chunk",   -- TableFlip/Incinerate
    "WhiteLine", "whiteline", "Line", "line", "Beam", "beam",   -- Omni Punch
    "WaterEffect", "watereffect", "Flow", "flow", "AfterImage"  -- Garou
}

-- Função que processa apenas alguns objetos por vez
local index = 1
local function processNextBatch()
    local count = 0
    local children = workspace:GetChildren()
    local size = #children
    
    -- Processa apenas alguns objetos por vez, continuando de onde parou
    while count < maxPerFrame and count < size do
        if index > size then index = 1 end
        local obj = children[index]
        
        pcall(function()
            -- Verifica somente pelo nome do objeto (verificação ultra-simplificada)
            local name = obj.Name
            for _, match in pairs(exactMatches) do
                if name == match then
                    if obj:IsA("BasePart") then
                        -- Para debris, verifica se está no ar (simplificado)
                        if name:find("ebris") or name:find("ubble") or name:find("hunk") then
                            if obj.Position.Y > 1 then
                                obj:Destroy()
                            end
                        else
                            -- Para outros efeitos, remove diretamente
                            obj:Destroy()
                        end
                    end
                    break
                end
            end
        end)
        
        index = index + 1
        count = count + 1
    end
end

-- Inicia o ciclo de processamento com delay entre execuções
spawn(function()
    while wait(updateDelay) do
        pcall(processNextBatch)
    end
end)

print("✓ Script anti-lag ULTRA-LEVE iniciado")
