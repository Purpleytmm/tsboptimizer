--[[
    This script is designed for use with jjsploit in The Strongest Battlegrounds.
    It continuously scans the game Workspace for specific unwanted effects:
      • Debris generated by the "Tableflip" and "Incinerate" moves (except those resting on the ground)
      • White line effects during the "OmniDirectionalPunch" move/cutscene
      • Flowing water graphics (after-images) from the base moveset of "Garou"
      
    The script assumes that effects are organized inside Models with names which include the move names.
    It uses a raycast check to determine if a debris part is "grounded" (i.e. resting on the ground). Only floating debris will be removed.
    
    Note: Names are processed in lowercase to allow case-insensitive matching.
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Helper function: Determine if a part is essentially on the ground.
-- It casts a downward ray from the part's position (ignoring the part itself)
-- and, if an obstacle is nearby, considers the part "grounded".
local function isGrounded(part)
    -- Define the downward direction and maximum distance to check.
    local downDirection = Vector3.new(0, -5, 0)
    local rayOrigin = part.Position
    -- Ignore the part itself during the raycast.
    local ignoreList = { part }
    
    -- Use the :FindPartOnRay method to get any hit.
    local hitPart, hitPosition = Workspace:FindPartOnRay(Ray.new(rayOrigin, downDirection), part)
    
    if hitPart and hitPosition then
        -- Calculate vertical distance from part to the hit position.
        local distance = part.Position.Y - hitPosition.Y
        -- If the distance is very small, we assume the part is on or very near the ground.
        return distance < 3
    end
    return false
end

-- Main loop: Continuously scan workspace and remove unwanted effects.
RunService.Heartbeat:Connect(function()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- Process only BasePart objects (parts with physical properties)
        if obj:IsA("BasePart") then
            local objName = obj.Name:lower()
            -- Attempt to find the closest Model ancestor for context (e.g., move name)
            local moveModel = obj:FindFirstAncestorWhichIsA("Model")
            local moveName = moveModel and moveModel.Name:lower() or ""
            
            -- Check for debris in Tableflip or Incinerate moves.
            if (moveName == "tableflip" or moveName == "incinerate") and objName:find("debris") then
                -- Only remove debris that are not grounded.
                if not isGrounded(obj) then
                    pcall(function()
                        obj:Destroy()
                    end)
                end

            -- Check for white line effects in the OmniDirectionalPunch move/cutscene.
            elseif moveName:find("omnidirectionalpunch") and objName:find("whiteline") then
                pcall(function()
                    obj:Destroy()
                end)

            -- Check for flowing water graphics in Garou's base moveset.
            elseif moveName:find("garou") and objName:find("flowingwater") then
                pcall(function()
                    obj:Destroy()
                end)
            end
        end
    end
end)
  
print("Custom effect removal script loaded.")
  
--[[ 
    DISCLAIMER:
    This script is intended for educational purposes and targeted specific unwanted visual effects as described.
    Use responsibly and ensure compliance with the game's terms of service and community guidelines.
]]
