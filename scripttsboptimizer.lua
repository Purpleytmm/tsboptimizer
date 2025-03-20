--=# Configurações do Usuário #=--
getgenv().Settings = {}
getgenv().Settings.Limb = {}
getgenv().Settings.Limb.Arms = true
getgenv().Settings.Limb.Legs = true
-- Shiftlock setting completely removed

--=# Configurações do Lag Reducer #=--
local PARTS_PER_TICK = 40
local SCAN_INTERVAL = 1
local KEY_COMBO = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}

--=# Cache de Serviços #=--
local RunService = game:GetService("RunService")
local InputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local workspaceRef = workspace
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
if not getgenv().executed then

    local function respawn(plr)
        if not plr or not plr.Character then return end
        local char = plr.Character
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then 
            humanoid:ChangeState(15) 
        end
        char:ClearAllChildren()
        local newChar = Instance.new("Model")
        newChar.Parent = workspaceRef
        plr.Character = newChar
        task.wait()
        plr.Character = char
        newChar:Destroy()
    end

    local function refresh(plr)
        if not plr or not plr.Character then return end
        local Human = plr.Character:FindFirstChildOfClass("Humanoid", true)
        local pos = (Human and Human.RootPart) and Human.RootPart.CFrame or nil
        local camPos = workspaceRef.CurrentCamera.CFrame
        respawn(plr)
        task.spawn(function()
            -- Ensure the wait returns a value before setting the camera CFrame
            task.wait(0.1)
            workspaceRef.CurrentCamera.CFrame = camPos
        end)
    end

    -- Hook for __namecall metamethod
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        if self.Name == "Communicate" and method == "FireServer" then
            if type(args[1]) == "table" and args[1].Goal == "Reset" then
                task.spawn(function()
                    respawn(LocalPlayer)
                end)
            end
        end
        return oldNamecall(self, ...)
    end)

    -- Hook for __newindex metamethod
    local oldNewIndex
    oldNewIndex = hookmetamethod(game, "__newindex", function(self, k, v)
        local char = self:FindFirstAncestorWhichIsA("Model")
        local player = (char and Players:GetPlayerFromCharacter(char)) or nil
        if k == "Parent" and (v == workspaceRef.Thrown or self:IsA("ParticleEmitter")) then
            self:Destroy()
            return nil
        else
            -- Uncomment for debugging:
            -- print(self, k, v)
        end
        return oldNewIndex(self, k, v)
    end)

    if workspaceRef:FindFirstChild("Thrown") then
        workspaceRef.Thrown.ChildAdded:Connect(function(instance)
            task.wait()
            if instance then
                instance:Destroy()
            end
        end)
    end

    local function Process()
        if not LocalPlayer.Character then return end
        local hrp = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
        hrp.ChildAdded:Connect(function(child)
            local Dodge = false
            if child.Name == "dodgevelocity" then
                task.spawn(function()
                    Dodge = true
                    local glow = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScreenGui"):WaitForChild("MagicHealth"):WaitForChild("Health"):WaitForChild("Glow")
                    for i = 1.975, 0, -1 do
                        if not Dodge then break end
                        glow.ImageColor3 = Color3.fromRGB(255, 255, 255)
                        task.wait(1)
                        glow.ImageColor3 = Color3.fromRGB(0, 0, 0)
                    end
                    Dodge = false
                end)
            elseif (child.Name == "moveme" or child.Name == "Sound") and Dodge then
                task.spawn(function()
                    Dodge = false
                    local textLabel = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScreenGui"):WaitForChild("MagicHealth"):WaitForChild("TextLabel")
                    for i = 3.975, 0, -1 do
                        textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                        task.wait(1)
                        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    end
                end)
            end
        end)
    end

    Process()
    LocalPlayer.CharacterAdded:Connect(Process)

    local UIS = InputService
    local Cam = workspaceRef.CurrentCamera

    RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if char:FindFirstChild("Left Arm") and char:FindFirstChild("Right Arm") then
            if not getgenv().Settings.Limb.Arms then
                local leftArm = char:FindFirstChild("Left Arm")
                local rightArm = char:FindFirstChild("Right Arm")
                if leftArm then leftArm:Destroy() end
                if rightArm then rightArm:Destroy() end
            end
            if not getgenv().Settings.Limb.Legs then
                local leftLeg = char:FindFirstChild("Left Leg")
                local rightLeg = char:FindFirstChild("Right Leg")
                if leftLeg then leftLeg:Destroy() end
                if rightLeg then rightLeg:Destroy() end
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
workspaceRef.DescendantAdded:Connect(function(obj)
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
            if registry and not registry.firstLineProtected then
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
    if lowerName:find("omni") and lowerName:find("punch") then
        return false
    end

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
    local startTime = os.clock()
    local limit = PARTS_PER_TICK
    
    while pointer <= #queue and limit > 0 do
        local obj = queue[pointer]
        if obj and obj.Parent then
            pcall(function() 
                obj:Destroy() 
            end)
        end
        pointer = pointer + 1
        limit = limit - 1
        
        if os.clock() - startTime > 0.008 then
            break
        end
    end
    
    if pointer > #queue then
        table.clear(queue)
        pointer = 1
    end
end

local function chunkedClean()
    local descendants = workspaceRef:GetDescendants()
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
        if camera.CameraType == Enum.CameraType.Custom then
            camera.CameraType = Enum.CameraType.Scriptable
        else
            camera.CameraType = Enum.CameraType.Custom
        end
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
