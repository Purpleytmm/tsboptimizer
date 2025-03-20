--=# Configurações Globais #=--
getgenv().Settings = {
    Limb = {
        Arms = true,
        Legs = true
    },
    AntiLag = {
        PartsPerTick = 3,
        ScanInterval = 2
    },
    FreecamKey = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}
}

--=# Sistema de Registro de Cutscenes #=--
local cutsceneRegistry = {}

--=# Sistemas Compartilhados #=--
local Players = game:GetService("Players")
local Local = Players.LocalPlayer
local RunService = game:GetService("RunService")

--=# Função de Proteção Integrada #=--
local bodyParts = {
    head = true, torso = true, humanoidrootpart = true,
    leftarm = true, rightarm = true, leftleg = true, rightleg = true
}

local function isProtected(obj)
    -- Verificação de personagem
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Humanoid") then
        return true
    end

    -- Proteção de partes do corpo
    if bodyParts[obj.Name:lower()] then
        return true
    end

    -- Controle de linhas brancas
    if obj.Name:lower() == "whiteline" then
        local cutsceneModel = obj:FindFirstAncestorWhichIsA("Model")
        if cutsceneModel then
            if not cutsceneRegistry[cutsceneModel] then
                cutsceneRegistry[cutsceneModel] = true
                return true
            end
            return false
        end
    end

    -- Filtro de efeitos
    local lowerName = obj.Name:lower()
    return not (lowerName:find("afterimage") or lowerName:find("flowingwater"))
end

--=# Sistema de Limpeza #=--
local cleanupQueue = {}
local queuePointer = 1

local function CleanWorld()
    local descendants = workspace:GetDescendants()
    for i = 1, #descendants, 15 do
        local obj = descendants[i]
        if obj:IsA("BasePart") and not isProtected(obj) then
            table.insert(cleanupQueue, obj)
        end
        if i % 75 == 0 then task.wait() end
    end
end

--=# Sistema de Personagem #=--
local function UpdateLimbs(char)
    pcall(function()
        if not Settings.Limb.Arms then
            char["Left Arm"]:Destroy()
            char["Right Arm"]:Destroy()
        end
        if not Settings.Limb.Legs then
            char["Left Leg"]:Destroy()
            char["Right Leg"]:Destroy()
        end
    end)
end

local function SetupCharacter(char)
    char:WaitForChild("HumanoidRootPart")
    UpdateLimbs(char)
    
    -- Sistema de Dodge
    char.HumanoidRootPart.ChildAdded:Connect(function(child)
        if child.Name == "dodgevelocity" then
            local Glow = Local.PlayerGui.ScreenGui.MagicHealth.Health.Glow
            Glow.ImageColor3 = Color3.new(1,1,1)
            task.delay(1.975, function()
                Glow.ImageColor3 = Color3.new(0,0,0)
            end)
        end
    end)
end

--=# Hooks e Conexões #=--
workspace.Thrown.ChildAdded:Connect(function(obj)
    task.wait() obj:Destroy()
end)

hookmetamethod(game,"__newindex",function(self,k,v)
    if k == "Parent" and (v == workspace.Thrown or self:IsA("ParticleEmitter")) then
        self:Destroy()
        return nil
    end
    return old(self,k,v)
end)

--=# Loop Principal #=--
RunService.Heartbeat:Connect(function()
    -- Limpeza de efeitos
    for _ = 1, Settings.AntiLag.PartsPerTick do
        if cleanupQueue[queuePointer] then
            pcall(cleanupQueue[queuePointer].Destroy, cleanupQueue[queuePointer])
            queuePointer += 1
        else
            table.clear(cleanupQueue)
            queuePointer = 1
            break
        end
    end

    -- Atualização de membros
    if Local.Character then
        UpdateLimbs(Local.Character)
    end
end)

--=# Freecam #=--
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Settings.FreecamKey[2] and input:IsModifierKeyDown(Settings.FreecamKey[1]) then
        workspace.CurrentCamera.CameraType = 
            workspace.CurrentCamera.CameraType == Enum.CameraType.Custom 
            and Enum.CameraType.Scriptable 
            or Enum.CameraType.Custom
    end
end)

--=# Inicialização #=--
Local.CharacterAdded:Connect(SetupCharacter)
task.spawn(function()
    while task.wait(Settings.AntiLag.ScanInterval) do
        CleanWorld()
    end
end)

--=# Otimização Final #=--
collectgarbage("setpause", 150)
collectgarbage("setstepmul", 250)
