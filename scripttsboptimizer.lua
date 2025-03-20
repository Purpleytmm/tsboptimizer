--=# Configurações Globais #=--
getgenv().Settings = {
    Limb = {
        Arms = true,
        Legs = true
    },
    AntiLag = {
        Enabled = true,
        BannedEffects = {
            "flowingwater", "waterclone", "afterimage",
            "consecutive", "machinegun", "_trail"
        }
    }
}

--=# Sistema Anti-Lag #=--
local function CleanDebris()
    local queue = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored then
            local lowerName = obj.Name:lower()
            for _, pattern in ipairs(Settings.AntiLag.BannedEffects) do
                if lowerName:find(pattern) then
                    table.insert(queue, obj)
                    break
                end
            end
        end
    end
    for _, obj in ipairs(queue) do pcall(obj.Destroy, obj) end
end

--=# Sistema Principal #=--
if not getgenv().executed then
    local Players = game:GetService("Players")
    local Local = Players.LocalPlayer

    -- Função de Respawn Otimizada
    function respawn(plr)
        if plr.Character then
            plr.Character:BreakJoints()
            task.wait(0.5)
            plr.Character = nil
        end
    end

    -- Anti-Throw e Partículas
    hookmetamethod(game,"__newindex",function(self,k,v)
        if k == "Parent" and (v == workspace.Thrown or self:IsA("ParticleEmitter")) then
            self:Destroy()
            return nil
        end
        return old(self,k,v)
    end)

    workspace.Thrown.ChildAdded:Connect(function(obj)
        task.wait() obj:Destroy()
    end)

    -- Controle de Membros
    local function UpdateLimbs(char)
        if not Settings.Limb.Arms then
            pcall(function()
                char["Left Arm"]:Destroy()
                char["Right Arm"]:Destroy()
            end)
        end
        if not Settings.Limb.Legs then
            pcall(function()
                char["Left Leg"]:Destroy()
                char["Right Leg"]:Destroy()
            end)
        end
    end

    -- Sistema de Dodge
    local function SetupDodge(hrp)
        hrp.ChildAdded:Connect(function(child)
            if child.Name == "dodgevelocity" then
                local Glow = Local.PlayerGui.ScreenGui.MagicHealth.Health.Glow
                Glow.ImageColor3 = Color3.new(1,1,1)
                task.wait(1.975)
                Glow.ImageColor3 = Color3.new(0,0,0)
            end
        end)
    end

    -- Inicialização
    Local.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart")
        UpdateLimbs(char)
        SetupDodge(char.HumanoidRootPart)
    end)

    -- Loop Principal
    game:GetService("RunService").RenderStepped:Connect(function()
        if Local.Character then
            UpdateLimbs(Local.Character)
            if Settings.AntiLag.Enabled then
                CleanDebris()
            end
        end
    end)

    getgenv().executed = true
end
