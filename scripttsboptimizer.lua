-- Configurações
local FREE_CAM_KEY = Enum.KeyCode.P -- Freecam: Shift + P

--[[ 
    PROTEÇÃO TOTAL (Players/Árvores/Dummies)
--]]
local function isProtected(obj)
    -- Verifica se é parte de um Player
    local player = game.Players:GetPlayerFromCharacter(obj.Parent)
    if player then return true end

    -- Verifica Dummies/NPCs e Árvores
    local model = obj:FindFirstAncestorOfClass("Model")
    if model then
        return model:FindFirstChild("Humanoid") or 
               model.Name:lower():find("tree") or 
               model.Name:lower():find("dummy") -- Proteção para dummies
    end

    return false
end

--[[ 
    FREECAM (Shift + P) - 100% Funcional
--]]
local camera = workspace.CurrentCamera
local freecamActive = false
local freecamPos, freecamCF

local function toggleFreecam()
    freecamActive = not freecamActive
    if freecamActive then
        freecamPos = camera.CFrame.Position
        freecamCF = camera.CFrame
        camera.CameraType = Enum.CameraType.Scriptable
    else
        camera.CameraType = Enum.CameraType.Custom
        camera.CFrame = freecamCF
    end
end

game:GetService("UserInputService").InputBegan:Connect(function(input, _)
    if input.KeyCode == FREE_CAM_KEY and input:IsModifierKeyDown(Enum.ModifierKey.Shift) then
        toggleFreecam()
    end
end)

--[[ 
    SISTEMA DE DEBRIS (Remoção Imediata)
--]]
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide and not isProtected(obj) then
        if obj and obj.Destroy then
            obj:Destroy()
        end
    end
end)

--[[ 
    LIMPEZA INICIAL
--]]
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide and not isProtected(obj) then
        obj:Destroy()
    end
end
local Players = game:GetService("Players")
local Local = Players.LocalPlayer

--[[ 
    Sistema Antilag adicional
--]]

getgenv().Settings = {}
Settings.Limb = {}
Settings.Limb.Arms = true
Settings.Limb.Legs = true
Settings.Shiftlock = true

if not executed then
function respawn(plr)
	local char = plr.Character
	if char:FindFirstChildOfClass("Humanoid") then char:FindFirstChildOfClass("Humanoid"):ChangeState(15) end
	char:ClearAllChildren()
	local newChar = Instance.new("Model")
	newChar.Parent = workspace
	plr.Character = newChar
	task.wait()
	plr.Character = char
	newChar:Destroy()
end

function refresh(plr)
	local Human = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid", true)
	local pos = Human and Human.RootPart and Human.RootPart.CFrame
	local pos1 = workspace.CurrentCamera.CFrame
	respawn(plr)
	task.spawn(function()
		workspace.CurrentCamera.CFrame = wait() and pos1
	end)
end

local old; old = hookmetamethod(game,"__namecall",function(self,...)
local method, args = getnamecallmethod(), {...}
if self.Name == "Communicate" and method == "FireServer" and args[1]["Goal"] == "Reset" then
task.spawn(function()
respawn(Local)
end)
end
return old(self,...)
end)

local old; old = hookmetamethod(game,"__newindex",function(self,k,v)
	local char = self:FindFirstAncestorWhichIsA("Model")
	local player = Players:GetPlayerFromCharacter(char)
	if k == "Parent" and (v == workspace.Thrown or self:IsA("ParticleEmitter")) then
	self:Destroy()
	return nil
	else
--print(self,k,v)
		end
	return old(self,k,v)
	end)

workspace.Thrown.ChildAdded:Connect(function(instance)
task.wait()
instance:Destroy()
end)

function Process()
Local.Character:WaitForChild("HumanoidRootPart")
Local.Character.HumanoidRootPart.ChildAdded:Connect(function(child)
	local Dodge = false
	if (child.Name == "dodgevelocity") then
	task.spawn(function()
		Dodge = true
		local Glow = Local.PlayerGui.ScreenGui.MagicHealth.Health.Glow
		for i = 1.975, 0, -1 do
		if Dodge == false then break end
		Glow.ImageColor3 = Color3.fromRGB(255,255,255)
		--print(i)
		task.wait(1)
		Glow.ImageColor3 = Color3.fromRGB(0,0,0)
		end
		Dodge = false
		end)
	elseif (child.Name == "moveme" or child.Name == "Sound" and Dodge) then
	task.spawn(function()
		Dodge = false
		local Text = Local.PlayerGui.ScreenGui.MagicHealth.TextLabel
		for i = 3.975, 0, -1 do
		Text.TextColor3 = Color3.fromRGB(255,50,50)
		--warn(i)
		task.wait(1)
		Text.TextColor3 = Color3.fromRGB(255,255,255)
		end
		end)
	end
	end)
end

Process()

Local.CharacterAdded:Connect(Process)

local UIS = game:GetService("UserInputService")
local Cam = game.Workspace.CurrentCamera

game:GetService("RunService").RenderStepped:Connect(function()
	local char = Local.Character
	local hrp = char:WaitForChild("HumanoidRootPart")
	if char:FindFirstChild("Left Arm") and char:FindFirstChild("Right Arm") then
	if not Settings.Limb.Arms then
	char:FindFirstChild("Left Arm"):Destroy()
	char:FindFirstChild("Right Arm"):Destroy()
	end
	if not Settings.Limb.Legs then
	char:FindFirstChild("Left Leg"):Destroy()
	char:FindFirstChild("Right Leg"):Destroy()
	end
	end
	if not char:FindFirstChild("Ragdoll") and Settings.Shiftlock then
	local pos = hrp.Position + Vector3.new(Cam.CFrame.LookVector.X, 0, Cam.CFrame.LookVector.Z)
	hrp.CFrame = CFrame.new(hrp.Position, pos)
	end
end)
end

getgenv().executed = true
