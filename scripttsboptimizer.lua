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
    if k
