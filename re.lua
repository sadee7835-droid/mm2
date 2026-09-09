local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

-- ==========================================
-- CONFIGURATION
-- ==========================================
getgenv().autoexe = true
getgenv().AutoFarm = true
getgenv().Speed = 16 -- Movement speed strictly set to 16 studs/sec
getgenv().SafeStart = true

-- Time & Player Hop Settings
getgenv().AutoServerHop = true -- Hops if less than 4 players
getgenv().TimeHop = true
getgenv().HopMinutes = 22 -- Hops after 22 minutes
getgenv().AntiAdminHop = true

getgenv().AutoMurderer = true
getgenv().AutoSheriff = true
getgenv().AutoFlingSheriff = true
getgenv().FlingVelocity = 99999
getgenv().AutoGunDrop = true
getgenv().AutoDodge = true

getgenv().EnableESP = true
getgenv().HitboxExpander = true
getgenv().HitboxSize = 8
getgenv().KnifeAura = true

getgenv().CombatCoinTarget = 45
getgenv().DodgeDistance = 20

getgenv().WalkSpeed = 16
getgenv().Fly = false
getgenv().FlySpeed = 50

-- WEBHOOK CONFIGURATION
getgenv().EnableWebhook = true
getgenv().WebhookURL = "https://discord.com/api/webhooks/1542155042289745970/bpouACUktfIAw-GY_ecweKu-TIPQKBw3UsMEVbWjFcNja02xGkLLU0DlY5Hwog3RCqaC"

-- ==========================================
-- SESSION TRACKER
-- ==========================================
local scriptStartTime = os.time()
local sessionStats = {
    totalCoins = 0,
    startTime = os.time(),
}

-- ==========================================
-- WEBHOOK HANDLER
-- ==========================================
local function sendWebhook(title, description, color)
    if not getgenv().EnableWebhook or getgenv().WebhookURL == "" then return end
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    if not requestFunc then return end

    local elapsedTime = math.max(1, os.time() - sessionStats.startTime)
    local cpm = math.floor((sessionStats.totalCoins / elapsedTime) * 60)

    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or 5814783,
            ["fields"] = {
                { ["name"] = "Total Farmed", ["value"] = tostring(sessionStats.totalCoins) .. " 🪙", ["inline"] = true },
                { ["name"] = "Est. CPM", ["value"] = tostring(cpm) .. " / min", ["inline"] = true }
            },
            ["footer"] = { ["text"] = "MM2 CFrame Farm • " .. lp.Name }
        }}
    }

    task.spawn(function()
        pcall(function()
            requestFunc({
                Url = getgenv().WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end)
    end)
end

sendWebhook("CFrame Farm Active ⚡", "Script started with autoexe=true. 22-Min Auto Hop is ENABLED.", 65280)

-- ==========================================
-- ANTI-AFK & NOCLIP ENGINE
-- ==========================================
local vu = game:GetService("VirtualUser")
lp.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(0.1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

RunService.Stepped:Connect(function()
    if (getgenv().AutoFarm or getgenv().Fly) and lp.Character then
        for _, part in ipairs(lp.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    if lp.Character and lp.Character:FindFirstChild("Humanoid") and getgenv().WalkSpeed ~= 16 then
        lp.Character.Humanoid.WalkSpeed = getgenv().WalkSpeed
    end
end)

-- ==========================================
-- SERVER HOPPER
-- ==========================================
local function serverHop()
    local placeId = game.PlaceId
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Desc&limit=100"
    
    local success, result = pcall(function()
        if requestFunc then
            local response = requestFunc({Url = url, Method = "GET"})
            return HttpService:JSONEncode(response.Body)
        else
            return HttpService:JSONDecode(game:HttpGet(url))
        end
    end)
    
    if success and result and result.data then
        for _, server in ipairs(result.data) do
            if type(server) == "table" and server.playing and server.playing > 5 and server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(placeId, server.id, lp)
                return
            end
        end
    end
end

-- ==========================================
-- HELPER FUNCTIONS & ESP
-- ==========================================
local function checkTool(playerTarget, toolName)
    local bp = playerTarget:FindFirstChild("Backpack")
    local char = playerTarget.Character
    return (bp and bp:FindFirstChild(toolName)) or (char and char:FindFirstChild(toolName))
end

local function getMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and checkTool(p, "Knife") then return p end
    end
    return nil
end

local function getSheriff()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and checkTool(p, "Gun") then return p end
    end
    return nil
end

local function applyESP(player)
    if player == lp then return end
    local function setupHighlight(char)
        if not char then return end
        local highlight = char:FindFirstChild("ESPHighlight") or Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.Adornee = char
        highlight.Parent = char
        
        RunService.Heartbeat:Connect(function()
            if not char or not char:Parent or not getgenv().EnableESP then
                highlight.Enabled = false
                return
            end
            highlight.Enabled = true
            if checkTool(player, "Knife") then
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
            elseif checkTool(player, "Gun") then
                highlight.FillColor = Color3.fromRGB(0, 150, 255)
            else
                highlight.FillColor = Color3.fromRGB(0, 255, 100)
            end
        end)
    end
    if player.Character then setupHighlight(player.Character) end
    player.CharacterAdded:Connect(setupHighlight)
end

for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end
Players.PlayerAdded:Connect(applyESP)

-- ==========================================
-- UI SETUP
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "MM2 Ultimate CFrame Hub",
   LoadingTitle = "Loading 16 Studs/s Engine...",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local Tab = Window:CreateTab("CFrame Farm", "zap")
local CombatTab = Window:CreateTab("Combat", "swords")
local VisualTab = Window:CreateTab("Visuals", "eye")
local MiscTab = Window:CreateTab("Misc", "settings")

Tab:CreateToggle({ Name = "Auto Farm Coins", CurrentValue = getgenv().AutoFarm, Callback = function(v) getgenv().AutoFarm = v end })
Tab:CreateSlider({ Name = "CFrame Speed", Range = {1, 50}, Increment = 1, Suffix = "Studs/s", CurrentValue = getgenv().Speed, Callback = function(v) getgenv().Speed = v end })
Tab:CreateToggle({ Name = "Safe Start (25s Wait)", CurrentValue = getgenv().SafeStart, Callback = function(v) getgenv().SafeStart = v end })

CombatTab:CreateToggle({ Name = "Auto Kill All (Murderer)", CurrentValue = getgenv().AutoMurderer, Callback = function(v) getgenv().AutoMurderer = v end })
CombatTab:CreateToggle({ Name = "Auto Shoot (Sheriff)", CurrentValue = getgenv().AutoSheriff, Callback = function(v) getgenv().AutoSheriff = v end })
CombatTab:CreateToggle({ Name = "Auto Fling Sheriff", CurrentValue = getgenv().AutoFlingSheriff, Callback = function(v) getgenv().AutoFlingSheriff = v end })
CombatTab:CreateSlider({ Name = "Combat Coin Target", Range = {0, 50}, Increment = 1, Suffix = "Coins", CurrentValue = getgenv().CombatCoinTarget, Callback = function(v) getgenv().CombatCoinTarget = v end })

VisualTab:CreateToggle({ Name = "Player ESP", CurrentValue = getgenv().EnableESP, Callback = function(v) getgenv().EnableESP = v end })
VisualTab:CreateToggle({ Name = "Hitbox Expander", CurrentValue = getgenv().HitboxExpander, Callback = function(v) getgenv().HitboxExpander = v end })

MiscTab:CreateToggle({ Name = "Hop After 22 Mins", CurrentValue = getgenv().TimeHop, Callback = function(v) getgenv().TimeHop = v end })
MiscTab:CreateToggle({ Name = "Hop (< 4 Players)", CurrentValue = getgenv().AutoServerHop, Callback = function(v) getgenv().AutoServerHop = v end })
MiscTab:CreateToggle({ Name = "Anti-Admin Hop", CurrentValue = getgenv().AntiAdminHop, Callback = function(v) getgenv().AntiAdminHop = v end })
MiscTab:CreateToggle({ Name = "Discord Webhooks", CurrentValue = getgenv().EnableWebhook, Callback = function(v) getgenv().EnableWebhook = v end })

-- ==========================================
-- HITBOX EXPANDER
-- ==========================================
RunService.RenderStepped:Connect(function()
    if getgenv().HitboxExpander then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = p.Character.HumanoidRootPart
                hrp.Size = Vector3.new(getgenv().HitboxSize, getgenv().HitboxSize, getgenv().HitboxSize)
                hrp.Transparency = 0.7
                hrp.CanCollide = false
            end
        end
    end
end)

-- ==========================================
-- REAL-TIME STATS OVERLAY
-- ==========================================
local guiParent = pcall(function() return CoreGui.Name end) and CoreGui or lp.PlayerGui
local statsGui = Instance.new("ScreenGui", guiParent)
local statsFrame = Instance.new("Frame", statsGui)
local statsLabel = Instance.new("TextLabel", statsFrame)

statsFrame.Size = UDim2.new(0, 220, 0, 50)
statsFrame.Position = UDim2.new(0, 15, 0.5, -25)
statsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
statsFrame.BackgroundTransparency = 0.2
statsFrame.BorderSizePixel = 0

statsLabel.Size = UDim2.new(1, 0, 1, 0)
statsLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
statsLabel.TextScaled = true
statsLabel.Font = Enum.Font.GothamBold
statsLabel.BackgroundTransparency = 1

-- ==========================================
-- MAIN ENGINE LOOP
-- ==========================================
task.spawn(function()
    local coinsCollectedRound = 0
    local inLobby = true
    local waitingForRoles = false

    while task.wait() do
        -- Update Stat Overlay
        local elapsedTime = math.max(1, os.time() - sessionStats.startTime)
        local cpm = math.floor((sessionStats.totalCoins / elapsedTime) * 60)
        local minsRunning = math.floor((os.time() - scriptStartTime) / 60)
        statsLabel.Text = "Farmed: " .. sessionStats.totalCoins .. " 🪙\nTime: " .. minsRunning .. " / " .. getgenv().HopMinutes .. "m"

        -- 22-Minute Timer Server Hop
        if getgenv().TimeHop and (os.time() - scriptStartTime) >= (getgenv().HopMinutes * 60) then
            sendWebhook("Time Limit Reached ⏳", getgenv().HopMinutes .. " minutes elapsed. Hopping server...", 16753920)
            serverHop()
            task.wait(5)
            continue
        end

        -- Anti-Admin Check
        if getgenv().AntiAdminHop then
            for _, p in ipairs(Players:GetPlayers()) do
                if p:GetRankInGroup(1200769) and p:GetRankInGroup(1200769) > 0 then
                    sendWebhook("Admin Detected 🚨", "Staff joined. Hopping...", 16711680)
                    serverHop()
                    task.wait(3)
                    continue
                end
            end
        end

        -- Low Player Hop
        if getgenv().AutoServerHop and #Players:GetPlayers() < 4 then
            sendWebhook("Dead Server 💀", "Less than 4 players. Hopping...", 16753920)
            serverHop()
            task.wait(3)
            continue
        end

        local char = lp.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or char.Humanoid.Health <= 0 then 
            coinsCollectedRound = 0 
            inLobby = true
            waitingForRoles = false
            task.wait(1)
            continue 
        end
        
        local root = char.HumanoidRootPart

        -- Get All Available Coins
        local availableCoins = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name == "Coin_Server" or obj.Name == "Coin") and obj.Name ~= "Collected" then
                table.insert(availableCoins, obj)
            end
        end

        -- Safe Start & Lobby Detection
        if #availableCoins > 0 then
            local lobbyDist = (root.Position - availableCoins[1].Position).Magnitude
            if lobbyDist > 2000 then
                inLobby = true
                waitingForRoles = false
                coinsCollectedRound = 0
                char.Humanoid.PlatformStand = false
                task.wait(1)
                continue
            elseif inLobby then
                inLobby = false
                if getgenv().SafeStart then
                    waitingForRoles = true
                    task.spawn(function()
                        local startCFrame = root.CFrame
                        local platform = Instance.new("Part", workspace)
                        platform.Size = Vector3.new(15, 1, 15)
                        platform.Position = startCFrame.Position + Vector3.new(0, 300, 0)
                        platform.Anchored = true
                        platform.CanCollide = true
                        
                        for i = 25, 1, -1 do
                            if not char:FindFirstChild("HumanoidRootPart") or char.Humanoid.Health <= 0 then break end
                            root.CFrame = platform.CFrame + Vector3.new(0, 3, 0)
                            task.wait(1)
                        end
                        
                        platform:Destroy()
                        if char:FindFirstChild("HumanoidRootPart") then root.CFrame = startCFrame end
                        waitingForRoles = false
                    end)
                end
            end
        end

        if waitingForRoles or not getgenv().AutoFarm then continue end

        local isMurderer = checkTool(lp, "Knife")
        local isSheriff = checkTool(lp, "Gun")
        local knife = char:FindFirstChild("Knife") or lp.Backpack:FindFirstChild("Knife")
        local gun = char:FindFirstChild("Gun") or lp.Backpack:FindFirstChild("Gun")

        -- FLING SHERIFF
        if getgenv().AutoFlingSheriff and not isSheriff and not isMurderer then
            local sheriff = getSheriff()
            local gunDrop = workspace:FindFirstChild("GunDrop", true)
            if sheriff and not gunDrop then
                local tRoot = sheriff.Character and sheriff.Character:FindFirstChild("HumanoidRootPart")
                if tRoot then
                    local oldCFrame = root.CFrame
                    local bav = Instance.new("BodyAngularVelocity", root)
                    bav.AngularVelocity = Vector3.new(0, getgenv().FlingVelocity, 0)
                    bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    
                    local st = os.clock()
                    while os.clock() - st < 1.2 do
                        if not tRoot or sheriff.Character.Humanoid.Health <= 0 then break end
                        root.CFrame = tRoot.CFrame
                        root.Velocity = Vector3.new(getgenv().FlingVelocity, getgenv().FlingVelocity, getgenv().FlingVelocity)
                        task.wait()
                    end
                    
                    bav:Destroy()
                    root.Velocity = Vector3.zero
                    root.RotVelocity = Vector3.zero
                    root.CFrame = oldCFrame
                    task.wait(0.5)
                    continue
                end
            end
        end

        -- AUTO GUN DROP PICKUP
        if getgenv().AutoGunDrop and not isSheriff and not isMurderer then
            local gunDrop = workspace:FindFirstChild("GunDrop", true)
            if gunDrop and gunDrop:IsA("BasePart") then
                char.Humanoid.PlatformStand = true
                root.CFrame = gunDrop.CFrame
                task.wait(0.3)
                continue
            end
        end

        -- COMBAT (MURDERER / SHERIFF)
        if isMurderer and coinsCollectedRound >= getgenv().CombatCoinTarget and getgenv().AutoMurderer then
            char.Humanoid:EquipTool(knife)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
                    local targetRoot = p.Character.HumanoidRootPart
                    root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 1)
                    if firetouchinterest and knife:FindFirstChild("Handle") then
                        firetouchinterest(knife.Handle, targetRoot, 0)
                        task.wait(0.01)
                        firetouchinterest(knife.Handle, targetRoot, 1)
                    end
                    task.wait(0.1)
                end
            end
            continue
        end

        if isSheriff and coinsCollectedRound >= getgenv().CombatCoinTarget and getgenv().AutoSheriff then
            local murderer = getMurderer()
            if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") and murderer.Character.Humanoid.Health > 0 then
                char.Humanoid:EquipTool(gun)
                local targetRoot = murderer.Character.HumanoidRootPart
                root.CFrame = targetRoot.CFrame * CFrame.new(0, 15, 0)
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, targetRoot.Position)
                task.wait(0.1)
                gun:Activate()
                vu:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(0.05)
                vu:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(0.5)
                continue
            end
        end

        -- CFRAME COIN MOVEMENT (16 STUDS/SEC)
        if coinsCollectedRound < 45 and #availableCoins > 0 then
            char.Humanoid.PlatformStand = true
            local targetCoin = availableCoins[1]

            -- Step towards coin position using CFrame stepping
            while targetCoin and targetCoin.Parent and targetCoin.Name ~= "Collected" do
                local dt = task.wait()
                if not root or not root.Parent or not getgenv().AutoFarm then break end

                local currentPos = root.Position
                local targetPos = targetCoin.Position
                local dist = (targetPos - currentPos).Magnitude

                if dist <= 1.5 then
                    break
                end

                val dir = (targetPos - currentPos).Unit
                local stepDist = math.min(dist, getgenv().Speed * dt)
                root.CFrame = CFrame.new(currentPos + (dir * stepDist))
            end

            if targetCoin and targetCoin.Parent then
                root.CFrame = targetCoin.CFrame
                if firetouchinterest then
                    firetouchinterest(root, targetCoin, 0)
                    task.wait(0.01)
                    firetouchinterest(root, targetCoin, 1)
                end
                targetCoin.Name = "Collected"
                coinsCollectedRound = coinsCollectedRound + 1
                sessionStats.totalCoins = sessionStats.totalCoins + 1
            end

            if coinsCollectedRound % 15 == 0 then
                sendWebhook("Milestone Reached 🪙", "Collected " .. coinsCollectedRound .. " coins this round.", 16766720)
            end
        else
            -- Waits idle if 45 coins are reached, unless combat roles trigger
            char.Humanoid.PlatformStand = false
            task.wait(0.5)
        end
    end
end)
