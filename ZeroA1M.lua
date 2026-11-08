--!strict
-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  ZERO AIM — PRIVATE TESTING                                    ║
-- ║  © 2024 Kabela · @eabeatrizxs                                  ║
-- ╚═══════════════════════════════════════════════════════════════╝
-- path: StarterPlayer/StarterPlayerScripts/ZeroAim.luau (LocalScript)

local Players           = game:GetService("Players")
local UIS               = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats             = game:GetService("Stats")
local HttpService       = game:GetService("HttpService")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════════
local CFG = {
    Version     = "2.3.1",
    ProductName = "ZERO AIM",
    ProductSub  = "PRIVATE TESTING",
    Author      = "Kabela",
    Handle      = "@eabeatrizxs",
    BubbleImage = "rbxassetid://111554358669127",
    Theme = {
        Base    = Color3.fromRGB(6, 6, 10),
        Panel   = Color3.fromRGB(14, 14, 22),
        Surface = Color3.fromRGB(20, 20, 32),
        Accent  = Color3.fromRGB(168, 85, 247),
        Accent2 = Color3.fromRGB(236, 72, 153),
        Text    = Color3.fromRGB(240, 240, 255),
        Subtext = Color3.fromRGB(160, 160, 190),
        Success = Color3.fromRGB(52, 211, 153),
        Warn    = Color3.fromRGB(251, 191, 36),
        Danger  = Color3.fromRGB(248, 113, 113),
    },
    RGBPalette = {
        Color3.fromRGB(168, 85, 247), Color3.fromRGB(59, 130, 246),
        Color3.fromRGB(236, 72, 153), Color3.fromRGB(34, 211, 238),
    },
    RGBSpeed = 2.2,
    UpdateRates = { ESP = 30, Dashboard = 4, Telemetry = 1 },
    Locale = "pt-BR",
}

-- ═══════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════
local function rgb(t: number): Color3
    local pal = CFG.RGBPalette
    local n = #pal
    local x = (t * CFG.RGBSpeed) % n
    local i = math.floor(x) + 1
    local j = (i % n) + 1
    local f = x - math.floor(x)
    return pal[i]:Lerp(pal[j], f)
end
local function tw(inst, props, dur, style, dir)
    local t = TweenService:Create(inst,
        TweenInfo.new(dur or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props)
    t:Play()
    return t
end
local function round(n, p) local m = 10^(p or 0); return math.floor(n*m+0.5)/m end
local function fmtBytes(b)
    if b < 1024 then return b .. " B" end
    if b < 1048576 then return string.format("%.1f KB", b/1024) end
    return string.format("%.1f MB", b/1048576)
end
local function hb(hz, fn)
    local acc, interval = 0, 1/hz
    return RunService.Heartbeat:Connect(function(dt)
        acc += dt
        if acc >= interval then acc = 0; fn(dt) end
    end)
end
local function new(cls, props, parent)
    local i = Instance.new(cls)
    if props then for k,v in pairs(props) do i[k] = v end end
    if parent then i.Parent = parent end
    return i
end
local function corner(inst, r) new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, inst) end
local function stroke(inst, color, thick, trans)
    return new("UIStroke", { Color = color or CFG.Theme.Accent, Thickness = thick or 1, Transparency = trans or 0.5 }, inst)
end

-- ═══════════════════════════════════════════════════════════════════
-- LOCALES
-- ═══════════════════════════════════════════════════════════════════
local LOCALES = {
    ["pt-BR"] = {
        dashboard="Dashboard", aimbot="Aimbot", esp="ESP", visuals="Visuals",
        performance="Desempenho", playermanager="Player Manager", hitbox="Hitbox Viewer",
        spectator="Spectator", freecam="Free Camera", telemetry="Telemetria",
        settings="Configurações", customization="Personalização", profiles="Perfis",
        security="Segurança", logs="Logs", animations="Animações",
        info="Informações", about="Sobre", players="Jogadores", fps="FPS", ping="Ping",
        memory="Memória", server="Servidor", events="Eventos", tools_active="Ferramentas ativas",
        sessions="Sessões",
    },
    ["en"] = {
        dashboard="Dashboard", aimbot="Aimbot", esp="ESP", visuals="Visuals",
        performance="Performance", playermanager="Player Manager", hitbox="Hitbox Viewer",
        spectator="Spectator", freecam="Free Camera", telemetry="Telemetry",
        settings="Settings", customization="Customization", profiles="Profiles",
        security="Security", logs="Logs", animations="Animations", info="Info", about="About",
        players="Players", fps="FPS", ping="Ping", memory="Memory", server="Server",
        events="Events", tools_active="Active tools", sessions="Sessions",
    },
    ["es"] = {
        dashboard="Dashboard", aimbot="Aimbot", esp="ESP", visuals="Visuals",
        performance="Rendimiento", playermanager="Gestor", hitbox="Hitbox",
        spectator="Espectador", freecam="Cámara libre", telemetry="Telemetría",
        settings="Ajustes", customization="Personalización", profiles="Perfiles",
        security="Seguridad", logs="Registros", animations="Animaciones", info="Info", about="Acerca",
        players="Jugadores", fps="FPS", ping="Ping", memory="Memoria", server="Servidor",
        events="Eventos", tools_active="Herramientas", sessions="Sesiones",
    },
}
local currentLocale = CFG.Locale
local function L(k) local p = LOCALES[currentLocale]; return p and p[k] or k end
local setLocale: (string) -> ()

-- ═══════════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════════
local STATE = {
    sessionStart = tick(), events = {}, activeTools = {},
    profiles = {}, settings = {},
    telemetry = { fps = {}, ping = {}, mem = {}, players = {} },
}
local function pushEvent(cat, msg)
    table.insert(STATE.events, 1, { t = cat, msg = msg, ts = os.time() })
    if #STATE.events > 200 then table.remove(STATE.events) end
end

-- ═══════════════════════════════════════════════════════════════════
-- REMOTES
-- ═══════════════════════════════════════════════════════════════════
local FOLDER = ReplicatedStorage:FindFirstChild("ZeroAimRemotes")
    or new("Folder", { Name = "ZeroAimRemotes" }, ReplicatedStorage)
local function getRemote(cls, name)
    local r = FOLDER:FindFirstChild(name)
    if r and r:IsA(cls) then return r end
    if r then r:Destroy() end
    return new(cls, { Name = name }, FOLDER)
end
local REM = {
    GetState      = getRemote("RemoteFunction", "GetState"),
    AdminAction   = getRemote("RemoteFunction", "AdminAction"),
    LogEvent      = getRemote("RemoteEvent",    "LogEvent"),
    PushTelemetry = getRemote("RemoteEvent",    "PushTelemetry"),
}

-- ═══════════════════════════════════════════════════════════════════
-- INTRO
-- ═══════════════════════════════════════════════════════════════════
local function playIntro()
    local gui = new("ScreenGui", {
        Name = "ZA_Intro", IgnoreGuiInset = true, ResetOnSpawn = false,
        DisplayOrder = 200, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, PG)
    new("Frame", { Size = UDim2.fromScale(1,1), BackgroundColor3 = CFG.Theme.Base,
        BorderSizePixel = 0, ZIndex = 1 }, gui)

    local halo = new("Frame", {
        AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(0,0), BackgroundColor3 = rgb(0),
        BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 2,
    }, gui)
    corner(halo, 1000)
    new("UIGradient", {
        Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0,1),
            NumberSequenceKeypoint.new(0.5,0.2),
            NumberSequenceKeypoint.new(1,1),
        }, Rotation = 90,
    }, halo)

    local portal = new("Frame", {
        AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(0,0), BackgroundColor3 = Color3.new(0,0,0),
        BorderSizePixel = 0, ZIndex = 3,
    }, gui)
    corner(portal, 1000)
    local rim = stroke(portal, rgb(0), 6, 0)

    local ring1 = new("Frame", {
        AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(0,0), BackgroundTransparency = 1, ZIndex = 4,
    }, gui)
    corner(ring1, 1000)
    local ring1S = stroke(ring1, rgb(0.3), 2, 0.3)
    local ring2 = new("Frame", {
        AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(0,0), BackgroundTransparency = 1, ZIndex = 4,
    }, gui)
    corner(ring2, 1000)
    local ring2S = stroke(ring2, rgb(0.6), 1, 0.5)

    local title = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.new(1,-40,0,80), BackgroundTransparency = 1,
        Text = "ZERO AIM", TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.GothamBlack, TextSize = 56,
        TextStrokeTransparency = 0, TextStrokeColor3 = Color3.new(0,0,0),
        TextTransparency = 1, ZIndex = 5,
    }, gui)
    new("UITextSizeConstraint", { MaxTextSize = 56, MinTextSize = 20 }, title)

    local subtitle = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5,0), Position = UDim2.new(0.5,0,0.5,44),
        Size = UDim2.new(1,-40,0,24), BackgroundTransparency = 1,
        Text = "P R I V A T E   T E S T I N G", TextColor3 = CFG.Theme.Subtext,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextTransparency = 1, ZIndex = 5,
    }, gui)

    local credit = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -30),
        Size = UDim2.new(1, -40, 0, 20), BackgroundTransparency = 1,
        Text = "by " .. CFG.Author .. "  ·  " .. CFG.Handle,
        TextColor3 = CFG.Theme.Subtext,
        Font = Enum.Font.GothamMedium, TextSize = 11,
        TextTransparency = 1, ZIndex = 5,
    }, gui)
    task.delay(1.4, function() tw(credit, { TextTransparency = 0.3 }, 0.6) end)

    local particles = new("Frame", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, ZIndex = 6 }, gui)
    local targetSize = math.min(gui.AbsoluteSize.X, gui.AbsoluteSize.Y) * 0.85
    local t0 = tick()

    tw(portal, { Size = UDim2.fromOffset(targetSize, targetSize) }, 2.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    tw(halo, { Size = UDim2.fromOffset(targetSize*1.8, targetSize*1.8) }, 2.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    tw(ring1, { Size = UDim2.fromOffset(targetSize*1.4, targetSize*1.4) }, 2.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    tw(ring2, { Size = UDim2.fromOffset(targetSize*1.8, targetSize*1.8) }, 2.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    task.delay(1.2, function()
        tw(title, { TextTransparency = 0 }, 0.6)
        tw(subtitle, { TextTransparency = 0.2 }, 0.6)
    end)

    local pConn = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - t0
        if elapsed > 4.2 then return end
        local c = rgb(tick())
        rim.Color = c; halo.BackgroundColor3 = c
        ring1S.Color = rgb(tick() + 0.3); ring2S.Color = rgb(tick() + 0.6)
        ring1.Rotation = (elapsed * 90) % 360
        ring2.Rotation = (-elapsed * 60) % 360
        if math.random() < 0.5 then
            local p = new("Frame", {
                AnchorPoint = Vector2.new(0.5,0.5), Size = UDim2.fromOffset(3,3),
                BackgroundColor3 = rgb(tick()), BorderSizePixel = 0,
                BackgroundTransparency = 0.3, ZIndex = 6,
            }, particles)
            corner(p, 100)
            local a = math.random() * math.pi * 2
            local r = math.random(180, 380)
            p.Position = UDim2.new(0.5, math.cos(a)*r, 0.5, math.sin(a)*r)
            tw(p, { Position = UDim2.fromScale(0.5,0.5), BackgroundTransparency = 1,
                Size = UDim2.fromOffset(1,1) }, 0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(1, function() p:Destroy() end)
        end
    end)

    task.wait(3.2)
    tw(portal, { Size = UDim2.fromOffset(targetSize*0.5, targetSize*0.5) }, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    tw(title, { TextTransparency = 0.6, TextSize = 48 }, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    tw(credit, { TextTransparency = 0.8 }, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.wait(0.6)
    local flash = new("Frame", { Size = UDim2.fromScale(1,1), BackgroundColor3 = rgb(0.2),
        BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 7 }, gui)
    tw(flash, { BackgroundTransparency = 1 }, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    task.wait(0.5)
    local fade = new("Frame", { Size = UDim2.fromScale(1,1), BackgroundColor3 = Color3.new(0,0,0),
        BorderSizePixel = 0, ZIndex = 8 }, gui)
    tw(fade, { BackgroundTransparency = 1 }, 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.wait(0.6)
    pConn:Disconnect()
    gui:Destroy()
end

-- ═══════════════════════════════════════════════════════════════════
-- BUBBLE
-- ═══════════════════════════════════════════════════════════════════
local Bubble = { gui=nil, btn=nil, onTap=nil, initialized=false }
function Bubble.show(cb)
    Bubble.onTap = cb
    if not Bubble.initialized then
        Bubble.initialized = true
        local gui = new("ScreenGui", {
            Name = "ZA_Bubble", IgnoreGuiInset = true, ResetOnSpawn = false,
            DisplayOrder = 90, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        }, PG)
        Bubble.gui = gui
        local btn = new("ImageButton", {
            Name = "Bubble", Size = UDim2.fromOffset(56, 56),
            Position = UDim2.new(1, -76, 0.5, -28),
            Image = CFG.BubbleImage, BackgroundColor3 = CFG.Theme.Panel,
            BackgroundTransparency = 0.15, AutoButtonColor = false,
            ScaleType = Enum.ScaleType.Fit, ImageTransparency = 0, Active = true,
        }, gui)
        corner(btn, 1000)
        local s = stroke(btn, rgb(0), 2, 0)
        Bubble.btn = btn
        RunService.RenderStepped:Connect(function() s.Color = rgb(tick()) end)

        local dragStart, startPos, moved, pressActive = nil, nil, false, false
        local inputChangedConn = nil
        btn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch
                or i.UserInputType == Enum.UserInputType.MouseButton1 then
                pressActive = true; dragStart = i.Position; startPos = btn.Position; moved = false
                inputChangedConn = UIS.InputChanged:Connect(function(ic)
                    if ic.UserInputType == Enum.UserInputType.Touch
                        or ic.UserInputType == Enum.UserInputType.MouseMovement then
                        local d = ic.Position - dragStart
                        if d.Magnitude > 6 then moved = true end
                        if moved then
                            btn.Position = UDim2.new(
                                startPos.X.Scale, startPos.X.Offset + d.X,
                                startPos.Y.Scale, startPos.Y.Offset + d.Y)
                        end
                    end
                end)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch
                or i.UserInputType == Enum.UserInputType.MouseButton1 then
                if inputChangedConn then inputChangedConn:Disconnect(); inputChangedConn = nil end
                if pressActive then
                    pressActive = false
                    local wasTap = not moved
                    dragStart = nil; startPos = nil; moved = false
                    if wasTap and Bubble.onTap then Bubble.onTap() end
                end
            end
        end)
    end
    Bubble.gui.Enabled = true
    Bubble.btn.Size = UDim2.fromOffset(0, 0)
    tw(Bubble.btn, { Size = UDim2.fromOffset(56, 56) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- ═══════════════════════════════════════════════════════════════════
-- WIDGETS
-- ═══════════════════════════════════════════════════════════════════
local Widgets = {}
function Widgets.scroll(parent)
    local s = new("ScrollingFrame", {
        Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
        ScrollBarThickness = 2, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0,
    }, parent)
    new("UIPadding", { PaddingTop = UDim.new(0,12), PaddingLeft = UDim.new(0,12),
        PaddingRight = UDim.new(0,12), PaddingBottom = UDim.new(0,30) }, s)
    new("UIListLayout", { Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder }, s)
    return s
end
function Widgets.header(parent, text, order)
    return new("TextLabel", {
        Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1, Text = text,
        TextColor3 = CFG.Theme.Accent, TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold, TextSize = 16, LayoutOrder = order or 1,
    }, parent)
end
function Widgets.toggle(parent, label, initial, order, onChanged)
    local btn = new("TextButton", {
        Size = UDim2.new(1,0,0,40), BackgroundColor3 = CFG.Theme.Surface,
        Text = "  " .. label, TextColor3 = CFG.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium, TextSize = 13,
        LayoutOrder = order or 1, AutoButtonColor = false,
    }, parent)
    corner(btn, 8)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(36,20), Position = UDim2.new(1,-48,0.5,-10),
        BackgroundColor3 = CFG.Theme.Surface, BorderSizePixel = 0,
    }, btn)
    corner(knob, 100)
    local dot = new("Frame", {
        Size = UDim2.fromOffset(16,16), Position = UDim2.fromOffset(2,2),
        BackgroundColor3 = CFG.Theme.Subtext, BorderSizePixel = 0,
    }, knob)
    corner(dot, 100)
    local state = initial or false
    local function apply()
        tw(knob, { BackgroundColor3 = state and CFG.Theme.Accent or CFG.Theme.Surface }, 0.15)
        tw(dot, { Position = UDim2.fromOffset(state and 18 or 2, 2),
            BackgroundColor3 = state and CFG.Theme.Text or CFG.Theme.Subtext }, 0.15)
    end
    apply()
    btn.MouseButton1Click:Connect(function()
        state = not state; apply(); if onChanged then onChanged(state) end
    end)
    return btn, function() return state end
end
function Widgets.slider(parent, label, minV, maxV, initial, order, onChanged)
    local holder = new("Frame", { Size = UDim2.new(1,0,0,46),
        BackgroundTransparency = 1, LayoutOrder = order or 1 }, parent)
    new("TextLabel", { Size = UDim2.new(1,-80,0,20), BackgroundTransparency = 1,
        Text = label, TextColor3 = CFG.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium, TextSize = 13 }, holder)
    local valLbl = new("TextLabel", { Size = UDim2.fromOffset(60,20),
        Position = UDim2.new(1,-60,0,0), BackgroundTransparency = 1,
        Text = tostring(initial), TextColor3 = CFG.Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = Enum.Font.GothamBold, TextSize = 13 }, holder)
    local track = new("Frame", { Size = UDim2.new(1,0,0,6),
        Position = UDim2.fromOffset(0,30), BackgroundColor3 = CFG.Theme.Surface,
        BorderSizePixel = 0 }, holder)
    corner(track, 100)
    local fill = new("Frame", {
        Size = UDim2.fromScale((initial-minV)/(maxV-minV),1),
        BackgroundColor3 = CFG.Theme.Accent, BorderSizePixel = 0 }, track)
    corner(fill, 100)
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(minV + rel*(maxV-minV) + 0.5)
        fill.Size = UDim2.fromScale(rel,1)
        valLbl.Text = tostring(v)
        if onChanged then onChanged(v) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            setFromX(i.Position.X)
            local conn, endConn
            conn = RunService.RenderStepped:Connect(function() setFromX(UIS:GetMouseLocation().X) end)
            endConn = UIS.InputEnded:Connect(function() conn:Disconnect(); endConn:Disconnect() end)
        end
    end)
    return holder, function() return tonumber(valLbl.Text) or initial end
end
function Widgets.dropdown(parent, label, options, initial, order, onChanged)
    local holder = new("Frame", {
        Size = UDim2.new(1,0,0,44), BackgroundColor3 = CFG.Theme.Surface,
        LayoutOrder = order or 1, BorderSizePixel = 0, ClipsDescendants = true,
    }, parent)
    corner(holder, 8)
    local btn = new("TextButton", {
        Size = UDim2.new(1,0,0,44), BackgroundTransparency = 1,
        Text = "  " .. label .. "  ▾", TextColor3 = CFG.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium, TextSize = 13, ZIndex = 3 }, holder)
    local list = new("Frame", {
        Size = UDim2.new(1,0,0,0), Position = UDim2.fromOffset(0,44),
        BackgroundTransparency = 1, ClipsDescendants = true,
        BorderSizePixel = 0, Visible = false, ZIndex = 2 }, holder)
    new("UIListLayout", { Padding = UDim.new(0,2) }, list)
    local current = initial
    for i, opt in ipairs(options) do
        local item = new("TextButton", {
            Size = UDim2.new(1,0,0,34), BackgroundColor3 = CFG.Theme.Panel,
            Text = "  " .. opt, TextColor3 = CFG.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamMedium, TextSize = 12,
            LayoutOrder = i, ZIndex = 2 }, list)
        corner(item, 6)
        item.MouseButton1Click:Connect(function()
            current = opt
            btn.Text = "  " .. label .. ": " .. current .. "  ▾"
            list.Visible = false; list.Size = UDim2.new(1,0,0,0)
            holder.Size = UDim2.new(1,0,0,44)
            if onChanged then onChanged(current) end
        end)
    end
    btn.MouseButton1Click:Connect(function()
        local open = not list.Visible
        list.Visible = open
        list.Size = open and UDim2.new(1,0,0,#options*36) or UDim2.new(1,0,0,0)
        holder.Size = open and UDim2.new(1,0,0,44 + #options*36) or UDim2.new(1,0,0,44)
    end)
    return holder, function() return current end
end
function Widgets.button(parent, label, order, onPress, color)
    local btn = new("TextButton", {
        Size = UDim2.new(1,0,0,42), BackgroundColor3 = color or CFG.Theme.Accent,
        Text = label, TextColor3 = CFG.Theme.Text,
        Font = Enum.Font.GothamBold, TextSize = 14,
        LayoutOrder = order or 1, AutoButtonColor = false }, parent)
    corner(btn, 8)
    btn.MouseButton1Click:Connect(function() if onPress then onPress() end end)
    return btn
end
function Widgets.card(parent, title, value, order, accent)
    local f = new("Frame", {
        Size = UDim2.new(1,-4,0,86), BackgroundColor3 = CFG.Theme.Surface,
        LayoutOrder = order or 1, BorderSizePixel = 0 }, parent)
    corner(f, 10); stroke(f, accent or CFG.Theme.Accent, 1, 0.7)
    new("TextLabel", { Size = UDim2.new(1,-16,0,22), Position = UDim2.fromOffset(12,8),
        BackgroundTransparency = 1, Text = title, TextColor3 = CFG.Theme.Subtext,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium, TextSize = 12 }, f)
    local val = new("TextLabel", { Size = UDim2.new(1,-16,0,44),
        Position = UDim2.fromOffset(12,30), BackgroundTransparency = 1,
        Text = value or "—", TextColor3 = CFG.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold, TextSize = 22 }, f)
    return f, val
end
function Widgets.input(parent, placeholder, order, onSubmit)
    local box = new("Frame", {
        Size = UDim2.new(1,0,0,42), BackgroundColor3 = CFG.Theme.Surface,
        LayoutOrder = order or 1, BorderSizePixel = 0 }, parent)
    corner(box, 8)
    local tb = new("TextBox", {
        Size = UDim2.new(1,-88,1,0), Position = UDim2.fromOffset(8,0),
        BackgroundTransparency = 1, Text = "", PlaceholderText = placeholder,
        PlaceholderColor3 = CFG.Theme.Subtext, TextColor3 = CFG.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium, TextSize = 13, ClearTextOnFocus = false }, box)
    local go = new("TextButton", {
        Size = UDim2.fromOffset(72,34), Position = UDim2.new(1,-78,0.5,-17),
        BackgroundColor3 = CFG.Theme.Accent, Text = "OK",
        TextColor3 = CFG.Theme.Text, Font = Enum.Font.GothamBold, TextSize = 13 }, box)
    corner(go, 6)
    go.MouseButton1Click:Connect(function() if onSubmit then onSubmit(tb.Text) end end)
    return box, tb
end

-- ═══════════════════════════════════════════════════════════════════
-- FEATURES
-- ═══════════════════════════════════════════════════════════════════

local ESP = {
    opts = { box=false, skeleton=false, name=false, distance=false,
             health=false, teamCheck=false, maxDistance=500 },
    billboards = {}, highlights = {}, gui = nil, skeletonCache = {},
    started = false, loopStarted = false,
}
function ESP.start()
    if not ESP.gui then
        ESP.gui = new("ScreenGui", {
            Name = "ZA_ESP", IgnoreGuiInset = true, ResetOnSpawn = false,
            DisplayOrder = 40, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        }, PG)
    end
    if ESP.loopStarted then return end
    ESP.loopStarted = true

    RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        local myTeam = LP.Team
        local seen: {[Player]: boolean} = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            seen[p] = true
            local char = p.Character
            local head = char and char:FindFirstChild("Head") :: BasePart?
            local hrp  = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
            local hum  = char and char:FindFirstChildOfClass("Humanoid")

            local skip = false
            if not head or not hrp or not hum then skip = true end
            if not skip and ESP.opts.teamCheck and myTeam and p.Team == myTeam then skip = true end
            local dist = 0
            if not skip then
                dist = (hrp.Position - cam.CFrame.Position).Magnitude
                if dist > ESP.opts.maxDistance then skip = true end
            end

            if ESP.opts.box and not skip and char then
                local h = ESP.highlights[p]
                if not h then
                    h = new("Highlight", {
                        FillTransparency = 1, OutlineTransparency = 0,
                        OutlineColor = rgb(tick()), FillColor = rgb(tick()),
                        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                        Adornee = char, Parent = char,
                    })
                    ESP.highlights[p] = h
                end
                h.OutlineColor = rgb(tick())
                h.Adornee = char
                h.Enabled = true
            elseif ESP.highlights[p] then
                ESP.highlights[p].Enabled = ESP.opts.box and not skip
            end

            if skip then
                if ESP.billboards[p] then ESP.billboards[p].Enabled = false end
            else
                if ESP.opts.name or ESP.opts.distance or ESP.opts.health then
                    local bb = ESP.billboards[p]
                    if not bb then
                        bb = new("BillboardGui", {
                            Name = "ZA_BB_" .. p.Name, Adornee = head,
                            Size = UDim2.fromOffset(180, 60),
                            StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0),
                            AlwaysOnTop = true, LightInfluence = 0, ResetOnSpawn = false,
                        }, char)
                        local root = new("Frame", {
                            Name = "Root", Size = UDim2.fromScale(1, 1),
                            BackgroundTransparency = 1,
                        }, bb)
                        new("TextLabel", {
                            Name = "NameLbl", Size = UDim2.new(1, 0, 0, 18),
                            BackgroundTransparency = 1, Text = p.Name,
                            Font = Enum.Font.GothamBold, TextSize = 13,
                            TextColor3 = CFG.Theme.Text, TextStrokeTransparency = 0.3,
                        }, root)
                        new("TextLabel", {
                            Name = "DistLbl", Size = UDim2.new(1, 0, 0, 14),
                            Position = UDim2.fromOffset(0, 18), BackgroundTransparency = 1,
                            Font = Enum.Font.Gotham, TextSize = 11,
                            TextColor3 = CFG.Theme.Subtext,
                        }, root)
                        local bar = new("Frame", {
                            Name = "HealthBar", Size = UDim2.new(1, 0, 0, 4),
                            Position = UDim2.fromOffset(0, 34),
                            BackgroundColor3 = Color3.fromRGB(30, 30, 40),
                            BorderSizePixel = 0,
                        }, root)
                        new("Frame", {
                            Name = "Fill", Size = UDim2.fromScale(1, 1),
                            BackgroundColor3 = CFG.Theme.Success, BorderSizePixel = 0,
                        }, bar)
                        ESP.billboards[p] = bb
                    end
                    bb.Enabled = true
                    bb.MaxDistance = ESP.opts.maxDistance
                    local root = bb:FindFirstChild("Root") :: Frame?
                    if root then
                        local nameLbl = root:FindFirstChild("NameLbl") :: TextLabel?
                        local distLbl = root:FindFirstChild("DistLbl") :: TextLabel?
                        local bar = root:FindFirstChild("HealthBar") :: Frame?
                        if nameLbl then nameLbl.Visible = ESP.opts.name end
                        if distLbl then
                            distLbl.Visible = ESP.opts.distance
                            distLbl.Text = string.format("%d studs", math.floor(dist))
                        end
                        if bar then
                            bar.Visible = ESP.opts.health
                            local fill = bar:FindFirstChild("Fill") :: Frame?
                            local hp = hum.Health / math.max(hum.MaxHealth, 1)
                            if fill then
                                fill.Size = UDim2.fromScale(math.clamp(hp, 0, 1), 1)
                                fill.BackgroundColor3 = hp > 0.6 and CFG.Theme.Success
                                    or hp > 0.3 and CFG.Theme.Warn or CFG.Theme.Danger
                            end
                        end
                    end
                elseif ESP.billboards[p] then
                    ESP.billboards[p].Enabled = false
                end

                if ESP.opts.skeleton then
                    local bones = {
                        { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
                        { "UpperTorso", "LeftUpperArm" }, { "UpperTorso", "RightUpperArm" },
                        { "LowerTorso", "LeftUpperLeg" }, { "LowerTorso", "RightUpperLeg" },
                        { "LeftUpperArm", "LeftLowerArm" }, { "RightUpperArm", "RightLowerArm" },
                        { "LeftUpperLeg", "LeftLowerLeg" }, { "RightUpperLeg", "RightLowerLeg" },
                    }
                    if not ESP.skeletonCache[p] then ESP.skeletonCache[p] = {} end
                    for i, pair in ipairs(bones) do
                        local a = char:FindFirstChild(pair[1]) :: BasePart?
                        local b = char:FindFirstChild(pair[2]) :: BasePart?
                        local line = ESP.skeletonCache[p][i]
                        if not line then
                            line = new("Frame", {
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Size = UDim2.fromOffset(0, 2), BackgroundColor3 = rgb(tick()),
                                BorderSizePixel = 0, ZIndex = 5, Visible = false
                            }, ESP.gui)
                            ESP.skeletonCache[p][i] = line
                        end
                        if a and b then
                            local av, aOn = cam:WorldToViewportPoint(a.Position)
                            local bv, bOn = cam:WorldToViewportPoint(b.Position)
                            if aOn and bOn then
                                local va = Vector2.new(av.X, av.Y)
                                local vb = Vector2.new(bv.X, bv.Y)
                                local mid = (va + vb) / 2
                                local len = (va - vb).Magnitude
                                line.Position = UDim2.fromOffset(mid.X, mid.Y)
                                line.Size = UDim2.fromOffset(len, 2)
                                line.Rotation = math.deg(math.atan2(vb.Y - va.Y, vb.X - va.X))
                                line.BackgroundColor3 = rgb(tick())
                                line.Visible = true
                            else
                                line.Visible = false
                            end
                        else
                            line.Visible = false
                        end
                    end
                end
            end
        end

        for p, h in pairs(ESP.highlights) do
            if not seen[p] then h:Destroy(); ESP.highlights[p] = nil end
        end
        for p, bb in pairs(ESP.billboards) do
            if not seen[p] then bb:Destroy(); ESP.billboards[p] = nil end
        end
        for p, tbl in pairs(ESP.skeletonCache) do
            if not seen[p] then
                for _, line in ipairs(tbl) do line:Destroy() end
                ESP.skeletonCache[p] = nil
            elseif not ESP.opts.skeleton then
                for _, line in ipairs(tbl) do line.Visible = false end
            end
        end
    end)
end

local HitboxViewer = { active = false, boxes = {}, color = CFG.Theme.Accent }
function HitboxViewer.setActive(v)
    HitboxViewer.active = v
    if v then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP or not p.Character then continue end
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    local box = Instance.new("BoxHandleAdornment")
                    box.Adornee = part
                    box.Size = part.Size + Vector3.new(0.1,0.1,0.1)
                    box.Color3 = HitboxViewer.color
                    box.Transparency = 0.5
                    box.AlwaysOnTop = true
                    box.ZIndex = 5
                    box.Parent = part
                    table.insert(HitboxViewer.boxes, box)
                end
            end
        end
    else
        for _, b in ipairs(HitboxViewer.boxes) do b:Destroy() end
        HitboxViewer.boxes = {}
    end
end

local FreeCam = {
    active=false, speed=50, sensitivity=1,
    savedCFrame=nil, savedType=nil,
    moveConn=nil, lookConn=nil, yaw=0, pitch=0,
}
function FreeCam.enable()
    if FreeCam.active then return end
    FreeCam.active = true
    local cam = workspace.CurrentCamera
    FreeCam.savedType = cam.CameraType
    FreeCam.savedCFrame = cam.CFrame
    cam.CameraType = Enum.CameraType.Scriptable
    if not UIS.TouchEnabled then
        UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
        UIS.MouseIconEnabled = false
    end
    local _, currentYaw, _ = cam.CFrame:ToEulerAnglesYXZ()
    FreeCam.yaw = currentYaw
    local look = cam.CFrame.LookVector
    FreeCam.pitch = math.asin(math.clamp(look.Y, -1, 1))
    FreeCam.moveConn = RunService.RenderStepped:Connect(function(dt)
        if not FreeCam.active then return end
        local c = workspace.CurrentCamera
        local move = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then move += c.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move -= c.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move -= c.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move += c.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.E) then move += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then move -= Vector3.yAxis end
        if move.Magnitude > 0 then c.CFrame = c.CFrame + move.Unit * FreeCam.speed * dt end
    end)
    FreeCam.lookConn = UIS.InputChanged:Connect(function(i)
        if not FreeCam.active then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch then
            local dx = i.Delta.X * 0.004 * FreeCam.sensitivity
            local dy = i.Delta.Y * 0.004 * FreeCam.sensitivity
            FreeCam.yaw -= dx
            FreeCam.pitch = math.clamp(FreeCam.pitch - dy, -math.pi/2 + 0.01, math.pi/2 - 0.01)
            local c = workspace.CurrentCamera
            c.CFrame = CFrame.new(c.CFrame.Position)
                * CFrame.Angles(0, FreeCam.yaw, 0)
                * CFrame.Angles(FreeCam.pitch, 0, 0)
        end
    end)
end
function FreeCam.disable()
    if not FreeCam.active then return end
    FreeCam.active = false
    if FreeCam.moveConn then FreeCam.moveConn:Disconnect(); FreeCam.moveConn = nil end
    if FreeCam.lookConn then FreeCam.lookConn:Disconnect(); FreeCam.lookConn = nil end
    if not UIS.TouchEnabled then
        UIS.MouseBehavior = Enum.MouseBehavior.Default
        UIS.MouseIconEnabled = true
    end
    local cam = workspace.CurrentCamera
    cam.CameraType = FreeCam.savedType or Enum.CameraType.Custom
    if LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then cam.CameraSubject = hum end
    end
    if FreeCam.savedCFrame then cam.CFrame = FreeCam.savedCFrame end
    FreeCam.savedCFrame = nil; FreeCam.savedType = nil
end

local Spectator = { target=nil, active=false, conn=nil }
function Spectator.start(target: Player)
    Spectator.target = target
    Spectator.active = true
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    if Spectator.conn then Spectator.conn:Disconnect() end
    Spectator.conn = RunService.RenderStepped:Connect(function()
        if not Spectator.active or not Spectator.target or not Spectator.target.Character then return end
        local hrp = Spectator.target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if hrp then cam.CFrame = CFrame.lookAt(hrp.Position + Vector3.new(0,4,-8), hrp.Position) end
    end)
end
function Spectator.stop()
    Spectator.active = false
    Spectator.target = nil
    if Spectator.conn then Spectator.conn:Disconnect(); Spectator.conn = nil end
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom
    if LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then cam.CameraSubject = hum end
    end
end

local Telemetry = { history={fps={},ping={},mem={},players={}}, max=120, _last=tick() }
function Telemetry.sample()
    local now = tick()
    local dt = math.max(now - Telemetry._last, 0.001)
    Telemetry._last = now
    table.insert(Telemetry.history.fps, 1/dt)
    local ok, p = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    table.insert(Telemetry.history.ping, ok and p or 0)
    table.insert(Telemetry.history.mem, math.floor(collectgarbage("count") * 1024))
    table.insert(Telemetry.history.players, #Players:GetPlayers())
    for _, k in ipairs({ "fps", "ping", "mem", "players" }) do
        if #Telemetry.history[k] > Telemetry.max then table.remove(Telemetry.history[k], 1) end
    end
end
local FpsCounter = { current = 60 }
RunService.RenderStepped:Connect(function(dt) FpsCounter.current = round(1/dt, 0) end)

local Aimbot = {
    mode = "aimassist", enabled = false,
    fov = 200, smoothness = 0.35, bodyPart = "Head",
    teamCheck = true, prediction = false, predictionAmount = 0.15,
    raycast = true, drawFov = true,
    target = nil, targetPart = nil, started = false,
    gui = nil, fovRing = nil, fovStroke = nil, cross = nil,
    targetLabel = nil, modeLabel = nil,
    activatedConn = nil, lastShotAt = 0,
}

local function getCandidates()
    local list = {}
    local cam = workspace.CurrentCamera
    local center = cam.ViewportSize / 2
    local myTeam = LP.Team
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if Aimbot.teamCheck and myTeam and p.Team == myTeam then continue end
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part = char:FindFirstChild(Aimbot.bodyPart) :: BasePart?
        if not part then continue end
        local screen, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local v2 = Vector2.new(screen.X, screen.Y)
        local screenDist = (v2 - center).Magnitude
        if screenDist > Aimbot.fov then continue end
        table.insert(list, { player = p, part = part, screenPos = v2, dist = screenDist })
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

local function predictedPosition(part: BasePart): Vector3
    if not Aimbot.prediction then return part.Position end
    return part.Position + part.AssemblyLinearVelocity * Aimbot.predictionAmount
end

local function aimAssistStep(dt: number)
    local list = getCandidates()
    if #list == 0 then Aimbot.target = nil; Aimbot.targetPart = nil; return end
    local best = list[1]
    Aimbot.target = best.player
    Aimbot.targetPart = best.part
    local cam = workspace.CurrentCamera
    local targetPos = predictedPosition(best.part)
    local targetCFrame = CFrame.lookAt(cam.CFrame.Position, targetPos)
    local alpha = math.clamp(1 - Aimbot.smoothness, 0.05, 1)
    cam.CFrame = cam.CFrame:Lerp(targetCFrame, alpha * (dt / 0.016))
end

local function silentAimFire()
    if Aimbot.mode ~= "silentaim" or not Aimbot.enabled then return end
    local list = getCandidates()
    if #list == 0 then return end
    local best = list[1]
    Aimbot.target = best.player
    Aimbot.targetPart = best.part
    Aimbot.lastShotAt = tick()
    local cam = workspace.CurrentCamera
    local targetPos = predictedPosition(best.part)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { LP.Character }
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(cam.CFrame.Position, targetPos - cam.CFrame.Position, params)
    if result and result.Instance and result.Instance.Parent then
        local hl = Instance.new("Highlight")
        hl.Name = "ZA_SilentHit"
        hl.FillColor = Color3.fromRGB(255, 60, 60)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.4
        hl.OutlineTransparency = 0
        hl.Adornee = result.Instance.Parent
        hl.Parent = result.Instance.Parent
        task.delay(0.15, function() if hl then hl:Destroy() end end)
    end
end

local function hookSilentAim()
    if Aimbot.activatedConn then Aimbot.activatedConn:Disconnect() end
    local function tryFire()
        if Aimbot.mode == "silentaim" and Aimbot.enabled then silentAimFire() end
    end
    Aimbot.activatedConn = UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            tryFire()
        end
    end)
    for _, t in ipairs(LP:GetChildren()) do
        if t:IsA("Tool") then t.Activated:Connect(tryFire) end
    end
    LP.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then child.Activated:Connect(tryFire) end
    end)
end

function Aimbot.start()
    if Aimbot.started then return end
    Aimbot.started = true
    Aimbot.gui = new("ScreenGui", {
        Name = "ZA_Aimbot", IgnoreGuiInset = true, ResetOnSpawn = false,
        DisplayOrder = 60, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, PG)
    Aimbot.fovRing = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(Aimbot.fov*2, Aimbot.fov*2),
        BackgroundTransparency = 1, Visible = false,
    }, Aimbot.gui)
    corner(Aimbot.fovRing, 1000)
    Aimbot.fovStroke = stroke(Aimbot.fovRing, rgb(0), 2, 0.2)
    Aimbot.cross = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1, Visible = false,
    }, Aimbot.gui)
    new("Frame", { Size = UDim2.new(0,14,0,1),
        Position = UDim2.fromScale(0.5,0.5), AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = rgb(0), BorderSizePixel = 0 }, Aimbot.cross)
    new("Frame", { Size = UDim2.new(0,1,0,14),
        Position = UDim2.fromScale(0.5,0.5), AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = rgb(0), BorderSizePixel = 0 }, Aimbot.cross)
    Aimbot.targetLabel = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0.5, Aimbot.fov + 20),
        Size = UDim2.fromOffset(280, 22),
        BackgroundTransparency = 1, Text = "",
        TextColor3 = CFG.Theme.Accent,
        Font = Enum.Font.GothamBold, TextSize = 13, Visible = false,
    }, Aimbot.gui)
    Aimbot.modeLabel = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 0.5, -Aimbot.fov - 12),
        Size = UDim2.fromOffset(200, 18),
        BackgroundTransparency = 1, Text = "ZERO AIM · ASSIST",
        TextColor3 = CFG.Theme.Subtext,
        Font = Enum.Font.GothamMedium, TextSize = 11, Visible = false,
    }, Aimbot.gui)
    hookSilentAim()
    RunService.RenderStepped:Connect(function(dt)
        local on = Aimbot.enabled and Aimbot.mode ~= "off"
        Aimbot.gui.Enabled = on
        if not on then Aimbot.target = nil; Aimbot.targetPart = nil; return end
        Aimbot.fovRing.Visible = Aimbot.drawFov
        Aimbot.fovRing.Size = UDim2.fromOffset(Aimbot.fov*2, Aimbot.fov*2)
        Aimbot.fovStroke.Color = rgb(tick())
        Aimbot.targetLabel.Position = UDim2.new(0.5, 0, 0.5, Aimbot.fov + 20)
        Aimbot.modeLabel.Position = UDim2.new(0.5, 0, 0.5, -Aimbot.fov - 12)
        Aimbot.cross.Visible = true
        Aimbot.targetLabel.Visible = true
        Aimbot.modeLabel.Visible = true
        Aimbot.modeLabel.Text = Aimbot.mode == "silentaim" and "ZERO AIM · SILENT" or "ZERO AIM · ASSIST"
        if Aimbot.mode == "aimassist" then
            aimAssistStep(dt)
        else
            local list = getCandidates()
            if #list > 0 then
                Aimbot.target = list[1].player
                Aimbot.targetPart = list[1].part
            else
                Aimbot.target = nil; Aimbot.targetPart = nil
            end
        end
        if Aimbot.target and Aimbot.targetPart then
            local cam = workspace.CurrentCamera
            local sp = cam:WorldToViewportPoint(Aimbot.targetPart.Position)
            local center = cam.ViewportSize / 2
            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
            Aimbot.targetLabel.Text = ("◎ %s  ·  %d px  ·  %s")
                :format(Aimbot.target.Name, math.floor(d), Aimbot.bodyPart)
            Aimbot.targetLabel.TextColor3 = rgb(tick())
        else
            Aimbot.targetLabel.Text = "(sem alvo no FOV)"
            Aimbot.targetLabel.TextColor3 = CFG.Theme.Subtext
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- TABS
-- ═══════════════════════════════════════════════════════════════════
local Tabs = {}

Tabs.dashboard = function(parent)
    local s = Widgets.scroll(parent)
    local _, playersVal = Widgets.card(s, L("players"), "—", 1)
    local _, fpsVal     = Widgets.card(s, L("fps"), "—", 2)
    local _, pingVal    = Widgets.card(s, L("ping"), "—", 3)
    local _, memVal     = Widgets.card(s, L("memory"), "—", 4)
    local _, serverVal  = Widgets.card(s, L("server"), "—", 5)
    local _, toolsVal   = Widgets.card(s, L("tools_active"), "0", 6)
    local _, eventsVal  = Widgets.card(s, L("events"), "—", 7)
    local _, sessionsVal = Widgets.card(s, L("sessions"), "1", 8)
    hb(4, function()
        playersVal.Text = ("%d / %d"):format(#Players:GetPlayers(), Players.MaxPlayers)
        fpsVal.Text = tostring(FpsCounter.current)
        local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        pingVal.Text = ok and (tostring(round(ping, 0)) .. " ms") or "—"
        memVal.Text = fmtBytes(math.floor(collectgarbage("count") * 1024))
        local sOk, sData = pcall(function() return REM.GetState:InvokeServer() end)
        serverVal.Text = (sOk and sData) and "ONLINE" or "OFFLINE"
        local count = 0
        for _ in pairs(STATE.activeTools) do count += 1 end
        toolsVal.Text = tostring(count)
        local last = STATE.events[1]
        eventsVal.Text = last and ("[" .. last.t .. "] " .. last.msg) or "—"
        sessionsVal.Text = tostring(math.floor((tick() - STATE.sessionStart) / 60)) .. " min"
    end)
end

Tabs.aimbot = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Aimbot · Aim Assist · Silent Aim", 1)
    Widgets.toggle(s, "Ativar motor de mira", false, 2, function(v)
        Aimbot.enabled = v
        Aimbot.start()
        if not v then Aimbot.mode = "off"
        elseif Aimbot.mode == "off" then Aimbot.mode = "aimassist" end
        STATE.activeTools.aimbot = v or nil
        pushEvent("aimbot", v and "engine on" or "engine off")
    end)
    Widgets.dropdown(s, "Modo", { "Aim Assist", "Silent Aim" }, "Aim Assist", 3, function(v)
        if v == "Silent Aim" then Aimbot.mode = "silentaim"; Aimbot.smoothness = 1
        else Aimbot.mode = "aimassist" end
    end)
    Widgets.toggle(s, "Team Check", true, 4, function(v) Aimbot.teamCheck = v end)
    Widgets.toggle(s, "Prediction", false, 5, function(v) Aimbot.prediction = v end)
    Widgets.toggle(s, "Raycast", true, 6, function(v) Aimbot.raycast = v end)
    Widgets.toggle(s, "Mostrar FOV", true, 7, function(v) Aimbot.drawFov = v end)
    Widgets.slider(s, "FOV (px)", 40, 600, 200, 8, function(v) Aimbot.fov = v end)
    Widgets.slider(s, "Smoothness", 0, 100, 35, 9, function(v) Aimbot.smoothness = v / 100 end)
    Widgets.slider(s, "Prediction (amt)", 0, 100, 15, 10, function(v) Aimbot.predictionAmount = v / 100 end)
    Widgets.dropdown(s, "Parte do corpo", {
        "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso",
    }, "Head", 11, function(v) Aimbot.bodyPart = v end)
end

Tabs.esp = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "ESP", 1)
    Widgets.toggle(s, "Box", false, 2, function(v) ESP.opts.box = v; ESP.start() end)
    Widgets.toggle(s, "Skeleton", false, 3, function(v) ESP.opts.skeleton = v; ESP.start() end)
    Widgets.toggle(s, "Name", false, 4, function(v) ESP.opts.name = v; ESP.start() end)
    Widgets.toggle(s, "Distance", false, 5, function(v) ESP.opts.distance = v; ESP.start() end)
    Widgets.toggle(s, "Health", false, 6, function(v) ESP.opts.health = v; ESP.start() end)
    Widgets.toggle(s, "Team Check", false, 7, function(v) ESP.opts.teamCheck = v; ESP.start() end)
    Widgets.slider(s, "Max Distance", 50, 1000, 500, 8, function(v) ESP.opts.maxDistance = v end)
end

Tabs.visuals = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Visuals", 1)
    Widgets.toggle(s, "RGB Dinâmico", true, 2, function(v) CFG.RGBSpeed = v and 2.2 or 0 end)
    Widgets.slider(s, "Glow", 0, 100, 60, 3)
    Widgets.slider(s, "Transparência", 0, 100, 15, 4)
    Widgets.toggle(s, "Partículas", true, 5)
end

Tabs.performance = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Desempenho", 1)
    local _, fpsV = Widgets.card(s, "FPS", tostring(FpsCounter.current), 2)
    local _, pingV = Widgets.card(s, "Ping", "—", 3)
    local _, memV = Widgets.card(s, "Memória", "—", 4)
    hb(2, function()
        fpsV.Text = tostring(FpsCounter.current)
        local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        pingV.Text = ok and (tostring(round(ping, 0)) .. " ms") or "—"
        memV.Text = fmtBytes(math.floor(collectgarbage("count") * 1024))
    end)
end

Tabs.playermanager = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Player Manager", 1)
    local order = 10
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local row = new("Frame", {
            Size = UDim2.new(1,0,0,44), BackgroundColor3 = CFG.Theme.Surface,
            LayoutOrder = order, BorderSizePixel = 0 }, s)
        corner(row, 8)
        new("TextLabel", { Size = UDim2.new(1,-80,1,0), Position = UDim2.fromOffset(8,0),
            BackgroundTransparency = 1, Text = p.Name, TextColor3 = CFG.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamMedium, TextSize = 13 }, row)
        local specBtn = new("TextButton", {
            Size = UDim2.fromOffset(64,32), Position = UDim2.new(1,-72,0.5,-16),
            BackgroundColor3 = CFG.Theme.Accent, Text = "Spec",
            TextColor3 = CFG.Theme.Text,
            Font = Enum.Font.GothamBold, TextSize = 12 }, row)
        corner(specBtn, 6)
        specBtn.MouseButton1Click:Connect(function() Spectator.start(p) end)
        order += 1
    end
end

Tabs.hitbox = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Hitbox Viewer", 1)
    Widgets.toggle(s, "Ativar visualização", false, 2, function(v)
        HitboxViewer.setActive(v)
        STATE.activeTools.hitbox = v or nil
    end)
end

Tabs.spectator = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Spectator", 1)
    local names = { "(nenhum)" }
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(names, p.Name) end
    end
    Widgets.dropdown(s, "Alvo", names, "(nenhum)", 2, function(v)
        if v == "(nenhum)" then Spectator.stop(); return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == v then Spectator.start(p); break end
        end
    end)
    Widgets.button(s, "Parar", 3, function() Spectator.stop() end, CFG.Theme.Danger)
end

Tabs.freecam = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Free Camera", 1)
    Widgets.toggle(s, "Ativar", false, 2, function(v)
        if v then FreeCam.enable() else FreeCam.disable() end
        STATE.activeTools.freecam = v or nil
    end)
    Widgets.slider(s, "Velocidade", 5, 200, 50, 3, function(v) FreeCam.speed = v end)
    Widgets.slider(s, "Sensibilidade", 1, 20, 5, 4, function(v) FreeCam.sensitivity = v / 5 end)
end

Tabs.telemetry = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Telemetria", 1)
    local _, fpsAvgV = Widgets.card(s, "FPS médio", "—", 2)
    local _, pingAvgV = Widgets.card(s, "Ping médio", "—", 3)
    local _, memAvgV = Widgets.card(s, "Memória", "—", 4)
    local _, playersV = Widgets.card(s, "Jogadores", "—", 5)
    hb(1, function()
        local function avg(t) local sum = 0; for _,v in ipairs(t) do sum += v end; return #t>0 and sum/#t or 0 end
        fpsAvgV.Text = tostring(round(avg(Telemetry.history.fps), 0))
        pingAvgV.Text = tostring(round(avg(Telemetry.history.ping), 0)) .. " ms"
        memAvgV.Text = fmtBytes(avg(Telemetry.history.mem))
        playersV.Text = tostring(round(avg(Telemetry.history.players), 0))
    end)
end

Tabs.settings = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Configurações", 1)
    Widgets.dropdown(s, "Idioma", {"pt-BR","en","es"}, currentLocale, 2, function(v)
        if setLocale then setLocale(v) end
    end)
end

Tabs.customization = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Personalização", 1)
    Widgets.toggle(s, "Partículas", true, 2)
end

Tabs.profiles = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Perfis", 1)
    Widgets.input(s, "Nome do perfil", 2, function(name)
        if name == "" then return end
        pushEvent("profiles", "salvo: " .. name)
    end)
end

Tabs.security = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Segurança", 1)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = CFG.Theme.Surface,
        Text = "  Modo local sem key system.",
        TextColor3 = CFG.Theme.Subtext, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true,
        Font = Enum.Font.Gotham, TextSize = 11, LayoutOrder = 2,
    }, s)
end

Tabs.logs = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Logs", 1)
    local list = new("ScrollingFrame", {
        Size = UDim2.new(1,0,0,300), BackgroundColor3 = CFG.Theme.Surface,
        ScrollBarThickness = 2, BorderSizePixel = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2 }, s)
    corner(list, 8)
    new("UIListLayout", { Padding = UDim.new(0,2) }, list)
    hb(2, function()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        for i = 1, math.min(20, #STATE.events) do
            local e = STATE.events[i]
            new("TextLabel", {
                Size = UDim2.new(1,-8,0,18), BackgroundTransparency = 1,
                Text = ("[%s] %s"):format(e.t, e.msg),
                TextColor3 = CFG.Theme.Subtext,
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = Enum.Font.Code, TextSize = 11, LayoutOrder = i }, list)
        end
    end)
end

Tabs.animations = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Animações & Intro", 1)
    Widgets.button(s, "Reproduzir intro", 2, function() task.spawn(playIntro) end)
end

Tabs.info = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Informações", 1)
    new("TextLabel", {
        Size = UDim2.new(1,0,0,140), BackgroundColor3 = CFG.Theme.Surface,
        Text = ("  ZERO AIM — PRIVATE TESTING\n  Versão: %s\n  Autor: %s (%s)"):format(CFG.Version, CFG.Author, CFG.Handle),
        TextColor3 = CFG.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Font = Enum.Font.GothamMedium, TextSize = 12, LayoutOrder = 2 }, s)
end

Tabs.about = function(parent)
    local s = Widgets.scroll(parent)
    Widgets.header(s, "Sobre · Créditos", 1)
    local ownerCard = new("Frame", {
        Size = UDim2.new(1, 0, 0, 130), BackgroundColor3 = CFG.Theme.Surface,
        BorderSizePixel = 0, LayoutOrder = 2 }, s)
    corner(ownerCard, 12)
    local cardStroke = stroke(ownerCard, rgb(0), 2, 0.2)
    RunService.RenderStepped:Connect(function()
        if cardStroke then cardStroke.Color = rgb(tick()) end
    end)
    new("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18), Position = UDim2.fromOffset(14, 12),
        BackgroundTransparency = 1, Text = "CRIADO POR",
        TextColor3 = CFG.Theme.Subtext,
        Font = Enum.Font.GothamMedium, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left }, ownerCard)
    new("TextLabel", {
        Size = UDim2.new(1, -24, 0, 34), Position = UDim2.fromOffset(14, 32),
        BackgroundTransparency = 1, Text = CFG.Author,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBlack, TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Left }, ownerCard)
    local handleLbl = new("TextLabel", {
        Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(14, 70),
        BackgroundTransparency = 1, Text = CFG.Handle,
        TextColor3 = rgb(0),
        Font = Enum.Font.GothamBold, TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left }, ownerCard)
    RunService.RenderStepped:Connect(function()
        if handleLbl then handleLbl.TextColor3 = rgb(tick()) end
    end)
    new("TextLabel", {
        Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(14, 96),
        BackgroundTransparency = 1, Text = "ZERO AIM · " .. CFG.ProductSub,
        TextColor3 = CFG.Theme.Subtext,
        Font = Enum.Font.Gotham, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left }, ownerCard)
end

-- ═══════════════════════════════════════════════════════════════════
-- PANEL
-- ═══════════════════════════════════════════════════════════════════
local TABS = {
    { id="dashboard",    label="dashboard" },
    { id="aimbot",       label="aimbot" },
    { id="esp",          label="esp" },
    { id="visuals",      label="visuals" },
    { id="performance",  label="performance" },
    { id="playermanager",label="playermanager" },
    { id="hitbox",       label="hitbox" },
    { id="spectator",    label="spectator" },
    { id="freecam",      label="freecam" },
    { id="telemetry",    label="telemetry" },
    { id="settings",     label="settings" },
    { id="customization",label="customization" },
    { id="profiles",     label="profiles" },
    { id="security",     label="security" },
    { id="logs",         label="logs" },
    { id="animations",   label="animations" },
    { id="info",         label="info" },
    { id="about",        label="about" },
}

local Panel = {
    gui=nil, root=nil, sidebar=nil, content=nil,
    isOpen=false, sidebarVisible=true, current="dashboard", cache={},
}

local function buildHeader(root)
    local header = new("Frame", {
        Size = UDim2.new(1,0,0,56), BackgroundColor3 = CFG.Theme.Panel,
        BorderSizePixel = 0 }, root)
    new("TextLabel", {
        Size = UDim2.new(1,-260,1,0), Position = UDim2.fromOffset(16,0),
        BackgroundTransparency = 1,
        Text = CFG.ProductName .. "  —  " .. CFG.ProductSub,
        TextColor3 = CFG.Theme.Text, Font = Enum.Font.GothamBold,
        TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left }, header)
    new("TextLabel", {
        Size = UDim2.fromOffset(220, 16),
        Position = UDim2.new(1, -300, 0.5, -8),
        BackgroundTransparency = 1,
        Text = "by " .. CFG.Author .. "  ·  " .. CFG.Handle,
        TextColor3 = CFG.Theme.Subtext,
        Font = Enum.Font.GothamMedium, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right }, header)
    local close = new("TextButton", {
        Size = UDim2.fromOffset(36,36), Position = UDim2.new(1,-48,0.5,-18),
        BackgroundColor3 = CFG.Theme.Danger, Text = "×",
        TextColor3 = CFG.Theme.Text, Font = Enum.Font.GothamBold, TextSize = 20,
        AutoButtonColor = false }, header)
    corner(close, 8)
    close.MouseButton1Click:Connect(function() Panel.close() end)
    local menu = new("TextButton", {
        Size = UDim2.fromOffset(36,36), Position = UDim2.new(1,-92,0.5,-18),
        BackgroundColor3 = CFG.Theme.Surface, Text = "☰",
        TextColor3 = CFG.Theme.Text, Font = Enum.Font.GothamBold, TextSize = 16,
        AutoButtonColor = false }, header)
    corner(menu, 8)
    menu.MouseButton1Click:Connect(function()
        Panel.sidebarVisible = not Panel.sidebarVisible
        Panel.layout()
    end)
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = root.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            root.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function buildSidebar(root)
    local sb = new("ScrollingFrame", {
        Name = "Sidebar", Size = UDim2.new(0,200,1,-56),
        Position = UDim2.fromOffset(0,56), BackgroundColor3 = CFG.Theme.Surface,
        BorderSizePixel = 0, ScrollBarThickness = 2,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true }, root)
    new("UIPadding", { PaddingTop = UDim.new(0,8), PaddingLeft = UDim.new(0,8),
        PaddingRight = UDim.new(0,8), PaddingBottom = UDim.new(0,8) }, sb)
    new("UIListLayout", { Padding = UDim.new(0,4), SortOrder = Enum.SortOrder.LayoutOrder }, sb)
    for i, tab in ipairs(TABS) do
        local btn = new("TextButton", {
            Name = tab.id, Size = UDim2.new(1,-4,0,38),
            BackgroundColor3 = CFG.Theme.Surface,
            BackgroundTransparency = (tab.id == Panel.current) and 0.1 or 0.5,
            BorderSizePixel = 0, Text = "  " .. L(tab.label),
            TextColor3 = CFG.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamMedium, TextSize = 13,
            LayoutOrder = i, AutoButtonColor = false }, sb)
        corner(btn, 8)
        btn.MouseButton1Click:Connect(function()
            Panel.navigate(tab.id)
            for _, c in ipairs(sb:GetChildren()) do
                if c:IsA("TextButton") then
                    c.BackgroundTransparency = (c == btn) and 0.1 or 0.5
                end
            end
        end)
    end
    new("TextLabel", {
        Size = UDim2.new(1, -12, 0, 40),
        BackgroundTransparency = 1,
        Text = "by " .. CFG.Author .. "\n" .. CFG.Handle,
        TextColor3 = CFG.Theme.Subtext,
        Font = Enum.Font.GothamMedium, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = 999 }, sb)
    return sb
end

function Panel.layout()
    if not Panel.root then return end
    if Panel.sidebar then Panel.sidebar.Visible = Panel.sidebarVisible end
    if Panel.content then
        if Panel.sidebarVisible then
            Panel.content.Position = UDim2.fromOffset(200,56)
            Panel.content.Size = UDim2.new(1,-200,1,-56)
        else
            Panel.content.Position = UDim2.fromOffset(0,56)
            Panel.content.Size = UDim2.new(1,0,1,-56)
        end
    end
end

function Panel.navigate(id)
    if not Panel.content then return end
    for _, c in ipairs(Panel.content:GetChildren()) do
        if c:IsA("Frame") then c.Visible = false end
    end
    local frame = Panel.cache[id]
    if not frame then
        frame = new("Frame", { Name = id, Size = UDim2.fromScale(1,1),
            BackgroundTransparency = 1, Visible = false }, Panel.content)
        Panel.cache[id] = frame
        local builder = Tabs[id]
        if builder then
            local ok, err = pcall(builder, frame)
            if not ok then warn("[ZERO AIM] tab " .. id .. ": " .. tostring(err)) end
        end
    end
    frame.Visible = true
    frame.Position = UDim2.fromOffset(0,18)
    tw(frame, { Position = UDim2.fromOffset(0,0) }, 0.2)
    Panel.current = id
end

function setLocale(l: string)
    if not LOCALES[l] then return end
    currentLocale = l
    if not Panel.gui then return end
    for id, frame in pairs(Panel.cache) do
        if frame and frame.Parent then frame:Destroy() end
        Panel.cache[id] = nil
    end
    if Panel.sidebar then Panel.sidebar:Destroy(); Panel.sidebar = nil end
    if Panel.content then Panel.content:Destroy(); Panel.content = nil end
    if Panel.root then
        Panel.sidebar = buildSidebar(Panel.root)
        Panel.content = new("Frame", {
            Name = "Content", BackgroundTransparency = 1, ClipsDescendants = true,
        }, Panel.root)
        Panel.layout()
        Panel.navigate(Panel.current)
    end
    pushEvent("settings", "locale: " .. l)
end

function Panel.open()
    if not Panel.gui then
        local gui = new("ScreenGui", {
            Name = "ZA_Panel", IgnoreGuiInset = true, ResetOnSpawn = false,
            DisplayOrder = 95, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, PG)
        Panel.gui = gui
        local root = new("Frame", {
            Name = "Root", Size = UDim2.fromOffset(720,460),
            Position = UDim2.fromScale(0.5,0.5),
            AnchorPoint = Vector2.new(0.5,0.5),
            BackgroundColor3 = CFG.Theme.Panel, BorderSizePixel = 0 }, gui)
        corner(root, 16)
        stroke(root, CFG.Theme.Accent, 2, 0.3)
        Panel.root = root
        buildHeader(root)
        Panel.sidebar = buildSidebar(root)
        Panel.content = new("Frame", { Name = "Content",
            BackgroundTransparency = 1, ClipsDescendants = true }, root)
        local function resize()
            local vp = gui.AbsoluteSize
            root.Size = UDim2.fromOffset(
                math.min(720, vp.X - 24), math.min(460, vp.Y - 24))
            Panel.sidebarVisible = vp.X >= 720
            Panel.layout()
        end
        gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
        task.defer(resize)
    end
    Panel.gui.Enabled = true
    Panel.layout()
    Panel.root.Size = UDim2.fromOffset(0,0)
    local vp = Panel.gui.AbsoluteSize
    tw(Panel.root, { Size = UDim2.fromOffset(
        math.min(720, vp.X - 24), math.min(460, vp.Y - 24)) },
        0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Panel.isOpen = true
    Panel.navigate(Panel.current)
    pushEvent("panel", "aberto")
end

function Panel.close()
    if not Panel.root then return end
    tw(Panel.root, { Size = UDim2.fromOffset(0,0) }, 0.2,
        Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.delay(0.22, function()
        if not Panel.isOpen and Panel.gui then Panel.gui.Enabled = false end
    end)
    Panel.isOpen = false
    pushEvent("panel", "fechado")
end

function Panel.toggle()
    if Panel.isOpen then Panel.close() else Panel.open() end
end

-- ═══════════════════════════════════════════════════════════════════
-- BOOT
-- ═══════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        Telemetry.sample()
        task.wait(1 / CFG.UpdateRates.Telemetry)
    end
end)

REM.LogEvent.OnClientEvent:Connect(function(entry)
    if entry and entry.message then
        pushEvent(entry.category or "log", tostring(entry.message))
    end
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then Panel.toggle() end
end)

task.spawn(function()
    local ok, err = pcall(playIntro)
    if not ok then warn("[ZERO AIM] intro erro: " .. tostring(err)) end
    Bubble.show(function() Panel.toggle() end)
end)

print([[
╔══════════════════════════════════════════════════════╗
║  ZERO AIM — by Kabela (@eabeatrizxs)                 ║
║  © 2024 · Todos os direitos reservados               ║
╚══════════════════════════════════════════════════════╝
]])
print(("[ZERO AIM] client v%s carregado"):format(CFG.Version))
