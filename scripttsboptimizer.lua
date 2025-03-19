local debrisToRemove = {} -- Tabela para armazenar debris removidos

-- Função para verificar se o objeto está no chão
local function isOnGround(obj)
    local origin = obj.Position
    local direction = Vector3.new(0, -5, 0)
    local ray = Ray.new(origin, direction)
    local hit = workspace:FindPartOnRay(ray, obj)
    return hit ~= nil
end

while wait(0.5) do
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") then
            local parentName = ""
            if obj.Parent and obj.Parent.Name then
                parentName = obj.Parent.Name:lower()
            end

            -- Remove partes com pais indicando golpes específicos
            if parentName:find("incinerar") or parentName:find("incinerate") or parentName:find("tableflip") then
                pcall(function() obj:Destroy() end)
            else
                -- Se o objeto não tiver hitbox e não estiver no chão, remove-o
                if not obj.CanCollide and not isOnGround(obj) then
                    debrisToRemove[obj] = true
                    pcall(function() obj:Destroy() end)
                -- Se estiver no chão, garante que não seja removido futuramente
                elseif isOnGround(obj) then
                    debrisToRemove[obj] = nil
                end
            end

            -- Força material para Plastic, exceto se fizer parte de um jogador
            if not obj:IsDescendantOf(game.Players) then
                pcall(function() obj.Material = Enum.Material.Plastic end)
            end

            -- (Opcional) Desativa sombras para aliviar a carga da GPU
            pcall(function() obj.CastShadow = false end)

        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            local parentName = ""
            if obj.Parent and obj.Parent.Name then
                parentName = obj.Parent.Name:lower()
            end

            -- Remove efeitos de flashes brancos (Omni Directional Punch)
            if parentName:find("omni") or parentName:find("punch") then
                pcall(function() obj:Destroy() end)
            -- Remove efeitos azuis (Flowing Water do Garou)
            elseif parentName:find("flowing") or parentName:find("water") then
                pcall(function() obj:Destroy() end)
            end

        elseif obj:IsA("Sound") then
            -- (Opcional) Desativa sons desnecessários para reduzir carga
            pcall(function() obj.Volume = 0 end)

        elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            -- (Opcional) Diminui o brilho das luzes para otimizar a performance
            pcall(function() obj.Brightness = obj.Brightness * 0.5 end)
        end
    end
end

