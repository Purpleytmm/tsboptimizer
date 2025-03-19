-- This script removes debris/blocks in STRNGEST BATTLEGROUNDS,
-- sparing only the parts that are on the ground (or nearly so)
-- and those that the player can step on (i.e. parts with collisions enabled 
-- that "sit" on something below them).
--
-- WARNING: Use this script responsibly. Exploit scripts may violate game
-- terms of service. Use at your own risk.

local workspace = game:GetService("Workspace")

-- Threshold distance (in studs) allowed between a part's bottom and the object it rests on.
local GROUND_GAP_THRESHOLD = 5 -- Increased from 3 to be more lenient

-- Ground Y-coordinate detection (automatic calibration)
local groundY = nil
local function detectGroundY()
    -- Try to find the ground level
    local minY = math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Size.X > 50 and obj.Size.Z > 50 and obj.CanCollide then
            if obj.Position.Y < minY then
                minY = obj.Position.Y
                groundY = obj.Position.Y + (obj.Size.Y/2)
            end
        end
    end
    
    -- Fallback if we couldn't detect ground
    if not groundY then groundY = 0 end
    print("Ground Y level detected at approximately: " .. groundY)
end

-- Check if a part is near ground level or stacked on another part
local function isGrounded(part)
    -- If part is very close to ground level, consider it grounded
    if math.abs(part.Position.Y - (part.Size.Y/2) - groundY) < 1 then
        return true
    end

    -- Use a more reliable raycast approach
    local success, result = pcall(function()
        -- The old raycast method as fallback in case RaycastParams isn't supported
        local origin = part.Position - Vector3.new(0, part.Size.Y/2 + 0.1, 0)
        local direction = Vector3.new(0, -10, 0)
        
        -- Try modern raycast first
        if typeof(RaycastParams) == "userdata" then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {part}
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            
            local rayResult = workspace:Raycast(origin, direction, rayParams)
            if rayResult then
                return (origin - rayResult.Position).Magnitude <= GROUND_GAP_THRESHOLD
            end
        else
            -- Fallback to legacy FindPartOnRay
            local ignore = {part}
            local hit, pos = workspace:FindPartOnRayWithIgnoreList(Ray.new(origin, direction), ignore)
            if hit then
                return (origin - pos).Magnitude <= GROUND_GAP_THRESHOLD
            end
        end
        return false
    end)
    
    -- If the raycast failed for any reason, be cautious and keep the part
    if not success then
        return true
    end
    
    return result
end

-- Process parts in batches to prevent script timeout
local function cleanDebris()
    detectGroundY()
    
    local toRemove = {}
    local partCount = 0
    local processedCount = 0
    
    -- Collect parts for processing
    print("Analyzing parts...")
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            partCount = partCount + 1
            
            -- Always keep parts with special properties
            if obj.Name:lower():find("ground") or
               obj.Name:lower():find("floor") or
               obj.Name:lower():find("platform") or
               obj.Transparency >= 0.9 then -- Nearly invisible parts are likely important
                continue
            end
            
            -- Apply criteria for removal
            if not obj.CanCollide or not isGrounded(obj) then
                table.insert(toRemove, obj)
            end
        end
    end
    
    -- Remove parts in batches
    print("Found " .. #toRemove .. " parts to remove out of " .. partCount .. " total parts.")
    for i, obj in ipairs(toRemove) do
        pcall(function()
            obj:Destroy()
        end)
        
        processedCount = processedCount + 1
        if i % 100 == 0 then
            print("Removed " .. i .. " parts...")
            task.wait(0.1) -- Brief pause every 100 parts to prevent timeout
        end
    end
    
    print("Debris cleanup completed. Removed " .. processedCount .. " parts.")
end

-- Run with a safety wrapper
local success, err = pcall(function()
    task.wait(2) -- Wait a bit longer to ensure game is fully loaded
    cleanDebris()
end)

if not success then
    warn("Script encountered an error: " .. tostring(err))
end
