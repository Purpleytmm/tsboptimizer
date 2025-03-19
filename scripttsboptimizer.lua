local debrisService = game:GetService("Debris")
local workspace = game:GetService("Workspace")

local function removeDebris()
    for _, debris in pairs(workspace:GetChildren()) do
        if debris:IsA("Part") and not debris:IsPointInRegion3(workspace.CurrentCamera.CFrame.Position) then
            if not debris:FindFirstChild("Hitbox") and debris.Position.Y > 0 then
                debris:Destroy()
            end
        end
    end
end

local function onOmniDirectionalPunch()
    for _, debris in pairs(workspace:GetChildren()) do
        if debris:IsA("Part") and debris.Name == "OmniDirectionalPunchDebris" then
            debris:Destroy()
        end
    end
end

game:GetService("RunService").Stepped:Connect(removeDebris)
game:GetService("RunService").Stepped:Connect(onOmniDirectionalPunch)
