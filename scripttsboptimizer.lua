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
    local gui = Instance.new("ScreenGui")
    gui.Name = "XPurpleNotif"
    gui.Parent = game:GetService("CoreGui")
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 60)
    frame.Position = UDim2.new(1, 300, 1, -70)
    frame.BackgroundColor3 = Color3.new(0.08, 0.08, 0.08)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    -- [...] (Adicione aqui os elementos de texto e animações)

    frame:TweenPosition(UDim2.new(1, -260, 1, -70), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5)
    task.delay(5, function()
        frame:TweenPosition(UDim2.new(1, 300, 1, -70), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5, true, function()
            gui:Destroy()
        end)
    end)
end

--=# Hook Anti-Throw Atualizado #=--
local originalNewIndex
originalNewIndex = hookmetamethod(game, "__newindex", function(self, k, v)
    if k == "Parent" and (v == workspace.Thrown or self:IsA("ParticleEmitter")) then
        self:Destroy()
        return nil
    end
    return originalNewIndex(self, k, v)
end)

--=# Proteção Total de Efeitos (Otimizada) #=--
local function isProtected(obj)
    if obj:GetAttribute("XPurple_Protected") then return true end

    local model = obj:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildWhichIsA("Humanoid") then
        obj:SetAttribute("XPurple_Protected", true)
        return true
    end

    local protectedNames = {
        ["frozen"] = true, ["soul"] = true,
        ["frozensoul"] = true, ["meteor"] = true
    }
    
    return protectedNames[obj.Name:lower()] 
        or string.match(obj.Name:lower(), "punch") 
        or string.match(obj.Name:lower(), "omni")
end

--=# Sistema de Limpeza Turbo #=--
local function ChunkedClean()
    local descendants = workspace:GetDescendants()
    for i = 1, #descendants, 15 do
        local obj = descendants[i]
        if obj:IsA("BasePart") and not isProtected(obj) then
            if not obj.Anchored and not obj.CanCollide then
                table.insert(queue, obj)
            end
        end
        if i % 50 == 0 then task.wait() end
    end
end

--=# Sistema de Membros Atualizado #=--
local function UpdateLimbs(char)
    for _, side in pairs({"Left", "Right"}) do
        local arm = char:FindFirstChild(side.."Arm") or char:FindFirstChild(side.." Arm")
        if arm and not Settings.Limb.Arms then arm:Destroy() end

        local leg = char:FindFirstChild(side.."Leg") or char:FindFirstChild(side.." Leg")
        if leg and not Settings.Limb.Legs then leg:Destroy() end
    end
end

--=# Loop Principal Otimizado #=--
RunService.Heartbeat:Connect(function()
    -- Processar Anti-Lag
    for _ = 1, math.min(Settings.AntiLag.PartsPerTick, #queue) do
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

--=# Inicialização #=--
ShowNotification()
Local.CharacterAdded:Connect(UpdateLimbs)
workspace.Thrown.ChildAdded:Connect(function(obj) task.defer(obj.Destroy, obj) end)

task.spawn(function()
    while task.wait(Settings.AntiLag.ScanInterval) do
        ChunkedClean()
        collectgarbage("step", 200) -- Otimização de memória
    end
end)
