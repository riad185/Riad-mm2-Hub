--[[
    ╔══════════════════════════════════════════════════════════════════╗

        ██████╗ ██╗ █████╗ ██████╗     ██╗   ██╗██╗   ██╗██████╗
        ██╔══██╗██║██╔══██╗██╔══██╗    ██║   ██║██║   ██║██╔══██╗
        ██████╔╝██║███████║██║  ██║    ██║   ██║██║   ██║██████╔╝
        ██╔══██╗██║██╔══██║██║  ██║    ╚██╗ ██╔╝██║   ██║██╔══██╗
        ██║  ██║██║██║  ██║██████╔╝     ╚████╔╝ ╚██████╔╝██████╔╝
        ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═════╝       ╚═══╝   ╚═════╝ ╚═════╝

    ║  MURDER MYSTERY 2  ·  ·  Rayfield Gen2                     ║
    ║  built for ALL  ·  github.com/riad185/Riad-mm2-Hub              ║
    ╚══════════════════════════════════════════════════════════════════╝
]]


if getgenv and getgenv().RiadHub_Unload then pcall(getgenv().RiadHub_Unload) end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local CoreGui           = game:GetService("CoreGui")
local Lighting          = game:GetService("Lighting")
local TeleportService   = game:GetService("TeleportService")
local CollectionService = game:GetService("CollectionService")
local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local activeConnections = {}

local Config = {
    RoleESP = false, ESPBoxes = false, ESPNames = true, ESPTracers = false,
    ESPDistance = true, ESPChams = false, ESPHealth = false,
    ESPDistanceMax = 600, GunESP = false, CoinESP = false,
    Fullbright = false, NoFog = false, DisableParticles = false, FPSBoost = false,

    Aimbot = false, AutoShoot = false, SilentAim = false,
    AimPrediction = true, PingComp = true, SingleShot = false,
    FOVRadius = 160, ShowFOV = false,
    AutoEquipGun = true, GrabGunAuto = false, GunGrabDist = 300,
    AutoGrabOnSheriffDeath = false,

    AutoStab = false, KillAura = false, AutoKill = false,
    KillMode = "Legit", KnifeSilentAim = true, AuraRange = 15,
    ShowAuraRing = false, AutoEquipKnife = true,
    ProximityKnife = true, KnifeProxDist = 18,

    HitboxExpander = false, HitboxSize = 10, HitboxTransparency = 0.6,

    MurdererAvoid = false, SafetyRadius = 40, RetreatToLobby = false,
    ProximityAlert = true, SprintWhenChased = true,
    FollowMurderer = false, FollowDist = 18,
    AutoPlay = false,

    Speed = false, SpeedValue = 24, JumpEnabled = false, JumpValue = 50,
    InfiniteJump = false, Noclip = false, Fly = false, FlySpeed = 35,
    AntiRagdoll = false, AntiVoid = true, AntiFling = true,

    CoinFarm = false, FarmSpeed = 28, FarmMethod = "Teleport",
    SafeCoinFarm = true, BagFullStop = true,
    CoinBagCap = 40, TeleportFarmDelay = 0.05,
    CoinMagnet = false, MagnetRadius = 60,

    FlingStyle = "Torque",
    FlingMurdererPreRound = false, FlingSheriffPreRound = false,
    FlingHeroPreRound = false, FlingSheriffDuringRound = false,
    FlingAllPreRound = false,

    AntiAFK = true, KillFeed = true, RoundNotifs = true,
}

----------------------------------------------------------------
-- helpers
----------------------------------------------------------------

local State = {
    Highlights = {}, ItemHighlights = {}, Boxes = {}, Tracers = {},
    DeadPlayers = {}, OriginalHitboxSizes = {}, OriginalLighting = {},
    IsFlinging = false, AuraRing = nil, FOVCircle = nil,
    SilentAimHookActive = true, RoundState = "Waiting",
    LastSafePosition = nil, flyBV = nil, Spectating = nil,
    ShotThisRound = false, Notified = {},
}

local espFolder = Instance.new("Folder")
espFolder.Name = "RiadHub_ESP"
if not pcall(function() espFolder.Parent = CoreGui end) then
    espFolder.Parent = LP:WaitForChild("PlayerGui")
end

local function getHRP(p)
    local c = p and p.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso")
        or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart")
end
local function getHumanoid(p)
    local c = p and p.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function isAlive(p)
    local h = getHumanoid(p)
    return h and h.Health > 0
end
local function getRole(p)
    local bp = p and p:FindFirstChild("Backpack")
    local ch = p and p.Character
    if (bp and bp:FindFirstChild("Knife")) or (ch and ch:FindFirstChild("Knife")) then return "Murderer" end
    if (bp and bp:FindFirstChild("Gun"))   or (ch and ch:FindFirstChild("Gun"))   then return "Sheriff" end
    return "Innocent"
end
local function roleColor(role)
    if role == "Murderer" then return Color3.fromRGB(255, 40, 40) end
    if role == "Sheriff"  then return Color3.fromRGB(40, 120, 255) end
    return Color3.fromRGB(230, 230, 230)
end
local function getRolePlayers()
    local m, s, inno = nil, nil, {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local r = getRole(p)
            if r == "Murderer" then m = p
            elseif r == "Sheriff" then s = p
            else table.insert(inno, p) end
        end
    end
    return m, s, inno
end
local function clearCategory(tbl)
    for _, obj in pairs(tbl) do
        if obj and obj.Parent then obj:Destroy() end
    end
    table.clear(tbl)
end
local function getActiveMap()
    for _, c in ipairs(Workspace:GetChildren()) do
        if c:IsA("Model")
            and not string.find(string.lower(c.Name), "lobby")
            and not Players:GetPlayerFromCharacter(c)
            and (c:FindFirstChild("Spawns") or c:FindFirstChild("CoinContainer") or c:FindFirstChild("Base")) then
            return c
        end
    end
    return nil
end
local function getLobbyModel()
    for _, c in ipairs(Workspace:GetChildren()) do
        if c:IsA("Model") and string.find(string.lower(c.Name), "lobby") then return c end
    end
    return Workspace:FindFirstChild("Lobby")
end
local function getAllActiveCoins()
    local coins, seen = {}, {}
    for _, tag in ipairs({"CoinVisual", "Coin"}) do
        for _, v in ipairs(CollectionService:GetTagged(tag)) do
            if v and v.Parent and not v:GetAttribute("Collected") and not v:GetAttribute("Delete") then
                local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                if part and not seen[part] and part.Transparency < 0.95 then
                    seen[part] = true
                    table.insert(coins, part)
                end
            end
        end
    end
    if #coins == 0 then
        local map = getActiveMap()
        if map then
            local container = map:FindFirstChild("CoinContainer") or map:FindFirstChild("Coins")
            if container then
                for _, d in ipairs(container:GetDescendants()) do
                    if d:IsA("BasePart") and not seen[d]
                        and (d:GetAttribute("CoinID") or string.find(string.lower(d.Name), "coin"))
                        and d.Transparency < 0.95 then
                        seen[d] = true
                        table.insert(coins, d)
                    end
                end
            end
        end
    end
    return coins
end
local function getCurrentCoinCount()
    local pg = LP:FindFirstChild("PlayerGui")
    local mg = pg and pg:FindFirstChild("MainGUI")
    local gu = mg and mg:FindFirstChild("Game")
    local bag = gu and gu:FindFirstChild("CoinBag")
    if bag then
        for _, d in ipairs(bag:GetDescendants()) do
            if d:IsA("TextLabel") and string.find(d.Text, "/") then
                local n = tonumber(string.match(d.Text, "(%d+)%s*/"))
                if n then return n end
            end
        end
    end
    return 0
end
local function getGunDrop()
    return Workspace:FindFirstChild("GunDrop") or Workspace:FindFirstChild("GunDrop", true)
end
local function getGunDropPart(drop)
    if not drop then return nil end
    if drop:IsA("BasePart") then return drop end
    if drop:IsA("Model") or drop:IsA("Folder") or drop:IsA("Tool") then
        local p = drop:FindFirstChild("GunDrop") or drop:FindFirstChild("Handle")
            or drop.PrimaryPart or drop:FindFirstChildWhichIsA("BasePart")
        if p and p:IsA("BasePart") then return p end
        for _, d in ipairs(drop:GetDescendants()) do
            if d:IsA("BasePart") then return d end
        end
    end
    return nil
end
local function fireTouch(a, b)
    if firetouchinterest and a and b then
        pcall(firetouchinterest, a, b, true)
        task.wait()
        pcall(firetouchinterest, a, b, false)
    end
end
local function interactWithGunDrop(gunPart, gunObj)
    if not gunPart then return end
    local ch = LP.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local prompt = gunObj and gunObj:FindFirstChildOfClass("ProximityPrompt", true)
    if prompt and fireproximityprompt then pcall(fireproximityprompt, prompt) end
    fireTouch(root, gunPart)
    local rh = ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm")
    if rh then fireTouch(rh, gunPart) end
end
local function nearestTarget(maxDist)
    maxDist = maxDist or math.huge
    local best, bestDist = nil, maxDist
    local myHRP = getHRP(LP)
    if not myHRP then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local hrp = getHRP(p)
            if hrp then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < bestDist then best, bestDist = p, d end
            end
        end
    end
    return best
end
local function equipTool(name)
    local ch = LP.Character
    if not ch then return nil end
    local bp = LP:FindFirstChild("Backpack")
    local h = getHumanoid(LP)
    local tool = ch:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
    if tool and h and bp and tool.Parent == bp then
        h:EquipTool(tool)
        task.wait(0.05)
    end
    return tool
end
local function notify(title, body, dur)
    pcall(function()
        Rayfield:Notify({ title = title, content = body, duration = dur or 3 })
    end)
end
local function killFeed(msg)
    if Config.KillFeed then notify("Kill Feed", msg, 4) end
end

----------------------------------------------------------------
-- lighting originals / fullbright / fps boost
----------------------------------------------------------------

for _, k in ipairs({"ClockTime", "FogEnd", "Brightness", "Ambient", "OutdoorAmbient"}) do
    State.OriginalLighting[k] = Lighting[k]
end

local function applyVisualWorld()
    if Config.Fullbright then
        Lighting.ClockTime = 14
        Lighting.Brightness = 3
        Lighting.FogEnd = 1e6
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    else
        Lighting.ClockTime = State.OriginalLighting.ClockTime
        Lighting.Brightness = State.OriginalLighting.Brightness
        Lighting.FogEnd = State.OriginalLighting.FogEnd
        Lighting.Ambient = State.OriginalLighting.Ambient
        Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
    end
end

local function fpsBoostPass()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if Config.DisableParticles and d:IsA("ParticleEmitter") then d.Enabled = false end
        if Config.FPSBoost then
            if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 1 end
            if d:IsA("MeshPart") then d.TextureID = "" end
        end
    end
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
end

----------------------------------------------------------------
-- fling engine
----------------------------------------------------------------

local function flingCharacter(targetChar)
    if State.IsFlinging then return end
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local tRoot  = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not tRoot then return end
    local myHum = getHumanoid(LP)
    local tHum  = targetChar:FindFirstChildOfClass("Humanoid")
    if not myHum or myHum.Health <= 0 or not tHum or tHum.Health <= 0 then return end

    State.IsFlinging = true
    local oldCF = myRoot.CFrame

    pcall(function()
        sethiddenproperty(LP, "SimulationRadius", 10000)
        sethiddenproperty(LP, "MaxSimulationRadius", 10000)
    end)
    pcall(function() setsimulationradius(10000) end)

    local bAV = Instance.new("BodyAngularVelocity")
    bAV.AngularVelocity = Vector3.new(0, 9e9, 0)
    bAV.MaxTorque = Vector3.new(0, 9e9, 0)
    bAV.P = 9e9
    bAV.Parent = myRoot

    local bV = Instance.new("BodyVelocity")
    bV.Velocity = Vector3.zero
    bV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bV.Parent = myRoot

    local conn = RunService.Stepped:Connect(function()
        if myChar and myChar.Parent then
            for _, child in ipairs(myChar:GetDescendants()) do
                if child:IsA("BasePart") then child.CanCollide = false end
            end
        end
    end)
    table.insert(activeConnections, conn)

    local start = tick()
    while tick() - start < 1.5 do
        if not targetChar or not targetChar.Parent or not tRoot.Parent or tHum.Health <= 0 then break end
        if not myChar.Parent or myHum.Health <= 0 then break end
        if Config.FlingStyle == "Velocity" then
            myRoot.CFrame = CFrame.new(tRoot.Position + Vector3.new(0, 1.2, 0))
            myRoot.AssemblyLinearVelocity = Vector3.new(0, 9e9, 0)
            myRoot.AssemblyAngularVelocity = Vector3.new(9e9, 9e9, 9e9)
        elseif Config.FlingStyle == "Orbit" then
            local angle = (tick() - start) * 20
            local off = Vector3.new(math.cos(angle) * 1.5, 0.5, math.sin(angle) * 1.5)
            myRoot.CFrame = CFrame.new(tRoot.Position + off, tRoot.Position)
            myRoot.AssemblyLinearVelocity = Vector3.new(9e9, 9e9, 9e9)
            myRoot.AssemblyAngularVelocity = Vector3.new(9e9, 9e9, 9e9)
        else
            myRoot.CFrame = tRoot.CFrame
            myRoot.AssemblyLinearVelocity = Vector3.new(9e9, 9e9, 9e9)
            myRoot.AssemblyAngularVelocity = Vector3.new(9e9, 9e9, 9e9)
        end
        RunService.Heartbeat:Wait()
    end

    pcall(function() conn:Disconnect() bAV:Destroy() bV:Destroy() end)
    if myRoot and myRoot.Parent then
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero
        myRoot.CFrame = oldCF
    end
    task.wait(0.15)
    State.IsFlinging = false
end

local function flingByRole(role)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) and getRole(p) == role then
            task.spawn(flingCharacter, p.Character)
            task.wait(0.1)
        end
    end
end

----------------------------------------------------------------
-- silent aim hook
----------------------------------------------------------------

if hookmetamethod and getnamecallmethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if State.SilentAimHookActive and not checkcaller() and method == "FireServer" then
            local args = {...}
            if self.Name == "KnifeThrown" and (Config.KnifeSilentAim or Config.SilentAim) then
                local tgt = nearestTarget()
                if tgt then
                    local tRoot = getHRP(tgt)
                    if tRoot then
                        local pos = tRoot.Position
                        if Config.AimPrediction then
                            pos = pos + (tRoot.AssemblyLinearVelocity * (Config.PingComp and 0.16 or 0.12))
                        end
                        args[2] = CFrame.new(pos)
                        return oldNamecall(self, unpack(args))
                    end
                end
            elseif self.Name == "Shoot" and Config.SilentAim then
                local m = select(1, getRolePlayers())
                if m then
                    local mRoot = getHRP(m)
                    if mRoot then
                        local pos = mRoot.Position
                        if Config.AimPrediction then
                            pos = pos + (mRoot.AssemblyLinearVelocity * (Config.PingComp and 0.16 or 0.12))
                        end
                        args[2] = CFrame.new(pos)
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end))
end

----------------------------------------------------------------
-- ESP primitives
----------------------------------------------------------------

local function getOrCreateBillboard(id, adornee, text, color)
    local bb = State.Highlights[id]
    if not bb or not bb.Parent then
        bb = Instance.new("BillboardGui")
        bb.Name = id
        bb.Size = UDim2.new(0, 180, 0, 56)
        bb.StudsOffset = Vector3.new(0, 2.8, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = adornee
        bb.Parent = espFolder
        local lbl = Instance.new("TextLabel")
        lbl.Name = "Tag"
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextStrokeTransparency = 0.3
        lbl.Parent = bb
        State.Highlights[id] = bb
    end
    bb.Adornee = adornee
    bb.MaxDistance = Config.ESPDistanceMax
    local tag = bb:FindFirstChild("Tag")
    if tag then tag.Text = text tag.TextColor3 = color end
    return bb
end

local function getOrCreateBox(id, adornee, color)
    local box = State.Boxes[id]
    if not box or not box.Parent then
        box = Instance.new("BoxHandleAdornment")
        box.Name = "box_" .. id
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Size = Vector3.new(3.5, 6.2, 3.5)
        box.Transparency = 0.6
        box.Parent = espFolder
        State.Boxes[id] = box
    end
    box.Adornee = adornee
    box.Color3 = color
    return box
end

local function getOrCreateCham(id, char, color)
    local hl = State.Highlights["cham_" .. id]
    if not hl or not hl.Parent then
        hl = Instance.new("Highlight")
        hl.Name = "cham_" .. id
        hl.OutlineColor = Color3.fromRGB(243, 240, 255)
        hl.FillTransparency = 0.45
        hl.OutlineTransparency = 0.1
        hl.Parent = espFolder
        State.Highlights["cham_" .. id] = hl
    end
    hl.Adornee = char
    hl.FillColor = color
    return hl
end

local function updateTracer(id, targetPos, color)
    if not Drawing or not Drawing.new then return end
    local line = State.Tracers[id]
    if not line then
        pcall(function()
            line = Drawing.new("Line")
            line.Thickness = 1.5
            line.Transparency = 0.85
            State.Tracers[id] = line
        end)
        line = State.Tracers[id]
        if not line then return end
    end
    if Config.ESPTracers then
        local sp, onScreen = Camera:WorldToViewportPoint(targetPos - Vector3.new(0, 2.5, 0))
        local myRoot = getHRP(LP)
        if onScreen and myRoot then
            local ms = Camera:WorldToViewportPoint(myRoot.Position - Vector3.new(0, 2.8, 0))
            line.From = Vector2.new(ms.X, ms.Y)
            line.To = Vector2.new(sp.X, sp.Y)
            line.Color = color
            line.Visible = true
        else
            line.Visible = false
        end
    else
        line.Visible = false
    end
end

if Drawing and Drawing.new then
    pcall(function()
        State.FOVCircle = Drawing.new("Circle")
        State.FOVCircle.Thickness = 1.5
        State.FOVCircle.Color = Color3.fromRGB(80, 220, 120)
        State.FOVCircle.Filled = false
        State.FOVCircle.Transparency = 0.8
        State.FOVCircle.Visible = false
    end)
end

local function updateAuraRing(myRoot)
    if not Config.ShowAuraRing or not myRoot then
        if State.AuraRing then State.AuraRing.Transparency = 1 end
        return
    end
    if not State.AuraRing or not State.AuraRing.Parent then
        local p = Instance.new("Part")
        p.Name = "Riad_AuraRing"
        p.Anchored, p.CanCollide, p.CastShadow, p.Transparency = true, false, false, 1
        local sg = Instance.new("SurfaceGui")
        sg.Face = Enum.NormalId.Top
        sg.AlwaysOnTop = true
        sg.LightInfluence = 0
        sg.Adornee = p
        sg.Parent = p
        local fr = Instance.new("Frame")
        fr.Size = UDim2.new(1, 0, 1, 0)
        fr.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
        fr.BackgroundTransparency = 0.92
        fr.BorderSizePixel = 0
        fr.Parent = sg
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = fr
        local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(80, 220, 120)
        s.Thickness = 2.5 s.Transparency = 0.1 s.Parent = fr
        p.Parent = Workspace
        State.AuraRing = p
    end
    local d = Config.AuraRange * 2
    State.AuraRing.Size = Vector3.new(d, 0.01, d)
    State.AuraRing.Transparency = 0
    State.AuraRing.CFrame = CFrame.new(myRoot.Position.X, myRoot.Position.Y - 2.85, myRoot.Position.Z)
end

----------------------------------------------------------------
-- MAIN LOOP
----------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(0.1)
        local myRoot = getHRP(LP)

        -- role ESP
        if Config.RoleESP then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local hrp = getHRP(p)
                    if hrp and isAlive(p) then
                        local role = getRole(p)
                        local color = roleColor(role)
                        local dist = myRoot and math.floor((hrp.Position - myRoot.Position).Magnitude) or 0
                        local text = Config.ESPNames and p.Name or ""
                        if Config.ESPDistance then text = text .. " [" .. dist .. "m]" end
                        if Config.ESPHealth then
                            local h = getHumanoid(p)
                            if h then text = text .. string.format(" %.0f%%", h.Health / h.MaxHealth * 100) end
                        end
                        getOrCreateBillboard(p.UserId, hrp, text, color)
                        if Config.ESPBoxes then getOrCreateBox(p.UserId, hrp, color) end
                        if Config.ESPChams then getOrCreateCham(p.UserId, p.Character, color) end
                        updateTracer(p.UserId, hrp.Position, color)
                    end
                end
            end
        else
            for id, bb in pairs(State.Highlights) do if bb:IsA("BillboardGui") then bb:Destroy() State.Highlights[id] = nil end end
            for id, box in pairs(State.Boxes) do if not box.Parent or not box.Adornee or not box.Adornee.Parent then box:Destroy() State.Boxes[id] = nil end end
        end

        -- item ESP (gun drop + coins)
        for _, obj in pairs(State.ItemHighlights) do obj:Destroy() end
        table.clear(State.ItemHighlights)
        if Config.GunESP then
            local gd = getGunDrop()
            local gp = getGunDropPart(gd)
            if gp then
                local bb = getOrCreateBillboard("gun_" .. gp:GetDebugId(), gp, "GUN", Color3.fromRGB(255, 220, 40))
                State.ItemHighlights["gun"] = bb
            end
        end
        if Config.CoinESP then
            for i, coin in ipairs(getAllActiveCoins()) do
                if i > 60 then break end
                State.ItemHighlights["coin_" .. i] =
                    getOrCreateBillboard("coin_" .. i, coin, "$", Color3.fromRGB(120, 255, 120))
            end
        end

        -- FOV circle
        if State.FOVCircle then
            State.FOVCircle.Visible = Config.ShowFOV
            if Config.ShowFOV then
                State.FOVCircle.Radius = Config.FOVRadius
                State.FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            end
        end

        updateAuraRing(myRoot)

        -- hitbox expander
        if Config.HitboxExpander then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local hrp = getHRP(p)
                    if hrp then
                        if not State.OriginalHitboxSizes[hrp] then
                            State.OriginalHitboxSizes[hrp] = hrp.Size
                        end
                        hrp.Size = Vector3.one * Config.HitboxSize
                        hrp.Transparency = Config.HitboxTransparency
                        hrp.CanCollide = false
                        hrp.Massless = true
                    end
                end
            end
        else
            for part, sz in pairs(State.OriginalHitboxSizes) do
                if part and part.Parent then
                    part.Size = sz
                    part.Transparency = 1
                end
            end
            State.OriginalHitboxSizes = {}
        end

        -- anti-void
        if Config.AntiVoid and myRoot and myRoot.Position.Y < -50 then
            if State.LastSafePosition then
                myRoot.CFrame = State.LastSafePosition
            else
                local lb = getLobbyModel()
                local part = lb and lb:FindFirstChildWhichIsA("BasePart")
                if part then myRoot.CFrame = part.CFrame + Vector3.new(0, 5, 0) end
            end
        end
        if myRoot and myRoot.Position.Y > -20 then
            State.LastSafePosition = myRoot.CFrame
        end

        -- anti-fling
        if Config.AntiFling and myRoot then
            local v = myRoot.AssemblyLinearVelocity
            if v.Magnitude > 500 then
                myRoot.AssemblyLinearVelocity = Vector3.zero
                myRoot.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
end)

----------------------------------------------------------------
-- COMBAT LOOP
----------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(0.15)
        local myRoot = getHRP(LP)
        if not myRoot then continue end
        local m, s, inno = getRolePlayers()
        local myRole = getRole(LP)

        -- auto-stab / kill aura / auto-kill (murderer side)
        if myRole == "Murderer" then
            if Config.AutoEquipKnife then equipTool("Knife") end
            local knife = LP.Character and LP.Character:FindFirstChild("Knife")
            if knife then
                if Config.AutoStab then
                    local tgt = nearestTarget(Config.KnifeProxDist)
                    if tgt then knife:Activate() end
                end
                if Config.KillAura then
                    local tgt = nearestTarget(Config.AuraRange)
                    if tgt then
                        if Config.KillMode == "Throw" and knife.Parent == LP.Character then
                            local tRoot = getHRP(tgt)
                            if tRoot then
                                knife:Activate()
                            end
                        else
                            local tRoot = getHRP(tgt)
                            if tRoot then
                                myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 2.5)
                                knife:Activate()
                            end
                        end
                    end
                end
                if Config.AutoKill then
                    for _, p in ipairs(inno) do
                        local hrp = getHRP(p)
                        if hrp and isAlive(p) then
                            myRoot.CFrame = hrp.CFrame * CFrame.new(0, 0, 2.5)
                            knife:Activate()
                            task.wait(0.05)
                        end
                    end
                end
            end
        end

        -- auto shoot / aimbot (sheriff side)
        if myRole == "Sheriff" then
            if Config.AutoEquipGun then equipTool("Gun") end
            if m and isAlive(m) then
                local mRoot = getHRP(m)
                local myCam = Camera
                if mRoot then
                    local sp, onScreen = myCam:WorldToViewportPoint(mRoot.Position)
                    local distFromCenter = (Vector2.new(sp.X, sp.Y) - Vector2.new(myCam.ViewportSize.X, myCam.ViewportSize.Y) / 2).Magnitude
                    if Config.AutoShoot and onScreen and distFromCenter < Config.FOVRadius then
                        if not (Config.SingleShot and State.ShotThisRound) then
                            local gun = LP.Character and LP.Character:FindFirstChild("Gun")
                            if gun and gun:FindFirstChild("Shoot") then
                                gun.Shoot:FireServer(myRoot.CFrame, CFrame.new(mRoot.Position))
                                State.ShotThisRound = true
                            end
                        end
                    end
                    if Config.Aimbot and onScreen and distFromCenter < Config.FOVRadius then
                        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, mRoot.Position)
                    end
                end
            end
        end

        -- auto gun grab
        if Config.GrabGunAuto and getRole(LP) == "Innocent" then
            local gd = getGunDrop()
            local gp = getGunDropPart(gd)
            if gp and myRoot then
                local d = (gp.Position - myRoot.Position).Magnitude
                if d < Config.GunGrabDist then
                    myRoot.CFrame = gp.CFrame * CFrame.new(0, 2, 0)
                    interactWithGunDrop(gp, gd)
                end
            end
        end

        -- survival: proximity alert / avoid / follow
        if m and myRoot then
            local mRoot = getHRP(m)
            if mRoot then
                local d = (mRoot.Position - myRoot.Position).Magnitude
                if Config.ProximityAlert and d < Config.SafetyRadius and not State.Notified[m.UserId] then
                    State.Notified[m.UserId] = true
                    notify("Proximity Alert", m.Name .. " is within " .. Config.SafetyRadius .. " studs!", 4)
                    task.delay(10, function() State.Notified[m.UserId] = nil end)
                end
                if Config.SprintWhenChased and d < Config.SafetyRadius then
                    local h = getHumanoid(LP)
                    if h then h.WalkSpeed = math.max(Config.SpeedValue, 30) end
                end
                if Config.MurdererAvoid and d < Config.SafetyRadius then
                    local away = (myRoot.Position - mRoot.Position).Unit * 15
                    myRoot.CFrame = CFrame.new(myRoot.Position + away)
                end
                if Config.FollowMurderer and d > Config.FollowDist then
                    myRoot.CFrame = mRoot.CFrame * CFrame.new(0, 0, Config.FollowDist)
                end
            end
        end

        -- retreat to lobby
        if Config.RetreatToLobby then
            local lb = getLobbyModel()
            local part = lb and lb:FindFirstChildWhichIsA("BasePart")
            if part then myRoot.CFrame = part.CFrame * CFrame.new(0, 4, 0) end
        end

        -- coin magnet: touch-grab nearby coins without moving
        if Config.CoinMagnet and myRoot then
            for _, coin in ipairs(getAllActiveCoins()) do
                if (coin.Position - myRoot.Position).Magnitude < Config.MagnetRadius then
                    fireTouch(myRoot, coin)
                end
            end
        end

        -- auto play dispatcher
        if Config.AutoPlay then
            if myRole == "Murderer" then
                Config.AutoStab = true
                Rayfield:Window and Rayfield:Window.Set and Rayfield:Window.Set("AutoStab", true)
            elseif myRole == "Sheriff" then
                Config.AutoShoot = true
            else
                Config.MurdererAvoid = true
            end
        end
    end
end)

----------------------------------------------------------------
-- MOVEMENT LOOP
----------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(0.05)
        local h = getHumanoid(LP)
        local myRoot = getHRP(LP)
        if h and myRoot then
            if Config.Speed then h.WalkSpeed = Config.SpeedValue end
            if Config.JumpEnabled then h.UseJumpPower = true h.JumpPower = Config.JumpValue end
            if Config.AntiRagdoll then
                if h.PlatformStand then h.PlatformStand = false end
                if h:GetState() == Enum.HumanoidStateType.Ragdoll then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end
        end
    end
end)

activeConnections[#activeConnections + 1] = UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local c = LP.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

activeConnections[#activeConnections + 1] = RunService.Stepped:Connect(function()
    if Config.Noclip then
        local c = LP.Character
        if c then
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("BasePart") then d.CanCollide = false end
            end
        end
    end
end)

activeConnections[#activeConnections + 1] = RunService.RenderStepped:Connect(function()
    if Config.Fly then
        local myRoot = getHRP(LP)
        if myRoot then
            if not State.flyBV or not State.flyBV.Parent then
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                bv.Velocity = Vector3.zero
                bv.Parent = myRoot
                State.flyBV = bv
            end
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
            State.flyBV.Velocity = move.Magnitude > 0 and move.Unit * Config.FlySpeed or Vector3.zero
            myRoot.AssemblyLinearVelocity = Vector3.new(State.flyBV.Velocity.X, State.flyBV.Velocity.Y, State.flyBV.Velocity.Z)
        end
    elseif State.flyBV then
        State.flyBV:Destroy()
        State.flyBV = nil
    end
end)

-- anti-AFK
activeConnections[#activeConnections + 1] = LP.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- click-TP (hold key + click)
activeConnections[#activeConnections + 1] = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local pos = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(pos.X, pos.Y)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {LP.Character}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local hit = Workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
        local myRoot = getHRP(LP)
        if hit and myRoot then
            myRoot.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
        end
    end
end)

----------------------------------------------------------------
-- COIN FARM LOOP
----------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(Config.QuickFarm and 0.02 or 0.1)
        if Config.CoinFarm then
            local myRoot = getHRP(LP)
            local h = getHumanoid(LP)
            if not myRoot or not h or h.Health <= 0 then continue end

            if Config.BagFullStop and getCurrentCoinCount() >= Config.CoinBagCap then
                task.wait(1)
                continue
            end

            if Config.SafeCoinFarm then
                local m = select(1, getRolePlayers())
                local mRoot = m and getHRP(m)
                if mRoot and (mRoot.Position - myRoot.Position).Magnitude < 30 then
                    task.wait(0.5)
                    continue
                end
            end

            local coins = getAllActiveCoins()
            if #coins == 0 then task.wait(1) continue end

            local target = coins[1]
            local bestDist = math.huge
            for _, c in ipairs(coins) do
                local d = (c.Position - myRoot.Position).Magnitude
                if d < bestDist then bestDist, target = d, c end
            end

            if target then
                if Config.FarmMethod == "Teleport" then
                    myRoot.CFrame = target.CFrame * CFrame.new(0, 1.5, 0)
                    task.wait(Config.TeleportFarmDelay)
                elseif Config.FarmMethod == "Glide" then
                    myRoot.CFrame = myRoot.CFrame:Lerp(CFrame.new(target.Position + Vector3.new(0, 2, 0)), 0.25)
                    task.wait(0.05)
                elseif Config.FarmMethod == "Tween" then
                    local tween = game:GetService("TweenService"):Create(
                        myRoot, TweenInfo.new((target.Position - myRoot.Position).Magnitude / (Config.FarmSpeed * 2), Enum.EasingStyle.Linear),
                        {CFrame = CFrame.new(target.Position + Vector3.new(0, 2, 0))}
                    )
                    tween:Play()
                    tween.Completed:Wait()
                else -- Walk
                    h:MoveTo(target.Position)
                    task.wait(0.1)
                end
            end
        end
    end
end)

----------------------------------------------------------------
-- FLING LOOPS + ROUND WATCHER
----------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(0.5)
        if State.RoundState ~= "Active" then
            if Config.FlingMurdererPreRound then flingByRole("Murderer") end
            if Config.FlingSheriffPreRound then flingByRole("Sheriff") end
            if Config.FlingHeroPreRound then flingByRole("Innocent") end
            if Config.FlingAllPreRound then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and isAlive(p) then
                        task.spawn(flingCharacter, p.Character)
                        task.wait(0.1)
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if Config.FlingSheriffDuringRound and State.RoundState == "Active" then
            local _, s = getRolePlayers()
            if s and s.Character and isAlive(s) then
                task.spawn(flingCharacter, s.Character)
            end
        end
    end
end)

-- round watcher: round is Active while LP is spawned inside an active map zone
task.spawn(function()
    while true do
        task.wait(1)
        local myRoot = getHRP(LP)
        local map = getActiveMap()
        local wasActive = State.RoundState == "Active"
        local isActive = false
        if map and myRoot then
            local spawns = map:FindFirstChild("Spawns")
            local anchor = spawns and spawns:FindFirstChildWhichIsA("BasePart")
            if anchor and (anchor.Position - myRoot.Position).Magnitude < 400 then
                isActive = true
            end
        end
        State.RoundState = isActive and "Active" or "Waiting"
        if not isActive and wasActive then
            State.ShotThisRound = false
            if Config.RoundNotifs then notify("Round Over", "Round ended — back to lobby.", 3) end
        end
    end
end)

-- kill feed: humanoid deaths
activeConnections[#activeConnections + 1] = Players.PlayerAdded:Connect(function(p)
    activeConnections[#activeConnections + 1] = p.CharacterAdded:Connect(function(ch)
        local hum = ch:WaitForChild("Humanoid", 10)
        if hum then
            hum.Died:Connect(function()
                local m = select(1, getRolePlayers())
                killFeed(p.Name .. " died. Murderer (last known): " .. (m and m.Name or "unknown"))
            end)
        end
    end)
end)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        activeConnections[#activeConnections + 1] = p.CharacterAdded:Connect(function(ch)
            local hum = ch:WaitForChild("Humanoid", 10)
            if hum then
                hum.Died:Connect(function()
                    killFeed(p.Name .. " died.")
                end)
            end
        end)
    end
end

-- sheriff death → grab gun
task.spawn(function()
    while true do
        task.wait(1)
        if Config.AutoGrabOnSheriffDeath then
            local _, s = getRolePlayers()
            if not s and State.LastSheriff and tick() - (State.LastSheriffTime or 0) < 1 then
                local gd = getGunDrop()
                local gp = getGunDropPart(gd)
                local myRoot = getHRP(LP)
                if gp and myRoot then
                    myRoot.CFrame = gp.CFrame * CFrame.new(0, 2, 0)
                    interactWithGunDrop(gp, gd)
                end
            end
            if s then State.LastSheriff, State.LastSheriffTime = s.UserId, nil end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(0.5)
        local _, s = getRolePlayers()
        if s then
            State.LastSheriff = s.Name
            State.LastSheriffAliveTick = tick()
        end
        if Config.AutoGrabOnSheriffDeath and State.LastSheriff and s == nil
            and State.LastSheriffAliveTick and tick() - State.LastSheriffAliveTick < 2 then
            local gd = getGunDrop()
            local gp = getGunDropPart(gd)
            local myRoot = getHRP(LP)
            if gp and myRoot then
                myRoot.CFrame = gp.CFrame * CFrame.new(0, 2, 0)
                interactWithGunDrop(gp, gd)
            end
        end
    end
end)

----------------------------------------------------------------
-- UNLOAD
----------------------------------------------------------------

getgenv().RiadHub_Unload = function()
    State.SilentAimHookActive = false
    for _, conn in ipairs(activeConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(activeConnections)
    clearCategory(State.Highlights)
    clearCategory(State.Boxes)
    clearCategory(State.Tracers)
    clearCategory(State.ItemHighlights)
    if State.AuraRing then State.AuraRing:Destroy() end
    if State.FOVCircle then pcall(function() State.FOVCircle:Remove() end) end
    if State.flyBV then State.flyBV:Destroy() end
    for part, sz in pairs(State.OriginalHitboxSizes) do
        if part and part.Parent then part.Size = sz part.Transparency = 1 end
    end
    for k, v in pairs(State.OriginalLighting) do Lighting[k] = v end
    espFolder:Destroy()
    pcall(function() Rayfield:Destroy() end)
end

----------------------------------------------------------------
-- UI — Rayfield Gen2
----------------------------------------------------------------

local Window = Rayfield:CreateWindow({
    name = "Riad Hub",
    loading_title = "Riad Hub v2",
    loading_subtitle = "MM2 refit on Gen2",
    key_system = false,
})

local HomeTab     = Window:CreateTab({ name = "Home" })
local VisualTab   = Window:CreateTab({ name = "Visuals" })
local CombatTab   = Window:CreateTab({ name = "Combat" })
local MoveTab     = Window:CreateTab({ name = "Movement" })
local FarmTab     = Window:CreateTab({ name = "Farm" })
local SurvTab     = Window:CreateTab({ name = "Survival" })
local TPTab       = Window:CreateTab({ name = "Teleports" })
local TrollTab    = Window:CreateTab({ name = "Trolling" })
local MiscTab     = Window:CreateTab({ name = "Misc" })

-- toggles/sliders/dropdowns: flag == Config key, so sync + Gen2 persistence both work
local function T(tab, name, flag, default, cb)
    tab:CreateToggle({
        name = name, flag = flag, default = default or false,
        callback = function(v)
            Config[flag] = v
            if flag == "Fullbright" or flag == "NoFog" then applyVisualWorld() end
            if flag == "FPSBoost" or flag == "DisableParticles" then fpsBoostPass() end
            if cb then cb(v) end
        end,
    })
end

local function S(tab, name, flag, min, max, default, suffix, cb)
    tab:CreateSlider({
        name = name, flag = flag, range = {min, max}, increment = 1,
        default = default, suffix = suffix or "",
        callback = function(v)
            Config[flag] = v
            if cb then cb(v) end
        end,
    })
end

local function D(tab, name, flag, options, default, cb)
    tab:CreateDropdown({
        name = name, flag = flag, options = options, default = default,
        callback = function(v)
            Config[flag] = v
            if cb then cb(v) end
        end,
    })
end

local function B(tab, name, cb)
    tab:CreateButton({ name = name, callback = cb })
end

------------------------------------------------------------ Home

HomeTab:CreateText({ text = "Riad Hub v2 — all systems live. Toggle key: Right Ctrl (set in Settings)." })
HomeTab:CreateDivider()

local statRole    = HomeTab:CreateStat({ name = "Your Role",    flag = "StatRole" })
local statMur     = HomeTab:CreateStat({ name = "Murderer",     flag = "StatMurderer" })
local statSher    = HomeTab:CreateStat({ name = "Sheriff",      flag = "StatSheriff" })
local statRound   = HomeTab:CreateStat({ name = "Round",        flag = "StatRound" })
local statFPS     = HomeTab:CreateStat({ name = "FPS",          flag = "StatFPS" })
local statPing    = HomeTab:CreateStat({ name = "Ping",         flag = "StatPing" })

task.spawn(function()
    while true do
        task.wait(0.5)
        local m, s = getRolePlayers()
        local role = getRole(LP)
        pcall(function()
            Window:Set("StatRole", role)
            Window:Set("StatMurderer", m and m.Name or "unknown")
            Window:Set("StatSheriff", s and s.Name or "unknown")
            Window:Set("StatRound", State.RoundState)
        end)
        local start = tick()
        RunService.RenderStepped:Wait()
        local frameTime = tick() - start
        pcall(function()
            Window:Set("StatFPS", math.floor(1 / math.max(frameTime, 1e-4)))
            Window:Set("StatPing", LP:GetNetworkPing() * 1000 // 1)
        end)
    end
end)

HomeTab:CreateDivider()
B(HomeTab, "Test Notification", function() notify("Riad Hub", "Notifications working.", 3) end)
B(HomeTab, "Announce Roles (chat)", function()
    local m, s = getRolePlayers()
    local msg = "[Riad] Murderer: " .. (m and m.Name or "?") .. " | Sheriff: " .. (s and s.Name or "?")
    local tcs = game:GetService("TextChatService")
    local ch = tcs:FindFirstChild("TextChannels") and tcs.TextChannels:FindFirstChild("RBXGeneral")
    if ch then ch:SendAsync(msg) end
end)
B(HomeTab, "Reset Character", function()
    local h = getHumanoid(LP)
    if h then h.Health = 0 end
end)
B(HomeTab, "Unload Hub", function() getgenv().RiadHub_Unload() end)

------------------------------------------------------------ Visuals

T(VisualTab, "Role ESP", "RoleESP")
T(VisualTab, "ESP Chams", "ESPChams")
T(VisualTab, "ESP Boxes", "ESPBoxes")
T(VisualTab, "ESP Names", "ESPNames", true)
T(VisualTab, "ESP Distance", "ESPDistance", true)
T(VisualTab, "ESP Health", "ESPHealth")
T(VisualTab, "ESP Tracers", "ESPTracers")
S(VisualTab, "ESP Max Distance", "ESPDistanceMax", 50, 2000, 600, " studs")
T(VisualTab, "Dropped Gun ESP", "GunESP")
T(VisualTab, "Coin ESP", "CoinESP")
T(VisualTab, "Fullbright", "Fullbright")
T(VisualTab, "No Fog", "NoFog")
T(VisualTab, "Disable Particles", "DisableParticles")
T(VisualTab, "FPS Boost (strip textures)", "FPSBoost")
B(VisualTab, "Re-apply Visual Pass", fpsBoostPass)

------------------------------------------------------------ Combat

T(CombatTab, "Aimbot", "Aimbot")
T(CombatTab, "Auto-Shoot", "AutoShoot")
T(CombatTab, "Silent Aim", "SilentAim")
T(CombatTab, "Aim Prediction", "AimPrediction", true)
T(CombatTab, "Ping Compensation", "PingComp", true)
T(CombatTab, "Single Shot Lock", "SingleShot")
T(CombatTab, "Auto Equip Gun", "AutoEquipGun", true)
T(CombatTab, "Full Gun Grabber", "GrabGunAuto")
S(CombatTab, "Gun Grab Distance", "GunGrabDist", 20, 800, 300, " studs")
T(CombatTab, "Grab Gun on Sheriff Death", "AutoGrabOnSheriffDeath")
T(CombatTab, "Show FOV Circle", "ShowFOV")
S(CombatTab, "FOV Radius", "FOVRadius", 50, 700, 160, "")
B(CombatTab, "Pick Up Gun Once", function()
    local gd = getGunDrop()
    local gp = getGunDropPart(gd)
    if gp then interactWithGunDrop(gp, gd) notify("Riad Hub", "Attempted gun pickup.", 2)
    else notify("Riad Hub", "No gun on map.", 2) end
end)

CombatTab:CreateDivider()
T(CombatTab, "Auto-Stab", "AutoStab")
T(CombatTab, "Kill Aura", "KillAura")
T(CombatTab, "Auto Kill Innocents", "AutoKill")
D(CombatTab, "Kill Mode", "KillMode", {"Legit", "Blatant", "Throw"}, "Legit")
T(CombatTab, "Knife Silent Aim", "KnifeSilentAim", true)
S(CombatTab, "Aura Range", "AuraRange", 5, 45, 15, " studs")
T(CombatTab, "Show Aura Ring", "ShowAuraRing")
T(CombatTab, "Auto Equip Knife", "AutoEquipKnife", true)
T(CombatTab, "Proximity Knife", "ProximityKnife", true)
S(CombatTab, "Knife Proximity Distance", "KnifeProxDist", 5, 40, 18, " studs")
B(CombatTab, "Kill All (Murderer Only)", function()
    local knife = equipTool("Knife")
    if not knife then notify("Riad Hub", "You need the knife equipped.", 3) return end
    local myHRP = getHRP(LP)
    if not myHRP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local hrp = getHRP(p)
            if hrp then
                myHRP.CFrame = hrp.CFrame
                task.wait(0.05)
                knife:Activate()
                task.wait(0.05)
            end
        end
    end
end)

CombatTab:CreateDivider()
T(CombatTab, "Hitbox Expander", "HitboxExpander")
S(CombatTab, "Hitbox Size", "HitboxSize", 4, 30, 10, " studs")
S(CombatTab, "Hitbox Transparency %", "HitboxTransparencyPct", 0, 100, 60, "%", function(v)
    Config.HitboxTransparency = v / 100
end)

------------------------------------------------------------ Movement

T(MoveTab, "Speed Boost", "Speed")
S(MoveTab, "Walk Speed", "SpeedValue", 16, 60, 24, "")
T(MoveTab, "Jump Boost", "JumpEnabled")
S(MoveTab, "Jump Power", "JumpValue", 50, 150, 50, "")
T(MoveTab, "Infinite Jump", "InfiniteJump")
T(MoveTab, "Noclip", "Noclip")
T(MoveTab, "Fly (WASD + Space/Shift)", "Fly")
S(MoveTab, "Fly Speed", "FlySpeed", 15, 150, 35, " studs/s")
T(MoveTab, "Anti-Ragdoll", "AntiRagdoll")
T(MoveTab, "Anti-Fling", "AntiFling", true)
T(MoveTab, "Anti-Void", "AntiVoid", true)
T(MoveTab, "Anti-AFK", "AntiAFK", true)
MoveTab:CreateKeybind({
    name = "Click-TP Modifier",
    default = Enum.KeyCode.LeftAlt,
    callback = function() end, -- click-tp reads LeftAlt directly; rebind target kept simple
})

------------------------------------------------------------ Farm

T(FarmTab, "Auto Farm Coins", "CoinFarm")
D(FarmTab, "Farm Method", "FarmMethod", {"Teleport", "Glide", "Tween", "Walk"}, "Teleport")
S(FarmTab, "Farm Speed (walk/tween)", "FarmSpeed", 16, 60, 28, "")
S(FarmTab, "Teleport Delay (x0.01s)", "TeleportFarmDelayV", 1, 50, 5, "", function(v)
    Config.TeleportFarmDelay = v / 100
end)
T(FarmTab, "Safe Farming (pause near murderer)", "SafeCoinFarm", true)
T(FarmTab, "Bag Full Stop", "BagFullStop", true)
S(FarmTab, "Coin Bag Cap", "CoinBagCap", 10, 40, 40, "")
T(FarmTab, "Coin Magnet (touch-grab)", "CoinMagnet")
S(FarmTab, "Magnet Radius", "MagnetRadius", 10, 200, 60, " studs")

------------------------------------------------------------ Survival

T(SurvTab, "Murderer Avoidance", "MurdererAvoid")
S(SurvTab, "Safety Radius", "SafetyRadius", 20, 80, 40, " studs")
T(SurvTab, "Retreat to Lobby", "RetreatToLobby")
T(SurvTab, "Proximity Alert", "ProximityAlert", true)
T(SurvTab, "Sprint When Chased", "SprintWhenChased", true)
T(SurvTab, "Follow Murderer", "FollowMurderer")
S(SurvTab, "Follow Distance", "FollowDist", 8, 40, 18, " studs")
T(SurvTab, "Role-Based Auto Play", "AutoPlay")

------------------------------------------------------------ Teleports

local function tpToPlayer(p, label)
    local myRoot = getHRP(LP)
    local pr = p and getHRP(p)
    if myRoot and pr then
        myRoot.CFrame = pr.CFrame * CFrame.new(0, 0, 4)
        notify("Riad Hub", "Teleported to " .. (label or p.Name), 2)
        return true
    end
    return false
end

B(Teleports_TPTab or TPTab, "Teleport to Murderer", function()
    local m = select(1, getRolePlayers())
    if not tpToPlayer(m) then notify("Riad Hub", "Murderer not found.", 2) end
end)
B(TPTab, "Teleport to Sheriff", function()
    local _, s = getRolePlayers()
    if not tpToPlayer(s) then notify("Riad Hub", "Sheriff not found.", 2) end
end)
B(TPTab, "Teleport to Active Map", function()
    local map = getActiveMap()
    local myRoot = getHRP(LP)
    local sp = map and map:FindFirstChild("Spawns")
    local first = sp and sp:FindFirstChildWhichIsA("BasePart")
    if first and myRoot then
        myRoot.CFrame = first.CFrame * CFrame.new(0, 3, 0)
        notify("Riad Hub", "Teleported to " .. map.Name, 2)
    else
        notify("Riad Hub", "No active map.", 2)
    end
end)
B(TPTab, "Teleport to Lobby", function()
    local lb = getLobbyModel()
    local p = lb and lb:FindFirstChildWhichIsA("BasePart")
    local myRoot = getHRP(LP)
    if p and myRoot then myRoot.CFrame = p.CFrame * CFrame.new(0, 4, 0) end
end)
B(TPTab, "Teleport to Dropped Gun", function()
    local gp = getGunDropPart(getGunDrop())
    local myRoot = getHRP(LP)
    if gp and myRoot then
        myRoot.CFrame = gp.CFrame * CFrame.new(0, 3, 0)
    else
        notify("Riad Hub", "No gun on map.", 2)
    end
end)

local slot1CF, slot2CF = nil, nil
local slotFile = "RiadHub_slots.json"
pcall(function()
    if isfile and isfile(slotFile) then
        local data = HttpService:JSONDecode(readfile(slotFile))
        if data.s1 then slot1CF = CFrame.new(unpack(data.s1)) end
        if data.s2 then slot2CF = CFrame.new(unpack(data.s2)) end
    end
end)
local function saveSlots()
    pcall(function()
        if writefile then
            writefile(slotFile, HttpService:JSONEncode({
                s1 = slot1CF and {slot1CF:GetComponents()} or nil,
                s2 = slot2CF and {slot2CF:GetComponents()} or nil,
            }))
        end
    end)
end
B(TPTab, "Save Slot 1", function()
    local r = getHRP(LP)
    if r then slot1CF = r.CFrame saveSlots() notify("Riad Hub", "Slot 1 saved.", 2) end
end)
B(TPTab, "Go To Slot 1", function()
    local r = getHRP(LP)
    if r and slot1CF then r.CFrame = slot1CF else notify("Riad Hub", "No Slot 1 saved.", 2) end
end)
B(TPTab, "Save Slot 2", function()
    local r = getHRP(LP)
    if r then slot2CF = r.CFrame saveSlots() notify("Riad Hub", "Slot 2 saved.", 2) end
end)
B(TPTab, "Go To Slot 2", function()
    local r = getHRP(LP)
    if r and slot2CF then r.CFrame = slot2CF else notify("Riad Hub", "No Slot 2 saved.", 2) end
end)

------------------------------------------------------------ Trolling

D(TrollTab, "Fling Style", "FlingStyle", {"Torque", "Velocity", "Orbit"}, "Torque")
B(TrollTab, "Fling Murderer", function()
    local m = select(1, getRolePlayers())
    if m and m.Character then
        notify("Riad Hub", "Flinging " .. m.Name .. "...", 2)
        task.spawn(flingCharacter, m.Character)
    else
        notify("Riad Hub", "Murderer not found.", 2)
    end
end)
B(TrollTab, "Fling Sheriff", function()
    local _, s = getRolePlayers()
    if s and s.Character then
        notify("Riad Hub", "Flinging " .. s.Name .. "...", 2)
        task.spawn(flingCharacter, s.Character)
    else
        notify("Riad Hub", "Sheriff not found.", 2)
    end
end)
TrollTab:CreateText({ text = "Warning: all pre-round fling toggles are DETECTED." })
T(TrollTab, "Fling Murderer (Pre-Round)", "FlingMurdererPreRound")
T(TrollTab, "Fling Sheriff (Pre-Round)", "FlingSheriffPreRound")
T(TrollTab, "Fling Hero (Pre-Round)", "FlingHeroPreRound")
T(TrollTab, "Fling ALL Players (Pre-Round)", "FlingAllPreRound")
T(TrollTab, "Fling Sheriff During Round", "FlingSheriffDuringRound")

------------------------------------------------------------ Misc

T(MiscTab, "Kill Feed Notifications", "KillFeed", true)
T(MiscTab, "Round End Notifications", "RoundNotifs", true)
B(MiscTab, "Rejoin Server", function()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end)
end)
B(MiscTab, "Server Hop (random public)", function()
    task.spawn(function()
        local ok, servers = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            ))
        end)
        if ok and servers and servers.data and #servers.data > 0 then
            local candidates = {}
            for _, srv in ipairs(servers.data) do
                if srv.id ~= game.JobId and srv.playing and srv.maxPlayers and srv.playing < srv.maxPlayers then
                    table.insert(candidates, srv.id)
                end
            end
            if #candidates > 0 then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, candidates[math.random(#candidates)], LP)
            else
                notify("Riad Hub", "No other servers found.", 3)
            end
        else
            notify("Riad Hub", "Server list fetch failed.", 3)
        end
    end)
end)

local playersForSpectate = {}
local function refreshPlayerList()
    table.clear(playersForSpectate)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(playersForSpectate, p.Name) end
    end
    return playersForSpectate
end

local spectateDD = MiscTab:CreateDropdown({
    name = "Spectate Player",
    flag = "SpectateTarget",
    options = refreshPlayerList(),
    callback = function(name)
        local target = Players:FindFirstChild(name)
        local hum = target and getHumanoid(target)
        if hum then
            Camera.CameraSubject = hum
            State.Spectating = name
        end
    end,
})
B(MiscTab, "Refresh Player List", function()
    pcall(function()
        Window:Set("SpectateTarget", nil)
    end)
    spectateDD:Refresh and spectateDD:Refresh(refreshPlayerList())
end)
B(MiscTab, "Stop Spectating", function()
    local h = getHumanoid(LP)
    if h then Camera.CameraSubject = h end
    State.Spectating = nil
end)

------------------------------------------------------------
-- sync Gen2 persisted flags into Config (one documented Get pass)
------------------------------------------------------------

task.spawn(function()
    task.wait(1)
    for k, _ in pairs(Config) do
        local ok, v = pcall(function() return Window:Get(k) end)
        if ok and v ~= nil then Config[k] = v end
    end
    -- percentage slider drives HitboxTransparency
    local okPct, pct = pcall(function() return Window:Get("HitboxTransparencyPct") end)
    if okPct and pct then Config.HitboxTransparency = pct / 100 end
    local okDelay, dv = pcall(function() return Window:Get("TeleportFarmDelayV") end)
    if okDelay and dv then Config.TeleportFarmDelay = dv / 100 end
    applyVisualWorld()
    notify("Riad Hub", "Riad Hub v2 loaded. Right Ctrl to toggle.", 4)
end)
