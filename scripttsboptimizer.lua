--=# Configurações Globais #=--
getgenv().Settings = {
    Limb = {
        Arms = true,
        Legs = true
    },
    AntiLag = {
        PartsPerTick = 38,
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
local UserInputService = game:GetService("UserInputService")
local Workspace = workspace

--=# Função de Proteção Integrada #=--
local bodyParts = {
    head = true, torso = true, humanoidrootpart = true,
    leftarm = true, rightarm = true, leftleg = true, rightleg = true
}

local function isProtected(obj)
    local lowerName = obj.Name:lower()
    -- Protege nomes específicos
    if lowerName == "frozen" or lowerName == "soul" or lowerName == "meteor" then
        return true
    end

    -- Verificação de personagem
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Humanoid") then
        return true
    end

    -- Proteção de partes do corpo
    if bodyParts[lowerName] then
        return true
    end

    -- Controle de linhas brancas
    if lowerName == "whiteline" then
        local cutsceneModel = obj:FindFirstAncestorWhichIsA("Model")
        if cutsceneModel then
            if not cutsceneRegistry[cutsceneModel] then
                cutsceneRegistry[cutsceneModel] = true
                return true
            end
            return false
        end
    end

    -- Filtro de efeitos: evita remoção para objetos com nomes contendo "afterimage" ou "flowingwater"
    return not (lowerName:find("afterimage") or lowerName:find("flowingwater"))
end

--=# Sistema de Limpeza #=--
local cleanupQueue = {}
local queuePointer = 1

local function CleanWorld()
    local descendants = Workspace:GetDescendants()
    for i = 1, #descendants, 15 do
        local obj = descendants[i]
        -- Verifica se é BasePart, se não está protegido,
        -- e se possui hitbox ou está ancorado. Só remove se NÃO tiver hitbox e NÃO estiver ancorado.
        if obj:IsA("BasePart") and 
           not isProtected(obj) and 
           (not obj.Anchored) and 
           (not obj:FindFirstChildWhichIsA("Hitbox")) then
            table.insert(cleanupQueue, obj)
        end
        if i % 75 == 0 then task.wait() end
    end
end

--=# Sistema de Personagem #=--
local function UpdateLimbs(char)
    pcall(function()
        if not Settings.Limb.Arms then
            if char:FindFirstChild("Left Arm") then
                char["Left Arm"]:Destroy()
            end
            if char:FindFirstChild("Right Arm") then
                char["Right Arm"]:Destroy()
            end
        end
        if not Settings.Limb.Legs then
            if char:FindFirstChild("Left Leg") then
                char["Left Leg"]:Destroy()
            end
            if char:FindFirstChild("Right Leg") then
                char["Right Leg"]:Destroy()
            end
        end
    end)
end

local function SetupCharacter(char)
    char:WaitForChild("HumanoidRootPart")
    UpdateLimbs(char)
    
    -- Sistema de Dodge
    char.HumanoidRootPart.ChildAdded:Connect(function(child)
        if child.Name == "dodgevelocity" then
            local Glow = Local:WaitForChild("PlayerGui"):WaitForChild("ScreenGui"):WaitForChild("MagicHealth"):WaitForChild("Health"):WaitForChild("Glow")
            Glow.ImageColor3 = Color3.new(1,1,1)
            task.delay(1.975, function()
                Glow.ImageColor3 = Color3.new(0,0,0)
            end)
        end
    end)
end

--=# Hooks e Conexões #=--
-- Modificado para checar hitbox e estado ancorado antes de destruir
Workspace.Thrown.ChildAdded:Connect(function(obj)
    task.wait()
    if obj:IsA("BasePart") and 
       (not obj.Anchored) and 
       (not obj:FindFirstChildWhichIsA("Hitbox")) and 
       (not isProtected(obj)) then
        obj:Destroy()
    end
end)

-- Mantemos o hookmetamethod para casos específicos, pois atua sobre novos índices que setam pais indesejados.
local old = nil
old = hookmetamethod(game, "__newindex", function(self, k, v)
    if k == "Parent" then
        if v == Workspace.Thrown or self:IsA("ParticleEmitter") then
            self:Destroy()
            return nil
        end
    end
    return old(self, k, v)
end)

--=# Loop Principal #=--
RunService.Heartbeat:Connect(function()
    -- Limpeza de efeitos: remoção gradual por partes
    for _ = 1, Settings.AntiLag.PartsPerTick do
        if cleanupQueue[queuePointer] then
            pcall(cleanupQueue[queuePointer].Destroy, cleanupQueue[queuePointer])
            queuePointer = queuePointer + 1
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
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Settings.FreecamKey[2] and input:IsModifierKeyDown(Settings.FreecamKey[1]) then
        local currentCamera = Workspace.CurrentCamera
        currentCamera.CameraType = 
            currentCamera.CameraType == Enum.CameraType.Custom 
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
