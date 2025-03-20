--=# Configurações do Usuário #=--
getgenv().Settings = {}
Settings.Limb = {}
Settings.Limb.Arms = true
Settings.Limb.Legs = true
-- Shiftlock setting completely removed

--=# Configurações do Lag Reducer #=--
local PARTS_PER_TICK = 40
local SCAN_INTERVAL = 0.75
local KEY_COMBO = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}

--=# Cache de Serviços #=--
local RunService = game:GetService("RunService")
local InputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Local = Players.LocalPlayer
local workspace = workspace
local camera = workspace.CurrentCamera

--=# Registros e Tabelas de Referência #=--
local cutsceneRegistry = {}
local omniPunchFirstLineFlag = false
local bodyParts = {
    head = true, torso = true, humanoidrootpart = true,
    leftarm = true, rightarm = true, leftleg = true, rightleg = true
}
local allowedEmotes = {
    car = true, plane = true, scooter = true
}
local effectsToRemove = {
    afterimage = true, 
    flowingwater = true, 
    _trail = true,
    consecutive = true,
    machinegun = true,
    ["machine gun"] = true
}

--=# Sistema de Limpeza #=--
local queue = {}
local pointer = 1

--=# Sistema de Respawn/Refresh #=--
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
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
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
        
        -- Shiftlock code completely removed
    end)
end

--=# Funções do Lag Reducer #=--
local function registerCutscene(cutsceneModel)
    if cutsceneModel and not cutsceneRegistry[cutsceneModel] then
        cutsceneRegistry[cutsceneModel] = {
            firstLineProtected = false,
            connection = cutsceneModel.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    cutsceneRegistry[cutsceneModel] = nil
                end
            end)
        }
    end
end

-- Rastreamento global para linhas brancas do Omni Punch
local whiteLinesAllowed = true
workspace.DescendantAdded:Connect(function(obj)
    if obj.Name:lower() == "whiteline" then
        local model = obj:FindFirstAncestorOfClass("Model")
        if model and model.Name:lower():find("omni") then
            if not whiteLinesAllowed then
                task.defer(function()
                    if obj and obj.Parent then
                        obj:Destroy()
                    end
                end)
            end
            whiteLinesAllowed = false
            
            -- Reset após 5 segundos
            task.delay(5, function()
                whiteLinesAllowed = true
            end)
        end
    end
end)

local function isProtected(obj, lowerName, model)
    -- Verifica se o objeto pertence a um personagem
    if model and model:FindFirstChild("Humanoid") then
        return true
    end

    -- Proteção para partes do corpo
    if bodyParts[lowerName] then
        return true
    end

    -- Proteção para emotes
    for keyword in next, allowedEmotes do
        if lowerName:find(keyword) then
            return true
        end
    end
    
    -- Proteção específica para Foul Ball (Metal Bat/Brutal Demon)
    local modelName = model and model.Name:lower() or ""
    if lowerName:find("ball") or lowerName:find("foul") or
       modelName:find("ball") or modelName:find("foul") or
       lowerName:find("metal bat") or lowerName:find("brutal demon") or
       modelName:find("metal bat") or modelName:find("brutal demon") then
        return true
    end

    -- Tratamento de linhas brancas (whiteline)
    if lowerName == "whiteline" then
        -- Caso seja um Omni Punch, trata com regra especial global
        if model and model.Name:lower():find("omni") then
            if not omniPunchFirstLineFlag then
                omniPunchFirstLineFlag = true
                
                task.delay(5, function() 
                    omniPunchFirstLineFlag = false
                end)
                
                return true -- Apenas a primeira linha é protegida
            end
            return false -- Todas as demais são removidas
        end
        
        -- Para outras cutscenes não-Omni
        if model then
            registerCutscene(model)
            local registry = cutsceneRegistry[model]
            
            if not registry.firstLineProtected then
                registry.firstLineProtected = true
                return true
            else
                return false
            end
        end
    end

    -- Proteção especial para Meteor e Frozen Soul
    if lowerName:find("meteor") then return true end
    if lowerName:find("frozen") and lowerName:find("soul") then return true end

    -- Remover efeitos de golpes consecutivos e machine gun blows
    if lowerName:find("consecutive") or lowerName:find("machine gun") or lowerName:find("machinegun") then
        return false
    end

    -- Remover partes do Omni Directional Punch
    if lowerName:find("omni") and lowerName:find("punch") then return false end

    -- Verificação de debris
    if lowerName:find("debris") then
        -- Proteção para debris do Foul Ball
        if modelName:find("metal") or modelName:find("brutal") or
           modelName:find("foul") or modelName:find("ball") then
            return true
        end
        
        -- Se o modelo for relacionado a Omni, protege
        if model and model.Name:lower():find("omni") then return true end
        
        return false -- Remove outros debris
    end

    -- Remover efeitos indesejados
    for effect in next, effectsToRemove do
        if lowerName:find(effect) then return false end
    end

    -- Remover efeitos de multi-golpes
    if lowerName:find("punch") then
        if lowerName:find("multi") or lowerName:find("rapid") or lowerName:find("barrage") then
            return false
        end
        
        if lowerName:find("hitfx") then
            return true
        end
    end

    -- Padrão: proteger
    return true
end

local function processQueue()
    local start = os.clock()
    local limit = PARTS_PER_TICK
    
    while pointer <= #queue and limit > 0 do
        local obj = queue[pointer]
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
        pointer = pointer + 1
        limit = limit - 1
        
        if os.clock() - start > 0.008 then
            break
        end
    end
    
    if pointer > #queue then
        table.clear(queue)
        pointer = 1
    end
end

local function chunkedClean()
    local descendants = workspace:GetDescendants()
    local processingIndex = 1
    local processingLimit = 150
    
    local function processChunk()
        local endIndex = math.min(processingIndex + processingLimit, #descendants)
        
        for i = processingIndex, endIndex do
            local obj = descendants[i]
            if obj:IsA("BasePart") and not obj.Anchored and not obj.CanCollide then
                local lowerName = obj.Name:lower()
                local model = obj:FindFirstAncestorOfClass("Model")
                
                if not isProtected(obj, lowerName, model) then
                    queue[#queue + 1] = obj
                end
            end
        end
        
        processingIndex = endIndex + 1
        return processingIndex <= #descendants
    end
    
    while processChunk() do
        RunService.Heartbeat:Wait()
    end
end

--=# Conexão do Freecam #=--
InputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == KEY_COMBO[2] and input:IsModifierKeyDown(KEY_COMBO[1]) then
        camera.CameraType = (camera.CameraType == Enum.CameraType.Custom)
            and Enum.CameraType.Scriptable
            or Enum.CameraType.Custom
    end
end)

--=# Inicialização dos Sistemas #=--
RunService.Heartbeat:Connect(processQueue)

task.spawn(function()
    while true do
        chunkedClean()
        task.wait(SCAN_INTERVAL)
    end
end)

--=# Otimização da Memória #=--
collectgarbage("setpause", 110)
collectgarbage("setstepmul", 200)

getgenv().executed = true
