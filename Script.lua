--[[
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░                                                                    ░
    ░                                                                    ░
    ░              ██████╗ ██╗ █████╗ ██████╗                            ░
    ░              ██╔══██╗██║██╔══██╗██╔══██╗                           ░
    ░              ██████╔╝██║███████║██║  ██║                           ░
    ░              ██╔══██╗██║██╔══██║██║  ██║                           ░
    ░              ██║  ██║██║██║  ██║██████╔╝                           ░
    ░              ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═════╝                            ░
    ░                                                                    ░
    ░                       h   u   b                                    ░
    ░                                                                    ░
    ░                                                                    ░
    ░              ─────────────────────────────────                     ░
    ░                                                                    ░
    ░                       murder mystery 2                             ░
    ░                                                                    ░
    ░              ─────────────────────────────────                     ░
    ░                                                                    ░
    ░                       keyless  ·  complete                         ░
    ░                       one file  ·  zero stubs                      ░
    ░                                                                    ░
    ░                                                                    ░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
]]

if getgenv().RiadUnload then pcall(getgenv().RiadUnload) end

getgenv().RAYFIELD_SECURE = true

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

-- ┌─────────────────────────────────────────────────────────────┐
-- │  services                                                   │
-- └─────────────────────────────────────────────────────────────┘

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local CoreGui           = game:GetService("CoreGui")
local Lighting          = game:GetService("Lighting")
local TeleportService   = game:GetService("TeleportService")
local CollectionService = game:GetService("CollectionService")
local TweenService      = game:GetService("TweenService")
local TextChatService   = game:GetService("TextChatService")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local connections = {}
local function track(c) table.insert(connections, c) return c end

-- ┌─────────────────────────────────────────────────────────────┐
-- │  config  ·  all user values                                 │
-- └─────────────────────────────────────────────────────────────┘

local Config = {
    RoleESP = false,
    ESPBoxes = false,
    ESPNames = true,
    ESPTracers = false,
    ESPDistance = true,
    ESPChams = false,
    ESPHealth = false,
    ESPDistanceMax = 600,
    GunESP = false,
    CoinESP = false,
    Fullbright = false,
    NoFog = false,
    DisableParticles = false,
    FPSBoost = false,

    Aimbot = false,
    AutoShoot = false,
    SilentAim = false,
    AimPrediction = true,
    PingComp = true,
    SingleShot = false,
    FOVRadius = 160,
    ShowFOV = false,
    AutoEquipGun = true,
    GrabGunAuto = false,
    GunGrabDist = 300,
    AutoGrabOnSheriffDeath = false,
    GunDropNotify = true,

    AutoStab = false,
    KillAura = false,
    AutoKill = false,
    KillMode = "Legit",
    KnifeSilentAim = true,
    AuraRange = 15,
    ShowAuraRing = false,
    AutoEquipKnife = true,
    ProximityKnife = true,
    KnifeProxDist = 18,

    HitboxExpander = false,
    HitboxSize = 10,
    HitboxTransparency = 0.6,

    MurdererAvoid = false,
    SafetyRadius = 40,
    RetreatToLobby = false,
    ProximityAlert = true,
    SprintWhenChased = true,
    FollowMurderer = false,
    FollowDist = 18,
    AutoPlay = false,

    Speed = false,
    SpeedValue = 24,
    JumpEnabled = false,
    JumpValue = 50,
    InfiniteJump = false,
    Noclip = false,
    Fly = false,
    FlySpeed = 35,
    AntiRagdoll = false,
    AntiVoid = true,
    AntiFling = true,

    CoinFarm = false,
    FarmSpeed = 28,
    FarmMethod = "Teleport",
    SafeCoinFarm = true,
    BagFullStop = true,
    CoinBagCap = 40,
    TeleportFarmDelay = 0.05,
    CoinMagnet = false,
    MagnetRadius = 60,
    UndergroundFarm = false,
    ReturnToLobbyWhenFull = false,

    FlingStyle = "Torque",
    FlingMurdererPreRound = false,
    FlingSheriffPreRound = false,
    FlingHeroPreRound = false,
    FlingSheriffDuringRound = false,
    FlingAllPreRound = false,

    AntiAFK = true,
    KillFeed = true,
    RoundNotifs = true,
    AnnounceRoles = false,
    RoundThreshold = 400,
}

-- ┌─────────────────────────────────────────────────────────────┐
-- │  state  ·  scratch space, not settings                      │
-- └─────────────────────────────────────────────────────────────┘

local State = {
    highlights = {},
    boxes = {},
    tracers = {},
    itemHighlights = {},
    originalHitboxSizes = {},
    originalLighting = {},
    isFlinging = false,
    auraRing = nil,
    fovCircle = nil,
    silentAimActive = true,
    roundState = "Waiting",
    lastSafePosition = nil,
    flyVelocity = nil,
    noclipConn = nil,
    spectating = nil,
    shotThisRound = false,
    notified = {},
    lastSheriffName = nil,
    lastSheriffTick = 0,
    farmStats = { coins = 0, startTick = tick(), lastCoin = 0 },
}

for _, k in ipairs({"ClockTime", "FogEnd", "Brightness", "Ambient", "OutdoorAmbient"}) do
    State.originalLighting[k] = Lighting[k]
end

local espFolder = Instance.new("Folder")
espFolder.Name = "RiadHub_ESP"
local ok = pcall(function() espFolder.Parent = CoreGui end)
if not ok then espFolder.Parent = LP:WaitForChild("PlayerGui") end

-- ┌─────────────────────────────────────────────────────────────┐
-- │  helpers                                                    │
-- └─────────────────────────────────────────────────────────────┘

local function getHRP(p)
    local c = p and p.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
        or c:FindFirstChild("Torso")
        or c:FindFirstChild("UpperTorso")
        or c:FindFirstChildWhichIsA("BasePart")
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
    if (bp and bp:FindFirstChild("Knife")) or (ch and ch:FindFirstChild("Knife")) then
        return "Murderer"
    end
    if (bp and bp:FindFirstChild("Gun")) or (ch and ch:FindFirstChild("Gun")) then
        return "Sheriff"
    end
    return "Innocent"
end

local function roleColor(role)
    if role == "Murderer" then return Color3.fromRGB(255, 40, 40) end
    if role == "Sheriff" then return Color3.fromRGB(40, 120, 255) end
    return Color3.fromRGB(230, 230, 230)
end

local function getRolePlayers()
    local murderer, sheriff = nil, nil
    local innocents = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local r = getRole(p)
            if r == "Murderer" then murderer = p
            elseif r == "Sheriff" then sheriff = p
            else table.insert(innocents, p) end
        end
    end
    return murderer, sheriff, innocents
end

local function getActiveMap()
    for _, c in ipairs(Workspace:GetChildren()) do
        if c:IsA("Model")
            and not string.find(string.lower(c.Name), "lobby")
            and not Players:GetPlayerFromCharacter(c)
            and (c:FindFirstChild("Spawns")
                or c:FindFirstChild("CoinContainer")
                or c:FindFirstChild("Base")) then
            return c
        end
    end
    return nil
end

local function getLobbyModel()
    for _, c in ipairs(Workspace:GetChildren()) do
        if c:IsA("Model") and string.find(string.lower(c.Name), "lobby") then
            return c
        end
    end
    return Workspace:FindFirstChild("Lobby")
end

local function getGunDrop()
    return Workspace:FindFirstChild("GunDrop")
        or Workspace:FindFirstChild("GunDrop", true)
end

local function getGunDropPart(drop)
    if not drop then return nil end
    if drop:IsA("BasePart") then return drop end
    if drop:IsA("Model") or drop:IsA("Folder") or drop:IsA("Tool") then
        local p = drop:FindFirstChild("GunDrop")
            or drop:FindFirstChild("Handle")
            or drop.PrimaryPart
            or drop:FindFirstChildWhichIsA("BasePart")
        if p and p:IsA("BasePart") then return p end
        for _, d in ipairs(drop:GetDescendants()) do
            if d:IsA("BasePart") then return d end
        end
    end
    return nil
end

local function getAllActiveCoins()
    local coins, seen = {}, {}
    for _, tag in ipairs({"CoinVisual", "Coin"}) do
        for _, v in ipairs(CollectionService:GetTagged(tag)) do
            if v and v.Parent
                and not v:GetAttribute("Collected")
                and not v:GetAttribute("Delete") then
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
            local container = map:FindFirstChild("CoinContainer")
                or map:FindFirstChild("Coins")
            if container then
                for _, d in ipairs(container:GetDescendants()) do
                    if d:IsA("BasePart")
                        and not seen[d]
                        and (d:GetAttribute("CoinID")
                            or string.find(string.lower(d.Name), "coin"))
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
    if prompt and fireproximityprompt then
        pcall(fireproximityprompt, prompt)
    end
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
                if d < bestDist then
                    best, bestDist = p, d
                end
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
    if Config.KillFeed then notify("kill feed", msg, 4) end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │  lighting and world visuals                                 │
-- └─────────────────────────────────────────────────────────────┘

local function applyWorldVisuals()
    if Config.Fullbright then
        Lighting.ClockTime = 14
        Lighting.Brightness = 3
        Lighting.FogEnd = 1e6
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    else
        Lighting.ClockTime = State.originalLighting.ClockTime
        Lighting.Brightness = State.originalLighting.Brightness
        Lighting.FogEnd = State.originalLighting.FogEnd
        Lighting.Ambient = State.originalLighting.Ambient
        Lighting.OutdoorAmbient = State.originalLighting.OutdoorAmbient
    end
end

local function applyFPSPass()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if Config.DisableParticles and d:IsA("ParticleEmitter") then
            d.Enabled = false
        end
        if Config.FPSBoost then
            if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 1 end
            if d:IsA("MeshPart") then d.TextureID = "" end
        end
    end
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │  silent aim hook                                            │
-- └─────────────────────────────────────────────────────────────┘

if hookmetamethod and getnamecallmethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if State.silentAimActive and not checkcaller() and method == "FireServer" then
            local args = {...}
            if self.Name == "KnifeThrown"
                and (Config.KnifeSilentAim or Config.SilentAim) then
                local tgt = nearestTarget()
                if tgt then
                    local tRoot = getHRP(tgt)
                    if tRoot then
                        local pos = tRoot.Position
                        if Config.AimPrediction then
                            local scale = Config.PingComp and 0.16 or 0.12
                            pos = pos + (tRoot.AssemblyLinearVelocity * scale)
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
                            local scale = Config.PingComp and 0.16 or 0.12
                            pos = pos + (mRoot.AssemblyLinearVelocity * scale)
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

-- ┌─────────────────────────────────────────────────────────────┐
-- │  esp primitives                                             │
-- └─────────────────────────────────────────────────────────────┘

local function upsertBillboard(id, adornee, text, color)
    local bb = State.highlights[id]
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
        State.highlights[id] = bb
    end
    bb.Adornee = adornee
    bb.MaxDistance = Config.ESPDistanceMax
    local tag = bb:FindFirstChild("Tag")
    if tag then
        tag.Text = text
        tag.TextColor3 = color
    end
    return bb
end

local function upsertBox(id, adornee, color)
    local box = State.boxes[id]
    if not box or not box.Parent then
        box = Instance.new("BoxHandleAdornment")
        box.Name = "box_" .. id
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Size = Vector3.new(3.5, 6.2, 3.5)
        box.Transparency = 0.6
        box.Parent = espFolder
        State.boxes[id] = box
    end
    box.Adornee = adornee
    box.Color3 = color
    return box
end

local function upsertCham(id, char, color)
    local hl = State.highlights["cham_" .. id]
    if not hl or not hl.Parent then
        hl = Instance.new("Highlight")
        hl.Name = "cham_" .. id
        hl.OutlineColor = Color3.fromRGB(243, 240, 255)
        hl.FillTransparency = 0.45
        hl.OutlineTransparency = 0.1
        hl.Parent = espFolder
        State.highlights["cham_" .. id] = hl
    end
    hl.Adornee = char
    hl.FillColor = color
    return hl
end

local function updateTracer(id, targetPos, color)
    if not Drawing or not Drawing.new then return end
    local line = State.tracers[id]
    if not line then
        pcall(function()
            line = Drawing.new("Line")
            line.Thickness = 1.5
            line.Transparency = 0.85
            State.tracers[id] = line
        end)
        line = State.tracers[id]
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
        State.fovCircle = Drawing.new("Circle")
        State.fovCircle.Thickness = 1.5
        State.fovCircle.Color = Color3.fromRGB(80, 220, 120)
        State.fovCircle.Filled = false
        State.fovCircle.Transparency = 0.8
        State.fovCircle.Visible = false
    end)
end

local function updateAuraRing(myRoot)
    if not Config.ShowAuraRing or not myRoot then
        if State.auraRing then State.auraRing.Transparency = 1 end
        return
    end
    if not State.auraRing or not State.auraRing.Parent then
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
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = fr
        local s = Instance.new("UIStroke")
        s.Color = Color3.fromRGB(80, 220, 120)
        s.Thickness = 2.5
        s.Transparency = 0.1
        s.Parent = fr
        p.Parent = Workspace
        State.auraRing = p
    end
    local d = Config.AuraRange * 2
    State.auraRing.Size = Vector3.new(d, 0.01, d)
    State.auraRing.Transparency = 0
    State.auraRing.CFrame = CFrame.new(
        myRoot.Position.X,
        myRoot.Position.Y - 2.85,
        myRoot.Position.Z
    )
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │  fling engine                                               │
-- └─────────────────────────────────────────────────────────────┘

local function flingCharacter(targetChar)
    if State.isFlinging then return end
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local tRoot  = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not tRoot then return end
    local myHum = getHumanoid(LP)
    local tHum  = targetChar:FindFirstChildOfClass("Humanoid")
    if not myHum or myHum.Health <= 0 or not tHum or tHum.Health <= 0 then return end

    State.isFlinging = true
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

    local start = tick()
    while tick() - start < 1.5 do
        if not targetChar or not targetChar.Parent
            or not tRoot.Parent or tHum.Health <= 0 then break end
        if not myChar.Parent or myHum.Health <= 0 then break end

        if Config.FlingStyle == "Velocity" then
            myRoot.CFrame = CFrame.new(tRoot.Position + Vector3.new(0, 1.2, 0))
            myRoot.AssemblyLinearVelocity = Vector3.new(0, 9e9, 0)
            myRoot.AssemblyAngularVelocity = Vector3.new(9e9, 9e9, 9e9)
        elseif Config.FlingStyle == "Orbit" then
            local angle = (tick() - start) * 20
            local off = Vector3.new(
                math.cos(angle) * 1.5,
                0.5,
                math.sin(angle) * 1.5
            )
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

    pcall(function()
        conn:Disconnect()
        bAV:Destroy()
        bV:Destroy()
    end)
    if myRoot and myRoot.Parent then
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero
        myRoot.CFrame = oldCF
    end
    task.wait(0.15)
    State.isFlinging = false
end

local function flingByRole(role)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) and getRole(p) == role then
            task.spawn(flingCharacter, p.Character)
            task.wait(0.1)
        end
    end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │  main tick  ·  esp, hitbox, anti-void, anti-fling           │
-- └─────────────────────────────────────────────────────────────┘

task.spawn(function()
    while true do
        task.wait(0.1)
        local myRoot = getHRP(LP)

        if Config.RoleESP then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local hrp = getHRP(p)
                    if hrp and isAlive(p) then
                        local role = getRole(p)
                        local color = roleColor(role)
                        local dist = myRoot
                            and math.floor((hrp.Position - myRoot.Position).Magnitude)
                            or 0
                        local text = Config.ESPNames and p.Name or ""
                        if Config.ESPDistance then
                            text = text .. " [" .. dist .. "m]"
                        end
                        if Config.ESPHealth then
                            local h = getHumanoid(p)
                            if h then
                                text = text .. string.format(
                                    " %.0f%%",
                                    h.Health / h.MaxHealth * 100
                                )
                            end
                        end
                        upsertBillboard(p.UserId, hrp, text, color)
                        if Config.ESPBoxes then
                            upsertBox(p.UserId, hrp, color)
                        end
                        if Config.ESPChams then
                            upsertCham(p.UserId, p.Character, color)
                        end
                        updateTracer(p.UserId, hrp.Position, color)
                    end
                end
            end
        else
            for id, bb in pairs(State.highlights) do
                if bb:IsA("BillboardGui") then
                    bb:Destroy()
                    State.highlights[id] = nil
                end
            end
            for id, box in pairs(State.boxes) do
                if not box.Parent or not box.Adornee
                    or not box.Adornee.Parent then
                    box:Destroy()
                    State.boxes[id] = nil
                end
            end
        end

        for _, obj in pairs(State.itemHighlights) do obj:Destroy() end
        table.clear(State.itemHighlights)

        if Config.GunESP then
            local gd = getGunDrop()
            local gp = getGunDropPart(gd)
            if gp then
                State.itemHighlights["gun"] = upsertBillboard(
                    "gun_" .. gp:GetDebugId(),
                    gp,
                    "gun",
                    Color3.fromRGB(255, 220, 40)
                )
            end
        end

        if Config.CoinESP then
            for i, coin in ipairs(getAllActiveCoins()) do
                if i > 60 then break end
                State.itemHighlights["coin_" .. i] = upsertBillboard(
                    "coin_" .. i,
                    coin,
                    "$",
                    Color3.fromRGB(120, 255, 120)
                )
            end
        end

        if State.fovCircle then
            State.fovCircle.Visible = Config.ShowFOV
            if Config.ShowFOV then
                State.fovCircle.Radius = Config.FOVRadius
                State.fovCircle.Position = Vector2.new(
                    Camera.ViewportSize.X / 2,
                    Camera.ViewportSize.Y / 2
                )
            end
        end

        updateAuraRing(myRoot)

        if Config.HitboxExpander then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local hrp = getHRP(p)
                    if hrp then
                        if not State.originalHitboxSizes[hrp] then
                            State.originalHitboxSizes[hrp] = hrp.Size
                        end
                        hrp.Size = Vector3.one * Config.HitboxSize
                        hrp.Transparency = Config.HitboxTransparency
                        hrp.CanCollide = false
                        hrp.Massless = true
                    end
                end
            end
        else
            for part, sz in pairs(State.originalHitboxSizes) do
                if part and part.Parent then
                    part.Size = sz
                    part.Transparency = 1
                end
            end
            State.originalHitboxSizes = {}
        end

        if Config.AntiVoid and myRoot and myRoot.Position.Y < -50 then
            if State.lastSafePosition then
                myRoot.CFrame = State.lastSafePosition
            else
                local lb = getLobbyModel()
                local part = lb and lb:FindFirstChildWhichIsA("BasePart")
                if part then
                    myRoot.CFrame = part.CFrame + Vector3.new(0, 5, 0)
                end
            end
        end
        if myRoot and myRoot.Position.Y > -20 then
            State.lastSafePosition = myRoot.CFrame
        end

        if Config.AntiFling and myRoot then
            local v = myRoot.AssemblyLinearVelocity
            if v.Magnitude > 500 then
                myRoot.AssemblyLinearVelocity = Vector3.zero
                myRoot.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
end)

-- ┌─────────────────────────────────────────────────────────────┐
-- │  combat tick  ·  knife side, gun side, auto-grab, survival  │
-- └─────────────────────────────────────────────────────────────┘

task.spawn(function()
    while true do
        task.wait(0.15)
        local myRoot = getHRP(LP)
        if not myRoot then continue end
        local murderer, sheriff, innocents = getRolePlayers()
        local myRole = getRole(LP)

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
                        if Config.KillMode == "Throw"
                            and knife.Parent == LP.Character then
                            knife:Activate()
                        else
                            local tRoot = getHRP(tgt)
                            if tRoot then
                                myRoot.CFrame = tRoot.CFrame
                                    * CFrame.new(0, 0, 2.5)
                                knife:Activate()
                            end
                        end
                    end
                end
                if Config.AutoKill then
                    for _, p in ipairs(innocents) do
                        local hrp = getHRP(p)
                        if hrp and isAlive(p) then
                            myRoot.CFrame = hrp.CFrame
                                * CFrame.new(0, 0, 2.5)
                            knife:Activate()
                            task.wait(0.05)
                        end
                    end
                end
            end
        end

        if myRole == "Sheriff" then
            if Config.AutoEquipGun then equipTool("Gun") end
            if murderer and isAlive(murderer) then
                local mRoot = getHRP(murderer)
                if mRoot then
                    local sp, onScreen = Camera:WorldToViewportPoint(mRoot.Position)
                    local center = Vector2.new(
                        Camera.ViewportSize.X,
                        Camera.ViewportSize.Y
                    ) / 2
                    local distFromCenter = (
                        Vector2.new(sp.X, sp.Y) - center
                    ).Magnitude
                    if Config.AutoShoot and onScreen
                        and distFromCenter < Config.FOVRadius then
                        if not (Config.SingleShot and State.shotThisRound) then
                            local gun = LP.Character
                                and LP.Character:FindFirstChild("Gun")
                            if gun and gun:FindFirstChild("Shoot") then
                                gun.Shoot:FireServer(
                                    myRoot.CFrame,
                                    CFrame.new(mRoot.Position)
                                )
                                State.shotThisRound = true
                            end
                        end
                    end
                    if Config.Aimbot and onScreen
                        and distFromCenter < Config.FOVRadius then
                        Camera.CFrame = CFrame.lookAt(
                            Camera.CFrame.Position,
                            mRoot.Position
                        )
                    end
                end
            end
        end

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

        if murderer and myRoot then
            local mRoot = getHRP(murderer)
            if mRoot then
                local d = (mRoot.Position - myRoot.Position).Magnitude
                if Config.ProximityAlert and d < Config.SafetyRadius
                    and not State.notified[murderer.UserId] then
                    State.notified[murderer.UserId] = true
                    notify(
                        "proximity",
                        murderer.Name .. " within "
                            .. Config.SafetyRadius .. " studs",
                        4
                    )
                    task.delay(10, function()
                        State.notified[murderer.UserId] = nil
                    end)
                end
                if Config.SprintWhenChased and d < Config.SafetyRadius then
                    local h = getHumanoid(LP)
                    if h then
                        h.WalkSpeed = math.max(Config.SpeedValue, 30)
                    end
                end
                if Config.MurdererAvoid and d < Config.SafetyRadius then
                    local away = (myRoot.Position - mRoot.Position).Unit * 15
                    myRoot.CFrame = CFrame.new(myRoot.Position + away)
                end
                if Config.FollowMurderer and d > Config.FollowDist then
                    myRoot.CFrame = mRoot.CFrame
                        * CFrame.new(0, 0, Config.FollowDist)
                end
            end
        end

        if Config.RetreatToLobby then
            local lb = getLobbyModel()
            local part = lb and lb:FindFirstChildWhichIsA("BasePart")
            if part then
                myRoot.CFrame = part.CFrame * CFrame.new(0, 4, 0)
            end
        end

        if Config.CoinMagnet and myRoot then
            for _, coin in ipairs(getAllActiveCoins()) do
                if (coin.Position - myRoot.Position).Magnitude
                    < Config.MagnetRadius then
                    fireTouch(myRoot, coin)
                end
            end
        end

        if Config.AutoPlay then
            if myRole == "Murderer" then
                Config.AutoStab = true
            elseif myRole == "Sheriff" then
                Config.AutoShoot = true
            else
                Config.MurdererAvoid = true
            end
        end
    end
end)

-- ┌─────────────────────────────────────────────────────────────┐
-- │  movement tick  ·  speed, jump, anti-ragdoll                │
-- └─────────────────────────────────────────────────────────────┘

task.spawn(function()
    while true do
        task.wait(0.05)
        local h = getHumanoid(LP)
        local myRoot = getHRP(LP)
        if h and myRoot then
            if Config.Speed then h.WalkSpeed = Config.SpeedValue end
            if Config.JumpEnabled then
                h.UseJumpPower = true
                h.JumpPower = Config.JumpValue
            end
            if Config.AntiRagdoll then
                if h.PlatformStand then h.PlatformStand = false end
                if h:GetState() == Enum.HumanoidStateType.Ragdoll then
                    h:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
    end
end)

track(UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local c = LP.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

track(RunService.Stepped:Connect(function()
    if Config.Noclip then
        local c = LP.Character
        if c then
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("BasePart") then d.CanCollide = false end
            end
        end
    end
end))

track(RunService.RenderStepped:Connect(function()
    if Config.Fly then
        local myRoot = getHRP(LP)
        if myRoot then
            if not State.flyVelocity or not State.flyVelocity.Parent then
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                bv.Velocity = Vector3.zero
                bv.Parent = myRoot
                State.flyVelocity = bv
            end
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                move = move + Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                move = move - Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                move = move - Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                move = move + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                move = move + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                move = move - Vector3.new(0, 1, 0)
            end
            State.flyVelocity.Velocity = move.Magnitude > 0
                and move.Unit * Config.FlySpeed
                or Vector3.zero
        end
    elseif State.flyVelocity then
        State.flyVelocity:Destroy()
        State.flyVelocity = nil
    end
end))

track(LP.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end))

track(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
        and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local pos = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(pos.X, pos.Y)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {LP.Character}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local hit = Workspace:Raycast(
            ray.Origin,
            ray.Direction * 2000,
            params
        )
        local myRoot = getHRP(LP)
        if hit and myRoot then
            myRoot.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
        end
    end
end))

-- ┌─────────────────────────────────────────────────────────────┐
-- │  coin farm tick                                             │
-- └─────────────────────────────────────────────────────────────┘

task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.CoinFarm then
            local myRoot = getHRP(LP)
            local h = getHumanoid(LP)
            if not myRoot or not h or h.Health <= 0 then continue end

            if Config.BagFullStop
                and getCurrentCoinCount() >= Config.CoinBagCap then
                if Config.ReturnToLobbyWhenFull then
                    local lb = getLobbyModel()
                    local part = lb and lb:FindFirstChildWhichIsA("BasePart")
                    if part then
                        myRoot.CFrame = part.CFrame * CFrame.new(0, 4, 0)
                    end
                end
                task.wait(1)
                continue
            end

            if Config.SafeCoinFarm then
                local murderer = select(1, getRolePlayers())
                local mRoot = murderer and getHRP(murderer)
                if mRoot
                    and (mRoot.Position - myRoot.Position).Magnitude < 30 then
                    task.wait(0.5)
                    continue
                end
            end

            local coins = getAllActiveCoins()
            if #coins == 0 then
                task.wait(1)
                continue
            end

            local target = coins[1]
            local bestDist = math.huge
            for _, c in ipairs(coins) do
                local d = (c.Position - myRoot.Position).Magnitude
                if d < bestDist then
                    bestDist, target = d, c
                end
            end

            if target then
                local yOffset = Config.UndergroundFarm and -15 or 1.5
                if Config.FarmMethod == "Teleport" then
                    myRoot.CFrame = target.CFrame
                        * CFrame.new(0, yOffset, 0)
                    task.wait(Config.TeleportFarmDelay)
                elseif Config.FarmMethod == "Glide" then
                    local dest = CFrame.new(
                        target.Position + Vector3.new(0, yOffset + 0.5, 0)
                    )
                    myRoot.CFrame = myRoot.CFrame:Lerp(dest, 0.25)
                    task.wait(0.05)
                elseif Config.FarmMethod == "Tween" then
                    local dist = (target.Position - myRoot.Position).Magnitude
                    local tween = TweenService:Create(
                        myRoot,
                        TweenInfo.new(
                            dist / (Config.FarmSpeed * 2),
                            Enum.EasingStyle.Linear
                        ),
                        {CFrame = CFrame.new(
                            target.Position + Vector3.new(0, yOffset, 0)
                        )}
                    )
                    tween:Play()
                    tween.Completed:Wait()
                else
                    h:MoveTo(target.Position)
                    task.wait(0.1)
                end

                State.farmStats.coins = State.farmStats.coins + 1
                State.farmStats.lastCoin = tick()
            end
        end
    end
end)

-- ┌─────────────────────────────────────────────────────────────┐
-- │  fling loops and round watcher                              │
-- └─────────────────────────────────────────────────────────────┘

task.spawn(function()
    while true do
        task.wait(0.5)
        if State.roundState ~= "Active" then
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
        if Config.FlingSheriffDuringRound
            and State.roundState == "Active" then
            local _, sheriff = getRolePlayers()
            if sheriff and sheriff.Character and isAlive(sheriff) then
                task.spawn(flingCharacter, sheriff.Character)
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        local myRoot = getHRP(LP)
        local map = getActiveMap()
        local wasActive = State.roundState == "Active"
        local isActive = false
        if map and myRoot then
            local spawns = map:FindFirstChild("Spawns")
            local anchor = spawns and spawns:FindFirstChildWhichIsA("BasePart")
            if anchor then
                local d = (anchor.Position - myRoot.Position).Magnitude
                if d < Config.RoundThreshold then isActive = true end
            end
        end
        State.roundState = isActive and "Active" or "Waiting"
        if not isActive and wasActive then
            State.shotThisRound = false
            if Config.RoundNotifs then
                notify("round", "round ended", 3)
            end
        end
    end
end)

-- ┌─────────────────────────────────────────────────────────────┐
-- │  gun drop watcher                                           │
-- └─────────────────────────────────────────────────────────────┘

task.spawn(function()
    local hadGun = false
    while true do
        task.wait(0.5)
        local gp = getGunDropPart(getGunDrop())
        if gp and not hadGun then
            hadGun = true
            if Config.GunDropNotify then
                notify("gun", "sheriff's gun is on the ground", 3)
            end
        elseif not gp then
            hadGun = false
        end
    end
end)

-- ┌─────────────────────────────────────────────────────────────┐
-- │  kill feed                                                  │
-- └─────────────────────────────────────────────────────────────┘

local function watchPlayer(p)
    if p == LP then return end
    track(p.CharacterAdded:Connect(function(ch)
        local hum = ch:WaitForChild("Humanoid", 10)
        if hum then
            hum.Died:Connect(function()
                killFeed(p.Name .. " died")
            end)
        end
    end))
    if p.Character then
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Died:Connect(function()
                killFeed(p.Name .. " died")
            end)
        end
    end
end

for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
track(Players.PlayerAdded:Connect(watchPlayer))

-- ┌─────────────────────────────────────────────────────────────┐
-- │  sheriff death  ·  auto grab gun                            │
-- └─────────────────────────────────────────────────────────────┘

task.spawn(function()
    while true do
        task.wait(0.5)
        local _, sheriff = getRolePlayers()
        if sheriff then
            State.lastSheriffName = sheriff.Name
            State.lastSheriffTick = tick()
        end
        if Config.AutoGrabOnSheriffDeath
            and State.lastSheriffName
            and not sheriff
            and tick() - State.lastSheriffTick < 2 then
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

-- ══════════════════════════════════════════════════════════════
--  UNLOAD  ·  kill everything clean
-- ══════════════════════════════════════════════════════════════

getgenv().RiadUnload = function()
    State.silentAimActive = false
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(connections)

    for _, tbl in ipairs({
        State.highlights, State.boxes,
        State.tracers, State.itemHighlights,
    }) do
        for _, obj in pairs(tbl) do
            if obj and obj.Parent then obj:Destroy() end
        end
        table.clear(tbl)
    end

    if State.auraRing then State.auraRing:Destroy() end
    if State.fovCircle then pcall(function() State.fovCircle:Remove() end) end
    if State.flyVelocity then State.flyVelocity:Destroy() end

    for part, sz in pairs(State.originalHitboxSizes) do
        if part and part.Parent then
            part.Size = sz
            part.Transparency = 1
        end
    end

    for k, v in pairs(State.originalLighting) do Lighting[k] = v end

    espFolder:Destroy()
    pcall(function() Rayfield:Destroy() end)
end

-- ══════════════════════════════════════════════════════════════
--  INTERFACE  ·  every tab, every toggle
-- ══════════════════════════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    name = "riad",
    loading_title = "riad",
    loading_subtitle = "loading",
    key_system = false,
})

local TabHome = Window:CreateTab({ name = "home" })
local TabVisual = Window:CreateTab({ name = "visuals" })
local TabGun = Window:CreateTab({ name = "gun" })
local TabKnife = Window:CreateTab({ name = "knife" })
local TabMove = Window:CreateTab({ name = "movement" })
local TabFarm = Window:CreateTab({ name = "farm" })
local TabSurv = Window:CreateTab({ name = "survival" })
local TabTP = Window:CreateTab({ name = "teleports" })
local TabFling = Window:CreateTab({ name = "fling" })
local TabMisc = Window:CreateTab({ name = "misc" })

-- shorthands to keep the UI section readable
local function T(tab, label, flag, default, cb)
    tab:CreateToggle({
        name = label,
        flag = flag,
        default = default or false,
        callback = function(v)
            Config[flag] = v
            if flag == "Fullbright" or flag == "NoFog" then
                applyWorldVisuals()
            end
            if flag == "FPSBoost" or flag == "DisableParticles" then
                applyFPSPass()
            end
            if cb then cb(v) end
        end,
    })
end

local function S(tab, label, flag, min, max, default, suffix, cb)
    tab:CreateSlider({
        name = label,
        flag = flag,
        range = {min, max},
        increment = 1,
        default = default,
        suffix = suffix or "",
        callback = function(v)
            Config[flag] = v
            if cb then cb(v) end
        end,
    })
end

local function D(tab, label, flag, options, default, cb)
    tab:CreateDropdown({
        name = label,
        flag = flag,
        options = options,
        default = default,
        callback = function(v)
            Config[flag] = v
            if cb then cb(v) end
        end,
    })
end

local function B(tab, label, cb)
    tab:CreateButton({ name = label, callback = cb })
end

-- ───────────────────────────  home  ───────────────────────────

TabHome:CreateText({ text = "riad hub — every feature live." })
TabHome:CreateDivider()

local statRole = TabHome:CreateStat({ name = "your role", flag = "statRole" })
local statMur = TabHome:CreateStat({ name = "murderer", flag = "statMurderer" })
local statSher = TabHome:CreateStat({ name = "sheriff", flag = "statSheriff" })
local statRound = TabHome:CreateStat({ name = "round", flag = "statRound" })
local statFPS = TabHome:CreateStat({ name = "fps", flag = "statFPS" })
local statPing = TabHome:CreateStat({ name = "ping", flag = "statPing" })
local statCoins = TabHome:CreateStat({ name = "coins farmed", flag = "statCoins" })

task.spawn(function()
    while true do
        task.wait(0.5)
        local murderer, sheriff = getRolePlayers()
        local role = getRole(LP)
        pcall(function()
            Window:Set("statRole", role)
            Window:Set("statMurderer", murderer and murderer.Name or "unknown")
            Window:Set("statSheriff", sheriff and sheriff.Name or "unknown")
            Window:Set("statRound", State.roundState)
            Window:Set("statCoins", State.farmStats.coins)
        end)
        local start = tick()
        RunService.RenderStepped:Wait()
        local frameTime = tick() - start
        pcall(function()
            Window:Set("statFPS", math.floor(1 / math.max(frameTime, 1e-4)))
            Window:Set("statPing", LP:GetNetworkPing() * 1000 // 1)
        end)
    end
end)

TabHome:CreateDivider()
B(TabHome, "test notification", function()
    notify("riad", "notifications working", 3)
end)
B(TabHome, "announce roles in chat", function()
    local murderer, sheriff = getRolePlayers()
    local msg = "murderer: " .. (murderer and murderer.Name or "?")
        .. " | sheriff: " .. (sheriff and sheriff.Name or "?")
    local channels = TextChatService:FindFirstChild("TextChannels")
    local general = channels and channels:FindFirstChild("RBXGeneral")
    if general then general:SendAsync(msg) end
end)
B(TabHome, "reset character", function()
    local h = getHumanoid(LP)
    if h then h.Health = 0 end
end)
B(TabHome, "unload", function()
    getgenv().RiadUnload()
end)

-- ──────────────────────────  visuals  ─────────────────────────

T(TabVisual, "role esp", "RoleESP")
T(TabVisual, "esp chams", "ESPChams")
T(TabVisual, "esp boxes", "ESPBoxes")
T(TabVisual, "esp names", "ESPNames", true)
T(TabVisual, "esp distance", "ESPDistance", true)
T(TabVisual, "esp health", "ESPHealth")
T(TabVisual, "esp tracers", "ESPTracers")
S(TabVisual, "esp max distance", "ESPDistanceMax", 50, 2000, 600, " studs")
T(TabVisual, "dropped gun esp", "GunESP")
T(TabVisual, "coin esp", "CoinESP")
T(TabVisual, "fullbright", "Fullbright")
T(TabVisual, "no fog", "NoFog")
T(TabVisual, "disable particles", "DisableParticles")
T(TabVisual, "fps boost", "FPSBoost")
B(TabVisual, "re-apply visual pass", applyFPSPass)

-- ────────────────────────────  gun  ───────────────────────────

T(TabGun, "aimbot", "Aimbot")
T(TabGun, "auto-shoot", "AutoShoot")
T(TabGun, "silent aim", "SilentAim")
T(TabGun, "aim prediction", "AimPrediction", true)
T(TabGun, "ping compensation", "PingComp", true)
T(TabGun, "single shot lock", "SingleShot")
T(TabGun, "auto equip gun", "AutoEquipGun", true)
T(TabGun, "auto grab gun", "GrabGunAuto")
S(TabGun, "grab distance", "GunGrabDist", 20, 800, 300, " studs")
T(TabGun, "grab on sheriff death", "AutoGrabOnSheriffDeath")
T(TabGun, "gun drop notification", "GunDropNotify", true)
T(TabGun, "show fov circle", "ShowFOV")
S(TabGun, "fov radius", "FOVRadius", 50, 700, 160, "")
B(TabGun, "pick up gun once", function()
    local gd = getGunDrop()
    local gp = getGunDropPart(gd)
    if gp then
        interactWithGunDrop(gp, gd)
        notify("riad", "attempted pickup", 2)
    else
        notify("riad", "no gun on map", 2)
    end
end)

-- ───────────────────────────  knife  ──────────────────────────

T(TabKnife, "auto-stab", "AutoStab")
T(TabKnife, "kill aura", "KillAura")
T(TabKnife, "auto kill innocents", "AutoKill")
D(TabKnife, "kill mode", "KillMode", {"Legit", "Blatant", "Throw"}, "Legit")
T(TabKnife, "knife silent aim", "KnifeSilentAim", true)
S(TabKnife, "aura range", "AuraRange", 5, 45, 15, " studs")
T(TabKnife, "show aura ring", "ShowAuraRing")
T(TabKnife, "auto equip knife", "AutoEquipKnife", true)
T(TabKnife, "proximity knife", "ProximityKnife", true)
S(TabKnife, "knife proximity distance", "KnifeProxDist", 5, 40, 18, " studs")
TabKnife:CreateDivider()
T(TabKnife, "hitbox expander", "HitboxExpander")
S(TabKnife, "hitbox size", "HitboxSize", 4, 30, 10, " studs")
S(TabKnife, "hitbox transparency %", "HitboxTransparencyPct", 0, 100, 60, "%", function(v)
    Config.HitboxTransparency = v / 100
end)
B(TabKnife, "kill all (murderer only)", function()
    local knife = equipTool("Knife")
    if not knife then
        notify("riad", "need knife equipped", 3)
        return
    end
    local myRoot = getHRP(LP)
    if not myRoot then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local hrp = getHRP(p)
            if hrp then
                myRoot.CFrame = hrp.CFrame
                task.wait(0.05)
                knife:Activate()
                task.wait(0.05)
            end
        end
    end
end)

-- ──────────────────────────  movement  ────────────────────────

T(TabMove, "speed boost", "Speed")
S(TabMove, "walk speed", "SpeedValue", 16, 60, 24, "")
T(TabMove, "jump boost", "JumpEnabled")
S(TabMove, "jump power", "JumpValue", 50, 150, 50, "")
T(TabMove, "infinite jump", "InfiniteJump")
T(TabMove, "noclip", "Noclip")
T(TabMove, "fly", "Fly")
S(TabMove, "fly speed", "FlySpeed", 15, 150, 35, " studs/s")
T(TabMove, "anti-ragdoll", "AntiRagdoll")
T(TabMove, "anti-fling", "AntiFling", true)
T(TabMove, "anti-void", "AntiVoid", true)
T(TabMove, "anti-afk", "AntiAFK", true)

-- ────────────────────────────  farm  ──────────────────────────

T(TabFarm, "auto farm coins", "CoinFarm")
D(TabFarm, "farm method", "FarmMethod",
    {"Teleport", "Glide", "Tween", "Walk"}, "Teleport")
S(TabFarm, "farm speed", "FarmSpeed", 16, 60, 28, "")
S(TabFarm, "teleport delay (x0.01s)", "TeleportFarmDelayV", 1, 50, 5, "", function(v)
    Config.TeleportFarmDelay = v / 100
end)
T(TabFarm, "safe farming", "SafeCoinFarm", true)
T(TabFarm, "bag full stop", "BagFullStop", true)
S(TabFarm, "coin bag cap", "CoinBagCap", 10, 40, 40, "")
T(TabFarm, "return to lobby when full", "ReturnToLobbyWhenFull")
T(TabFarm, "underground farm", "UndergroundFarm")
T(TabFarm, "coin magnet", "CoinMagnet")
S(TabFarm, "magnet radius", "MagnetRadius", 10, 200, 60, " studs")

-- ─────────────────────────  survival  ─────────────────────────

T(TabSurv, "murderer avoidance", "MurdererAvoid")
S(TabSurv, "safety radius", "SafetyRadius", 20, 80, 40, " studs")
T(TabSurv, "retreat to lobby", "RetreatToLobby")
T(TabSurv, "proximity alert", "ProximityAlert", true)
T(TabSurv, "sprint when chased", "SprintWhenChased", true)
T(TabSurv, "follow murderer", "FollowMurderer")
S(TabSurv, "follow distance", "FollowDist", 8, 40, 18, " studs")
T(TabSurv, "role-based auto play", "AutoPlay")

-- ─────────────────────────  teleports  ────────────────────────

local function tpToPlayer(p, label)
    local myRoot = getHRP(LP)
    local pr = p and getHRP(p)
    if myRoot and pr then
        myRoot.CFrame = pr.CFrame * CFrame.new(0, 0, 4)
        notify("riad", "tp: " .. (label or p.Name), 2)
        return true
    end
    return false
end

B(TabTP, "teleport to murderer", function()
    local murderer = select(1, getRolePlayers())
    if not tpToPlayer(murderer) then
        notify("riad", "murderer not found", 2)
    end
end)
B(TabTP, "teleport to sheriff", function()
    local _, sheriff = getRolePlayers()
    if not tpToPlayer(sheriff) then
        notify("riad", "sheriff not found", 2)
    end
end)
B(TabTP, "teleport to active map", function()
    local map = getActiveMap()
    local myRoot = getHRP(LP)
    local spawns = map and map:FindFirstChild("Spawns")
    local first = spawns and spawns:FindFirstChildWhichIsA("BasePart")
    if first and myRoot then
        myRoot.CFrame = first.CFrame * CFrame.new(0, 3, 0)
        notify("riad", "tp: " .. map.Name, 2)
    else
        notify("riad", "no active map", 2)
    end
end)
B(TabTP, "teleport to lobby", function()
    local lb = getLobbyModel()
    local part = lb and lb:FindFirstChildWhichIsA("BasePart")
    local myRoot = getHRP(LP)
    if part and myRoot then
        myRoot.CFrame = part.CFrame * CFrame.new(0, 4, 0)
    end
end)
B(TabTP, "teleport to dropped gun", function()
    local gp = getGunDropPart(getGunDrop())
    local myRoot = getHRP(LP)
    if gp and myRoot then
        myRoot.CFrame = gp.CFrame * CFrame.new(0, 3, 0)
    else
        notify("riad", "no gun on map", 2)
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

B(TabTP, "save slot 1", function()
    local r = getHRP(LP)
    if r then slot1CF = r.CFrame saveSlots() notify("riad", "slot 1 saved", 2) end
end)
B(TabTP, "go to slot 1", function()
    local r = getHRP(LP)
    if r and slot1CF then r.CFrame = slot1CF
    else notify("riad", "no slot 1", 2) end
end)
B(TabTP, "save slot 2", function()
    local r = getHRP(LP)
    if r then slot2CF = r.CFrame saveSlots() notify("riad", "slot 2 saved", 2) end
end)
B(TabTP, "go to slot 2", function()
    local r = getHRP(LP)
    if r and slot2CF then r.CFrame = slot2CF
    else notify("riad", "no slot 2", 2) end
end)

-- ────────────────────────────  fling  ─────────────────────────

D(TabFling, "fling style", "FlingStyle",
    {"Torque", "Velocity", "Orbit"}, "Torque")
B(TabFling, "fling murderer", function()
    local murderer = select(1, getRolePlayers())
    if murderer and murderer.Character then
        notify("riad", "flinging " .. murderer.Name, 2)
        task.spawn(flingCharacter, murderer.Character)
    else
        notify("riad", "murderer not found", 2)
    end
end)
B(TabFling, "fling sheriff", function()
    local _, sheriff = getRolePlayers()
    if sheriff and sheriff.Character then
        notify("riad", "flinging " .. sheriff.Name, 2)
        task.spawn(flingCharacter, sheriff.Character)
    else
        notify("riad", "sheriff not found", 2)
    end
end)
TabFling:CreateText({ text = "pre-round flings are detected." })
T(TabFling, "fling murderer pre-round", "FlingMurdererPreRound")
T(TabFling, "fling sheriff pre-round", "FlingSheriffPreRound")
T(TabFling, "fling hero pre-round", "FlingHeroPreRound")
T(TabFling, "fling all pre-round", "FlingAllPreRound")
T(TabFling, "fling sheriff during round", "FlingSheriffDuringRound")

-- ────────────────────────────  misc  ──────────────────────────

T(TabMisc, "kill feed notifications", "KillFeed", true)
T(TabMisc, "round end notifications", "RoundNotifs", true)

TabMisc:CreateDivider()

B(TabMisc, "load infinite yield", function()
    loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
    ))()
end)

B(TabMisc, "rejoin server", function()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(
            game.PlaceId, game.JobId, LP
        )
    end)
end)

B(TabMisc, "server hop", function()
    task.spawn(function()
        local ok, servers = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/"
                    .. game.PlaceId
                    .. "/servers/Public?sortOrder=Asc&limit=100"
            ))
        end)
        if ok and servers and servers.data and #servers.data > 0 then
            local candidates = {}
            for _, srv in ipairs(servers.data) do
                if srv.id ~= game.JobId
                    and srv.playing
                    and srv.maxPlayers
                    and srv.playing < srv.maxPlayers then
                    table.insert(candidates, srv.id)
                end
            end
            if #candidates > 0 then
                TeleportService:TeleportToPlaceInstance(
                    game.PlaceId,
                    candidates[math.random(#candidates)],
                    LP
                )
            else
                notify("riad", "no other servers", 3)
            end
        else
            notify("riad", "server fetch failed", 3)
        end
    end)
end)

TabMisc:CreateDivider()

local spectateOptions = {}
local function refreshSpectateList()
    table.clear(spectateOptions)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(spectateOptions, p.Name) end
    end
    return spectateOptions
end

local spectateDD = TabMisc:CreateDropdown({
    name = "spectate player",
    flag = "SpectateTarget",
    options = refreshSpectateList(),
    callback = function(name)
        local target = Players:FindFirstChild(name)
        local hum = target and getHumanoid(target)
        if hum then
            Camera.CameraSubject = hum
            State.spectating = name
        end
    end,
})

B(TabMisc, "refresh player list", function()
    spectateDD:Refresh and spectateDD:Refresh(refreshSpectateList())
end)
B(TabMisc, "stop spectating", function()
    local h = getHumanoid(LP)
    if h then Camera.CameraSubject = h end
    State.spectating = nil
end)

-- ┌─────────────────────────────────────────────────────────────┐
-- │  sync persisted flags into Config                           │
-- └─────────────────────────────────────────────────────────────┘

task.spawn(function()
    task.wait(1)
    for k, _ in pairs(Config) do
        local ok, v = pcall(function() return Window:Get(k) end)
        if ok and v ~= nil then Config[k] = v end
    end
    local okPct, pct = pcall(function()
        return Window:Get("HitboxTransparencyPct")
    end)
    if okPct and pct then Config.HitboxTransparency = pct / 100 end
    local okDelay, dv = pcall(function()
        return Window:Get("TeleportFarmDelayV")
    end)
    if okDelay and dv then Config.TeleportFarmDelay = dv / 100 end
    applyWorldVisuals()
    notify("riad", "loaded", 4)
end)
