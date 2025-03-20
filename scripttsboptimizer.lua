getgenv().Settings = {
    Limb = { Arms = true, Legs = true },
    AntiLag = { PartsPerTick = 38, ScanInterval = 2 },
    FreecamKey = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}
}

local queue = {}
local pointer = 1
local camera = workspace.CurrentCamera
local input = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Local = Players.LocalPlayer

local function isProtected(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Humanoid") then return true end
    
    local bodyParts = {
        head = true, torso = true, humanoidrootpart = true,
        leftarm = true, rightarm = true, leftleg = true, rightleg = true
    }
    if bodyParts[obj.Name:lower()] then return true end

    local name = obj.Name:lower()
    return name:find("punch") or name:find("omni") or name:find("hit") or name:find("fx") or name:find("gfx")
end

local function UpdateLimbs(char)
    pcall(function()
        if not Settings.Limb.Arms then
            if char:FindFirstChild("Left Arm") then char["Left Arm"]:Destroy() end
            if char:FindFirstChild("Right Arm") then char["Right Arm"]:Destroy() end
        end
        if not Settings.Limb.Legs then
            if char:FindFirstChild("Left Leg") then char["Left Leg"]:Destroy() end
            if char:FindFirstChild("Right Leg") then char["Right Leg"]:Destroy() end
        end
    end)
end

local function chunkedClean()
    local descendants = workspace:GetDescendants()
    for i = 1, #descendants, 10 do
        local obj = descendants[i]
        if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
            if not isProtected(obj) then table.insert(queue, obj) end
        end
        if i % 50 == 0 then wait() end
    end
end

game:GetService("RunService").Heartbeat:Connect(function()
    for _ = 1, Settings.AntiLag.PartsPerTick do
        if queue[pointer] then
            pcall(function() queue[pointer]:Destroy() end)
            pointer += 1
        else
            table.clear(queue)
            pointer = 1
            break
        end
    end
    if Local.Character then UpdateLimbs(Local.Character) end
end)

input.InputBegan:Connect(function(input)
    if input.KeyCode == Settings.FreecamKey[2] and input:IsModifierKeyDown(Settings.FreecamKey[1]) then
        camera.CameraType = camera.CameraType == Enum.CameraType.Custom and Enum.CameraType.Scriptable or Enum.CameraType.Custom
    end
end)

Local.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    UpdateLimbs(char)
end)

task.spawn(function()
    while task.wait(Settings.AntiLag.ScanInterval) do
        chunkedClean()
    end
end)
