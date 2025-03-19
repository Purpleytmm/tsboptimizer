local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local function isPlayerPart(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    return model and model:FindFirstChild("Humanoid")
end

local function isTreePart(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    while model do
        if model.Name:lower():find("tree") then
            return true
        end
        model = model:FindFirstAncestorOfClass("Model")
    end
    return false
end

local function isValidPlatform(obj)
    return obj.Anchored and obj.CanCollide
end

local function cleanDebris()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if isPlayerPart(obj) then
                continue
            elseif isTreePart(obj) then
                continue
            elseif not isValidPlatform(obj) then
                pcall(function()
                    obj:Destroy()
                end)
            end
        end
    end
end

while task.wait(1) do
    cleanDebris()
end
