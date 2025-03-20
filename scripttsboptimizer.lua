-- Configurações ULTRA-OTIMIZADAS
local PARTS_PER_TICK = 38
local SCAN_INTERVAL = 2
local KEY_COMBO = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}

-- Lista de EXCLUSÃO ESPECÍFICA (Efeitos para REMOVER)
local BAN_LIST = {
    -- Efeitos do Omni Punch Cutscene (linhas brancas)
    ["trail"] = true, ["line_"] = true, ["slash_fx"] = true,
    ["beam_effect"] = true, ["cutscene_line"] = true, ["whiteline"] = true,
    
    -- Efeitos do Flowing Water (Hero Hunter)
    ["flowafterimage"] = true, ["waterclone"] = true, ["fadephantom"] = true,
    ["slowfade"] = true, ["ripple_effect"] = true, ["flowfx"] = true,
    ["ghosttrace"] = true, ["afterimage_fade"] = true
}

-- Sistema de rastreamento para primeira linha
local firstLineProtected = false

local function isProtected(obj)
    -- Proteção da PRIMEIRA LINHA do Omni Punch
    if obj.Name:lower():find("whiteline") then
        if not firstLineProtected then
            firstLineProtected = true
            return true
        end
        return false
    end

    -- Verificação de efeitos BANIDOS
    local lowerName = obj.Name:lower()
    for bannedPattern in pairs(BAN_LIST) do
        if lowerName:find(bannedPattern) then
            return false  -- Permite destruição
        end
    end

    -- Proteção padrão (personagens + outros efeitos)
    local model = obj:FindFirstAncestorOfClass("Model")
    return (model and model:FindFirstChild("Humanoid")) 
        or lowerName:find("punch")
        or lowerName:find("hitfx")
end

-- Sistema de limpeza OTIMIZADO (mesmo código anterior)
-- ... (mantenha o restante do código igual da versão anterior)

-- Reset da proteção da linha quando a cutscene terminar
game:GetService("Workspace").ChildRemoved:Connect(function(child)
    if child.Name:find("PunchCutscene") then
        firstLineProtected = false
    end
end)
