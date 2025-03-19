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
            -- Ignora partes que são dos jogadores
            if obj:IsDescendantOf(game.Players) then
                -- não faz nada se for parte de um jogador
            else
                local parentName = ""
                if obj.Parent and obj.Parent.Name then
                    parentName = obj.Parent.Name:lower()
                end

                -- Ignora partes que pertencem a árvores (supondo que "tree" conste no nome)
                if parentName:find("tree") then
                    -- não faz nada para partes de árvores
                else
                    -- Remove partes com pais indicando golpes específicos
                    if parentName:find("incinerar") or parentName:find("incinerate") or parentName:find("tableflip") then
                        pcall(function() obj:Destroy() end)
                    else
                        -- Se o objeto não tiver hitbox e não estiver no chão, remove-o
                        if not obj.CanCollide and not isOnGround(obj) then
                            pcall(function() obj:Destroy() end)
                        end
                    end
                end
            end

        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            local parentName = ""
            if obj.Parent and obj.Parent.Name then
                parentName = obj.Parent.Name:lower()
            end
            -- Remove partículas e trails relacionados aos efeitos indesejados
            if parentName:find("omni") or parentName:find("punch") or parentName:find("flowing") or parentName:find("water") then
                pcall(function() obj:Destroy() end)
            end

        elseif obj:IsA("Sound") then
            pcall(function() obj.Volume = 0 end)

        elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            pcall(function() obj.Brightness = obj.Brightness * 0.5 end)
        end
    end
end
