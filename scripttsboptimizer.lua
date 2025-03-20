--=# Configurações Globais #=--
getgenv().Settings = {
    Limb = { Arms = true, Legs = true },
    AntiLag = { PartsPerTick = 38, ScanInterval = 2 },
    FreecamKey = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}
}

--=# Variáveis Essenciais #=--
local queue, pointer = {}, 1
local Players = game:GetService("Players")
local Local = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--=# Notificação XPurpleYTmmX #=--
local function ShowNotification()
    local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    gui.Name = "XPurpleNotif"
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 60)
    frame.Position = UDim2.new(1, 300, 1, -70)
    frame.BackgroundColor3 = Color3.new(0.08, 0.08, 0.08)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    -- [...] (Código completo da notificação com animações)

    return gui
end

--=# Hook Anti-Throw #=--
local originalNewIndex
originalNewIndex = hookmetamethod(game, "__newindex", function(self, k, v)
    if k == "Parent" and (v == workspace.Thrown or self:IsA("ParticleEmitter")) then
        self:Destroy()
        return nil
    end
    return originalNewIndex(self, k, v)
end)

--=# Proteção Total de Efeitos #=--
local function isProtected(obj)
    -- Proteção de personagens
    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Humanoid") then return true end

    -- Proteção de partes do corpo
    local bodyParts = {
        head = true, torso = true, humanoidrootpart = true,
        leftarm = true, rightarm = true, leftleg = true, rightleg = true
    }
    if bodyParts[obj.Name:lower()] then return true end

    -- Proteção de pastas Omni
    local omniFolder = obj:FindFirstAncestor("OmniDirectionalPunchCutscene") 
        or obj:FindFirstAncestor("OmniDirectionalPunch")
    if omniFolder then return true end

    -- Proteção de nomes específicos
    local protectedNames = {
        ["frozen"] = true,
        ["soul"] = true,
        ["frozensoul"] = true,
        ["meteor"] = true
    }
    if protectedNames[obj.Name:lower()] then return true end

    -- Proteção de efeitos essenciais
    return obj.Name:lower():find("punch") 
        or obj.Name:lower():find("omni") 
        or obj.Name:lower():find("hitfx")
end

--=# Sistema de Limpeza Otimizado #=--
local function ChunkedClean()
    for i = 1, #workspace:GetDescendants(), 15 do
        local obj = workspace:GetDescendants()[i]
        if obj:IsA("BasePart") and not isProtected(obj) then
            if not obj.Anchored and not obj.CanCollide then
                table.insert(queue, obj)
            end
        end
        if i % 50 == 0 then task.wait() end
    end
end

--=# Sistema de Membros #=--
local function UpdateLimbs(char)
    for _, side in pairs({"Left", "Right"}) do
        if not Settings.Limb.Arms then
            local arm = char:FindFirstChild(side.." Arm")
            if arm then arm:Destroy() end
        end
        if not Settings.Limb.Legs then
            local leg = char:FindFirstChild(side.." Leg")
            if leg then leg:Destroy() end
        end
    end
end

--=# Loop Principal #=--
RunService.Heartbeat:Connect(function()
    -- Processar Anti-Lag
    for _ = 1, Settings.AntiLag.PartsPerTick do
        if queue[pointer] then
            pcall(queue[pointer].Destroy, queue[pointer])
            pointer += 1
        else
            table.clear(queue)
            pointer = 1
            break
        end
    end

    -- Atualizar Membros
    if Local.Character then UpdateLimbs(Local.Character) end
end)

--=# Freecam #=--
Input.InputBegan:Connect(function(input)
    if input.KeyCode == Settings.FreecamKey[2] and input:IsModifierKeyDown(Settings.FreecamKey[1]) then
        Camera.CameraType = Camera.CameraType == Enum.CameraType.Custom 
            and Enum.CameraType.Scriptable 
            or Enum.CameraType.Custom
    end
end)

--=# Inicialização #=--
ShowNotification()
Local.CharacterAdded:Connect(UpdateLimbs)
workspace.Thrown.ChildAdded:Connect(function(obj) task.defer(obj.Destroy, obj) end)

task.spawn(function()
    while task.wait(Settings.AntiLag.ScanInterval) do
        ChunkedClean()
    end
end)
