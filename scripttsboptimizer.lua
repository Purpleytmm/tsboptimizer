local workspace = game:GetService("Workspace")

local GROUND_GAP_THRESHOLD = 5

local groundY = nil
local function detectGroundY()
    local minY = math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Size.X > 50 and obj.Size.Z > 50 and obj.CanCollide then
            if obj.Position.Y < minY then
                minY = obj.Position.Y
                groundY = obj.Position.Y + (obj.Size.Y/2)
            end
        end
    end
    
    if not groundY then groundY = 0 end
    print("Ground Y level detected at approximately: " .. groundY)
end

local function isGrounded(part)
    if math.abs(part.Position.Y - (part.Size.Y/2) - groundY) < 1 then
        return true
    end

    local success, result = pcall(function()
        local origin = part.Position - Vector3.new(0, part.Size.Y/2 + 0.1, 0)
        local direction = Vector3.new(0, -10, 0)
        
        if typeof(RaycastParams) == "userdata" then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {part}
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            
            local rayResult = workspace:Raycast(origin, direction, rayParams)
            if rayResult then
                return (origin - rayResult.Position).Magnitude <= GROUND_GAP_THRESHOLD
            end
        else
            local ignore = {part}
            local hit, pos = workspace:FindPartOnRayWithIgnoreList(Ray.new(origin, direction), ignore)
            if hit then
                return (origin - pos).Magnitude <= GROUND_GAP_THRESHOLD
            end
        end
        return false
    end)
    
    if not success then
        return true
    end
    
    return result
end

local function cleanDebris()
    detectGroundY()
    
    local toRemove = {}
    local partCount = 0
    local processedCount = 0
    
    print("Analyzing parts...")
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            partCount = partCount + 1
            
            if obj.Name:lower():find("ground") or
               obj.Name:lower():find("floor") or
               obj.Name:lower():find("platform") or
               obj.Transparency >= 0.9 then
                continue
            end
            
            if not obj.CanCollide or not isGrounded(obj) then
                table.insert(toRemove, obj)
            end
        end
    end
    
    print("Found " .. #toRemove .. " parts to remove out of " .. partCount .. " total parts.")
    for i, obj in ipairs(toRemove) do
        pcall(function()
            obj:Destroy()
        end)
        
        processedCount = processedCount + 1
        if i % 100 == 0 then
            print("Removed " .. i .. " parts...")
            task.wait(0.1)
        end
    end
    
    print("Debris cleanup completed. Removed " .. processedCount .. " parts.")
end

local success, err = pcall(function()
    task.wait(2)
    cleanDebris()
end)

if not success then
    warn("Script encountered an error: " .. tostring(err))
end
