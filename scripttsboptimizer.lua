local CLEAN_INTERVAL = 5 -- Segundos entre limpezas

local function isPlayerPart(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    return model and model:FindFirstChild("Humanoid")
end

local function isTree(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    return model and model.Name:lower():find("tree")
end

local function isFlowingWaterEffect(obj)
    return obj.Name:lower():find("afterimage") or obj.Name:lower():find("flowing")
end

local function cleanDebris()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            -- Remove after images do Flowing Water
            if isFlowingWaterEffect(obj) then
                pcall(obj.Destroy, obj)
            -- Remove debris comum (não remove jogadores/árvores)
            elseif not obj.Anchored and not obj.CanCollide and not isPlayerPart(obj) and not isTree(obj) then
                pcall(obj.Destroy, obj)
            end
        end
    end
end

while task.wait(CLEAN_INTERVAL) do
    cleanDebris()
end
