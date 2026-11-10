--[[
    Kato Key System  v3.3.0
    Pantalla de key para Kato Hub con el mismo estilo Soft UI (neumorphism claro) de Kato Lib v3.

    USO
        local KeySystem = loadstring(game:HttpGet("URL/KatoKeySystem.lua"))()
        local ok, key = KeySystem.Prompt({
            Title = "Kato Hub", Subtitle = "Key System",
            KeyLink = "https://tu-link-de-key.com",
            DiscordLink = "https://discord.gg/tu-server",
            Keys = { "KATO-1234" },             -- lista fija, o:
            -- KeyUrl = "https://raw.../keys.txt", -- una key por linea, o:
            -- Validate = function(key) return key == "x", "mensaje opcional" end,
            -- Library = Kato,                  -- opcional: usa los colores del tema activo de Kato Lib
        })
        if not ok then return end
        -- cargar el hub aqui

    Idioma: Language = "es" | "en" (por defecto el de Library, o espanol). Los textos aceptan { es = ..., en = ... }.

    Tambien: KeySystem.new(opts) devuelve un objeto con :Wait() :SetStatus(text, kind) :Close() :Destroy()
    y callbacks OnSuccess(key) / OnFail(key, msg) / OnClose().

    Sombras: se dibujan con capas de Frames redondeados (sin assets). Si subes la imagen de sombra
    descrita en KatoLib.lua, pon su ID en SHADOW_IMAGE y se usara un ImageLabel 9-slice.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ===== Constantes configurables =====
local SHADOW_IMAGE = ""                     -- mismo PNG que KatoLib (160x160, blur 12, cuadrado blanco 96x96)
local SHADOW_SLICE = Rect.new(64, 64, 96, 96)
local SHADOW_EDGE = 32
local SHADOW_STEP = 2.5
local SHADOW_MAX_LAYERS = 10

local LocalPlayer = Players.LocalPlayer
local rgb = Color3.fromRGB
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)

local KeySystem = {}
KeySystem.__index = KeySystem
KeySystem.Version = "3.3.0"

-- ===== Idiomas =====
-- Por defecto sigue al idioma de Kato Lib (opts.Library) o usa opts.Language; si no hay ninguno, espanol.
-- Title, Subtitle, Description y Placeholder aceptan string o { es = "...", en = "..." }.
KeySystem.Languages = {
    es = {
        Subtitle = "Sistema de keys", Description = "Consigue tu key y pégala abajo para desbloquear el hub.",
        Placeholder = "Pega tu key aquí", Verify = "Verificar key", Verifying = "Verificando...", Unlocked = "Desbloqueado",
        GetKey = "Conseguir key", Discord = "Discord", Locked = "Bloqueado (%ds)",
        AttemptsOne = "%s  ·  queda 1 intento", AttemptsMany = "%s  ·  quedan %d intentos",
        ErrValidate = "Error al validar la key", ErrServer = "No se pudo conectar con el servidor de keys",
        NotConfigured = "El sistema de keys no está configurado", TryAgain = "Ya puedes intentarlo de nuevo.",
        PasteFirst = "Primero pega una key.", Granted = "Acceso concedido. ¡Bienvenido!",
        Expired = "Tu key guardada caducó. Consigue una nueva.", ConnError = "Error de conexión, inténtalo de nuevo.",
        TooMany = "Demasiados intentos. Espera %d segundos.", Invalid = "Key inválida.",
        LinkCopied = "Link de la key copiado al portapapeles.", Link = "Link: %s", NoLink = "No hay un link de key configurado.",
        DiscordCopied = "Invitación de Discord copiada.", Checking = "Comprobando tu key guardada...", Welcome = "Hola, %s.",
    },
    en = {
        Subtitle = "Key System", Description = "Get your key and paste it below to unlock the hub.",
        Placeholder = "Paste your key here", Verify = "Verify key", Verifying = "Verifying...", Unlocked = "Unlocked",
        GetKey = "Get key", Discord = "Discord", Locked = "Locked (%ds)",
        AttemptsOne = "%s  ·  1 attempt left", AttemptsMany = "%s  ·  %d attempts left",
        ErrValidate = "Error validating the key", ErrServer = "Could not reach the key server",
        NotConfigured = "Key system not configured", TryAgain = "You can try again.",
        PasteFirst = "Paste a key first.", Granted = "Access granted. Welcome!",
        Expired = "Your saved key expired. Get a new one.", ConnError = "Connection error, try again.",
        TooMany = "Too many attempts. Wait %d seconds.", Invalid = "Invalid key.",
        LinkCopied = "Key link copied to clipboard.", Link = "Link: %s", NoLink = "No key link configured.",
        DiscordCopied = "Discord invite copied.", Checking = "Checking your saved key...", Welcome = "Welcome, %s.",
    },
}
-- Paleta Soft UI (igual que el tema "Kato" de Kato Lib v3)
-- Paleta Soft UI con contraste: identica al tema "Kato" de Kato Lib v3.1 / v3.2 (sin Library se usa esta)
local DefaultTheme = {
    Background = rgb(220, 224, 236),   -- #DCE0EC ventana
    Card = rgb(227, 230, 241),         -- #E3E6F1 botones elevados
    Inset = rgb(205, 210, 227),        -- #CDD2E3 campos hundidos
    Track = rgb(197, 202, 220),
    Light = WHITE, Shadow = rgb(169, 176, 203), Knob = WHITE,
    Edge = rgb(119, 125, 156),         -- borde de controles (>= 3:1)
    WindowStroke = rgb(195, 200, 218),
    Accent = rgb(123, 97, 255),
    AccentStrong = rgb(111, 87, 230),  -- fondo del boton primario (texto blanco >= 4.5:1)
    AccentHover = rgb(98, 78, 204),
    AccentText = rgb(92, 73, 191),
    AccentSoft = rgb(226, 220, 255),
    Accent2Soft = rgb(226, 220, 255), Accent2Text = rgb(92, 73, 191), -- segundo acento = primero en el default
    Accent2 = rgb(123, 97, 255), OnAccent = WHITE, Black = BLACK, White = WHITE,
    Text = rgb(35, 39, 61), Muted = rgb(84, 89, 120), Dim = rgb(130, 136, 166),
    Success = rgb(36, 140, 92), Warning = rgb(196, 118, 12), Error = rgb(229, 72, 77),
    DangerSoft = rgb(249, 220, 226), DangerText = rgb(190, 38, 46),
}

local Space = { XS = 4, S = 8, M = 12, L = 16, XL = 20, XXL = 24, XXXL = 32 }
local Motion = { Fast = 0.15, Base = 0.2, Slow = 0.3 }
local Level = {
    Window      = { Offset = 10, Blur = 26, Dark = 0.42, Light = 0, DarkKey = "Black" },
    Control     = { Offset = 3, LightOffset = 3, Blur = 6, Dark = 0.62, Light = 0.95 },
    ControlLift = { Offset = 4, LightOffset = 4, Blur = 8, Dark = 0.72, Light = 1 },
    Flat        = { Offset = 0, Blur = 0, Dark = 0, Light = 0 },
}
local CONTROL_EDGES = true -- borde de 1 px en input y botones secundarios (como Theme.ControlEdges de Kato Lib)

-- Builder Sans con pesos reales; si no existe se usa Gotham
local function face(enumFont, weight)
    local ok, f = pcall(function() return Font.new(Font.fromEnum(enumFont).Family, weight) end)
    if ok and f then return f end
    return Font.fromEnum(Enum.Font.GothamMedium)
end
local Fonts = {
    Bold = face(Enum.Font.BuilderSans, Enum.FontWeight.Bold),
    Semi = face(Enum.Font.BuilderSans, Enum.FontWeight.SemiBold),
    Medium = face(Enum.Font.BuilderSans, Enum.FontWeight.Medium),
    Regular = face(Enum.Font.BuilderSans, Enum.FontWeight.Regular),
    Mono = face(Enum.Font.RobotoMono, Enum.FontWeight.Medium),
}
-- nombres antiguos
Fonts.Title, Fonts.Body = Fonts.Bold, Fonts.Medium

local function create(class, props, children)
    local inst = Instance.new(class)
    if inst:IsA("GuiObject") then inst.BorderSizePixel = 0 end
    if inst:IsA("GuiButton") then inst.AutoButtonColor = false end
    if class == "TextButton" or class == "TextLabel" or class == "TextBox" then
        inst.Text = ""
        inst.FontFace = Fonts.Medium
    end
    if class == "TextLabel" or class == "ImageLabel" then inst.BackgroundTransparency = 1 end
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    if parent then inst.Parent = parent end
    return inst
end

local function tween(obj, props, t, style, dir)
    if not t or t <= 0 then
        for k, v in pairs(props) do obj[k] = v end
        return
    end
    local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function corner(p, r) return create("UICorner", { CornerRadius = r == true and UDim.new(1, 0) or UDim.new(0, r or 12), Parent = p }) end
local function nseq(points)
    local k = {}
    for i, p in ipairs(points) do k[i] = NumberSequenceKeypoint.new(p[1], p[2]) end
    return NumberSequence.new(k)
end
local function trim(s) return (tostring(s or ""):match("^%s*(.-)%s*$")) end
local function isPress(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function copy(text)
    local fn = setclipboard or toclipboard or (syn and syn.write_clipboard)
    if type(fn) == "function" then return pcall(fn, text) end
    return false
end
local function hash(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + string.byte(s, i)) % 4294967296 end
    return string.format("%08x", h)
end
local function hasFS()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
        and type(makefolder) == "function" and type(isfolder) == "function"
end

-- ===== Sombras Soft UI =====
-- Una sombra = caja (mismo tamano que la cara, desplazada) con capas concentricas o un 9-slice.
local function newShadow(holder, color, blur, radius)
    local box = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0, Parent = holder })
    local sh = { box = box, layers = {} }
    if SHADOW_IMAGE ~= "" then
        local img = create("ImageLabel", {
            Image = SHADOW_IMAGE, ImageColor3 = color, ImageTransparency = 1,
            ScaleType = Enum.ScaleType.Slice, SliceCenter = SHADOW_SLICE,
            SliceScale = math.max(blur, 1) / 12,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, SHADOW_EDGE * 2 * math.max(blur, 1) / 12, 1, SHADOW_EDGE * 2 * math.max(blur, 1) / 12),
            ZIndex = 0, Parent = box,
        })
        sh.image = img
        return sh
    end
    local n = math.clamp(math.ceil(blur / SHADOW_STEP), 2, SHADOW_MAX_LAYERS)
    for i = 1, n do
        local e = blur * (i - 1) / (n - 1)
        local f = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, e, 1, e), BackgroundColor3 = color, BackgroundTransparency = 1, ZIndex = 0, Parent = box,
        })
        corner(f, radius == true and true or (radius + e / 2))
        sh.layers[i] = f
    end
    return sh
end
local function setShadow(sh, sign, offset, alpha, t)
    tween(sh.box, { Position = UDim2.fromOffset(sign * offset, sign * offset) }, t)
    if sh.image then
        tween(sh.image, { ImageTransparency = 1 - alpha }, t)
        return
    end
    local n = #sh.layers
    local a = alpha <= 0 and 0 or 1 - (1 - math.min(alpha, 0.99)) ^ (1 / n)
    for _, f in ipairs(sh.layers) do tween(f, { BackgroundTransparency = 1 - a }, t) end
end

local function edge(frame, color)
    if not CONTROL_EDGES then return nil end
    return create("UIStroke", { Color = color, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = frame })
end

-- holder transparente + sombra oscura (abajo-der) + sombra clara (arriba-izq) + cara
local function raised(theme, props, radius, level, blur, faceColor)
    props.BackgroundTransparency = 1
    local holder = create("Frame", props)
    local dark = newShadow(holder, theme[level.DarkKey or "Shadow"] or theme.Shadow, blur, radius)
    local light = newShadow(holder, theme.Light, blur, radius)
    local faceFrame = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = faceColor or theme.Card, ZIndex = 1, Parent = holder })
    corner(faceFrame, radius)
    local s = { holder = holder, face = faceFrame }
    function s.set(lv, t)
        setShadow(dark, 1, lv.Offset, lv.Dark, t)
        setShadow(light, -1, lv.LightOffset or lv.Offset, lv.Light, t)
    end
    s.set(level, 0)
    return s
end

-- superficie hundida: relleno Inset + sombra interior arriba y luz abajo (UIGradient) + borde accesible
local function inset(theme, frame, radius)
    frame.BackgroundColor3 = theme.Inset
    corner(frame, radius)
    local top = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = theme.Shadow, ZIndex = 0, Parent = frame })
    corner(top, radius)
    create("UIGradient", { Rotation = 90, Transparency = nseq({ { 0, 0.15 }, { 0.18, 0.53 }, { 0.45, 1 }, { 1, 1 } }), Parent = top })
    local bottom = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = theme.Light, ZIndex = 0, Parent = frame })
    corner(bottom, radius)
    create("UIGradient", { Rotation = 90, Transparency = nseq({ { 0, 1 }, { 0.6, 1 }, { 1, 0.2 } }), Parent = bottom })
    edge(frame, theme.Edge)
    return frame
end

function KeySystem.new(opts)
    opts = opts or {}
    local Theme = {}
    local lib = opts.Library
    for k, v in pairs(DefaultTheme) do Theme[k] = v end
    if lib and type(lib.Theme) == "table" then for k, v in pairs(lib.Theme) do Theme[k] = v end end
    if type(opts.Theme) == "table" then for k, v in pairs(opts.Theme) do Theme[k] = v end end
    if typeof(opts.Accent) == "Color3" then
        Theme.Accent = opts.Accent
        Theme.AccentHover = opts.Accent:Lerp(BLACK, 0.1)
        Theme.AccentSoft = WHITE:Lerp(opts.Accent, 0.25)
    end
    if typeof(opts.Accent) == "Color3" then
        Theme.AccentStrong = opts.Accent:Lerp(BLACK, 0.1)
        Theme.AccentHover = opts.Accent:Lerp(BLACK, 0.2)
        Theme.AccentText = opts.Accent:Lerp(BLACK, 0.25)
    end
    -- Kato Lib v1/v2/v3.1 no tienen todas las llaves: lo que falte se deriva del acento heredado
    -- (no del default), para que un tema de la libreria no quede mezclado con el violeta por defecto
    local src = (lib and type(lib.Theme) == "table") and lib.Theme or {}
    if typeof(src.Accent) == "Color3" and typeof(opts.Accent) ~= "Color3" then
        local a = src.Accent
        if src.AccentStrong == nil then Theme.AccentStrong = a:Lerp(BLACK, 0.1) end
        if src.AccentHover == nil then Theme.AccentHover = a:Lerp(BLACK, 0.2) end
        if src.AccentText == nil then Theme.AccentText = a:Lerp(BLACK, 0.25) end
        if src.AccentSoft == nil then Theme.AccentSoft = WHITE:Lerp(a, 0.22) end
        if src.Accent2 == nil then Theme.Accent2 = a end
    end
    if typeof(opts.Accent2) == "Color3" then
        Theme.Accent2 = opts.Accent2
        Theme.Accent2Text = opts.Accent2:Lerp(BLACK, 0.25)
        Theme.Accent2Soft = WHITE:Lerp(opts.Accent2, 0.16)
    elseif src.Accent2Text == nil and (typeof(opts.Accent) == "Color3" or typeof(src.Accent) == "Color3") then
        -- sin segundo acento propio: sigue al primero (igual que en Kato Lib)
        Theme.Accent2Text, Theme.Accent2Soft = Theme.AccentText, Theme.AccentSoft
    end

    -- primera vez: Kato Lib (v3.6+) pregunta el idioma antes de mostrar la pantalla de key y lo guarda
    if lib and type(lib.AskLanguage) == "function" and opts.Language == nil and opts.AskLanguage ~= false then
        pcall(lib.AskLanguage, lib)
    end
    -- idioma: opts.Language > idioma activo de Kato Lib > espanol
    local langCode = opts.Language or (lib and type(lib.Language) == "string" and lib.Language) or "es"
    local Str = {}
    for k, v in pairs(KeySystem.Languages.en) do Str[k] = v end
    for k, v in pairs(KeySystem.Languages[langCode] or KeySystem.Languages.es) do Str[k] = v end
    if type(opts.Strings) == "table" then for k, v in pairs(opts.Strings) do Str[k] = v end end
    local function tr(v)
        if type(v) ~= "table" then return v ~= nil and tostring(v) or nil end
        local s = v[langCode]
        if s == nil then s = v.en end
        if s == nil then s = v.es end
        return s ~= nil and tostring(s) or nil
    end

    local cfg = {
        Title = tr(opts.Title) or "Kato Hub",
        Subtitle = tr(opts.Subtitle) or Str.Subtitle,
        Icon = opts.Icon or "rbxassetid://110461677380547",
        Description = tr(opts.Description) or Str.Description,
        Folder = opts.Folder or "KatoHub",
        SaveKey = opts.SaveKey ~= false,
        MaxAttempts = opts.MaxAttempts or 5,
        Cooldown = opts.Cooldown or 20,
        CaseSensitive = opts.CaseSensitive ~= false,
    }
    local idSource = opts.Id or opts.KeyUrl or (type(opts.Keys) == "table" and table.concat(opts.Keys, "|")) or cfg.Title
    local keyPath = cfg.Folder .. "/keys/" .. hash(tostring(idSource)) .. ".txt"

    local self = setmetatable({}, KeySystem)
    self.Done, self.Success, self.Key = false, false, nil
    self._event = Instance.new("BindableEvent")
    local conns = {}
    local attempts, busy, locked = 0, false, false

    -- GUI
    local gui = create("ScreenGui", {
        Name = "KatoKeySystem", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 200, IgnoreGuiInset = false,
    })
    do
        local placed = pcall(function()
            local h = gethui and gethui()
            if typeof(h) ~= "Instance" then error("no gethui") end
            local old = h:FindFirstChild("KatoKeySystem")
            if old then old:Destroy() end
            gui.Parent = h
        end)
        if not placed then placed = pcall(function() gui.Parent = game:GetService("CoreGui") end) end
        if not placed then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    end
    self.Gui = gui

    -- velo suave con el color del texto (nunca negro puro sobre un UI claro)
    local dim = create("Frame", {
        Size = UDim2.new(1, 0, 1, 80), Position = UDim2.fromOffset(0, -60),
        BackgroundColor3 = Theme.Text, BackgroundTransparency = 1, Parent = gui,
    })
    tween(dim, { BackgroundTransparency = 0.55 }, Motion.Slow)

    local W, H = 420, 368
    local win = raised(Theme, {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H), Parent = gui,
    }, 20, Level.Flat, Level.Window.Blur, Theme.Background)
    local holder = win.holder
    local card = win.face
    card.ClipsDescendants = true
    local scale = create("UIScale", { Parent = holder })
    local function fit()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        return math.clamp(math.min((vp.X - 24) / W, (vp.Y - 24) / H, 1), 0.5, 1)
    end
    local base = fit()
    scale.Scale = base * 0.96

    -- cabecera: logo suelto (sin caja), titulo y subtitulo
    local icon = create("ImageLabel", {
        Image = cfg.Icon, Position = UDim2.fromOffset(Space.XXL, Space.XXL), Size = UDim2.fromOffset(44, 44), Parent = card,
    })
    corner(icon, Space.M)
    create("TextLabel", {
        Text = cfg.Title, FontFace = Fonts.Bold, TextSize = 20, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(80, 26), Size = UDim2.new(1, -136, 0, 22), Parent = card,
    })
    create("TextLabel", {
        Text = cfg.Subtitle, FontFace = Fonts.Regular, TextSize = 12, TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(80, 50), Size = UDim2.new(1, -136, 0, 14), Parent = card,
    })

    -- boton cerrar: circulo elevado
    local closeS = raised(Theme, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -Space.XXL, 0, 30), Size = UDim2.fromOffset(32, 32), Parent = card,
    }, true, Level.Control, Level.Control.Blur)
    local closeBtn = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = closeS.face })
    local xParts = {}
    for _, r in ipairs({ 45, -45 }) do
        local p = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(11, 2),
            Rotation = r, BackgroundColor3 = Theme.Text, ZIndex = 2, Parent = closeS.face,
        })
        corner(p, true)
        table.insert(xParts, p)
    end
    closeBtn.MouseEnter:Connect(function()
        closeS.set(Level.ControlLift, Motion.Fast)
        for _, p in ipairs(xParts) do tween(p, { BackgroundColor3 = Theme.Error }, Motion.Fast) end
    end)
    closeBtn.MouseLeave:Connect(function()
        closeS.set(Level.Control, Motion.Base)
        for _, p in ipairs(xParts) do tween(p, { BackgroundColor3 = Theme.Text }, Motion.Base) end
    end)
    closeBtn.InputBegan:Connect(function(i) if isPress(i) then closeS.set(Level.Flat, Motion.Fast) end end)
    closeBtn.InputEnded:Connect(function(i) if isPress(i) then closeS.set(Level.Control, Motion.Base) end end)

    create("TextLabel", {
        Text = cfg.Description, FontFace = Fonts.Regular, TextSize = 13, TextColor3 = Theme.Muted, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.fromOffset(Space.XXL, 88), Size = UDim2.new(1, -Space.XXL * 2, 0, 36), Parent = card,
    })

    -- input hundido
    local inputPos = UDim2.fromOffset(Space.XXL, 132)
    local inputFrame = create("Frame", { Position = inputPos, Size = UDim2.new(1, -Space.XXL * 2, 0, 44), Parent = card })
    inset(Theme, inputFrame, Space.M)
    local glyphRing = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, Space.L, 0.5, 0), Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Theme.Muted, ZIndex = 2, Parent = inputFrame,
    })
    corner(glyphRing, true)
    local glyphHole = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(4, 4),
        BackgroundColor3 = Theme.Inset, ZIndex = 3, Parent = glyphRing,
    })
    corner(glyphHole, true)
    local glyphStem = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 25, 0.5, 0), Size = UDim2.fromOffset(9, 2),
        BackgroundColor3 = Theme.Muted, ZIndex = 2, Parent = inputFrame,
    })
    local function glyph(color, t)
        tween(glyphRing, { BackgroundColor3 = color }, t)
        tween(glyphStem, { BackgroundColor3 = color }, t)
    end
    local box = create("TextBox", {
        Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -56, 1, 0), BackgroundTransparency = 1,
        PlaceholderText = tr(opts.Placeholder) or Str.Placeholder, PlaceholderColor3 = Theme.Muted,
        TextColor3 = Theme.Text, FontFace = Fonts.Mono, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2, Parent = inputFrame,
    })
    box.Focused:Connect(function() glyph(Theme.Accent, Motion.Base) end)
    box.FocusLost:Connect(function() glyph(Theme.Muted, Motion.Base) end)

    local status = create("TextLabel", {
        Text = "", FontFace = Fonts.Regular, TextSize = 12, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(Space.XXL + 2, 184), Size = UDim2.new(1, -Space.XXL * 2, 0, 16), RichText = true, Parent = card,
    })
    local function setStatus(text, color)
        status.Text = text or ""
        status.TextColor3 = color or Theme.Muted
        status.TextTransparency = 1
        tween(status, { TextTransparency = 0 }, Motion.Base)
    end

    -- boton primario: morado solido, texto blanco
    local verifyS = raised(Theme, {
        Position = UDim2.fromOffset(Space.XXL, 210), Size = UDim2.new(1, -Space.XXL * 2, 0, 44), Parent = card,
    }, Space.M, Level.Control, Level.Control.Blur)
    verifyS.face.BackgroundColor3 = Theme.AccentStrong
    local verify = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = verifyS.face })
    local vText = create("TextLabel", {
        Text = Str.Verify, FontFace = Fonts.Semi, TextSize = 14, TextColor3 = Theme.OnAccent,
        Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = verifyS.face,
    })
    -- indicador de carga: tres puntos que respiran (sin glow)
    local dots = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, -66, 0.5, 0), Size = UDim2.fromOffset(28, 6),
        BackgroundTransparency = 1, Visible = false, ZIndex = 2, Parent = verifyS.face,
    })
    local dotList = {}
    for i = 1, 3 do
        local d = create("Frame", {
            Position = UDim2.fromOffset((i - 1) * 11, 0), Size = UDim2.fromOffset(6, 6),
            BackgroundColor3 = Theme.OnAccent, ZIndex = 2, Parent = dots,
        })
        corner(d, true)
        dotList[i] = d
    end
    local verifyColor = Theme.AccentStrong
    verify.MouseEnter:Connect(function()
        if locked or busy then return end
        verifyS.set(Level.ControlLift, Motion.Fast)
        tween(verifyS.face, { BackgroundColor3 = verifyColor == Theme.AccentStrong and Theme.AccentHover or verifyColor }, Motion.Fast)
    end)
    verify.MouseLeave:Connect(function()
        verifyS.set(Level.Control, Motion.Base)
        tween(verifyS.face, { BackgroundColor3 = verifyColor }, Motion.Base)
    end)
    verify.InputBegan:Connect(function(i) if isPress(i) then verifyS.set(Level.Flat, Motion.Fast) end end)
    verify.InputEnded:Connect(function(i) if isPress(i) then verifyS.set(Level.Control, Motion.Base) end end)

    -- botones secundarios: neutros elevados
    local function secondary(pos, size, text)
        local s = raised(Theme, { Position = pos, Size = size, Parent = card }, Space.M, Level.Control, Level.Control.Blur)
        local b = create("TextButton", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = text,
            FontFace = Fonts.Semi, TextSize = 14, TextColor3 = Theme.Text, ZIndex = 2, Parent = s.face,
        })
        edge(s.face, Theme.Edge)
        b.MouseEnter:Connect(function() s.set(Level.ControlLift, Motion.Fast) tween(b, { TextColor3 = Theme.AccentText }, Motion.Fast) end)
        b.MouseLeave:Connect(function() s.set(Level.Control, Motion.Base) tween(b, { TextColor3 = Theme.Text }, Motion.Base) end)
        b.InputBegan:Connect(function(i) if isPress(i) then s.set(Level.Flat, Motion.Fast) end end)
        b.InputEnded:Connect(function(i) if isPress(i) then s.set(Level.Control, Motion.Base) end end)
        return b
    end
    local hasDiscord = opts.DiscordLink ~= nil
    local getKey, discord
    if hasDiscord then
        getKey = secondary(UDim2.fromOffset(Space.XXL, 270), UDim2.new(0.5, -(Space.XXL + Space.S - 2), 0, 40), Str.GetKey)
        discord = secondary(UDim2.new(0.5, Space.S - 2, 0, 270), UDim2.new(0.5, -(Space.XXL + Space.S - 2), 0, 40), Str.Discord)
    else
        getKey = secondary(UDim2.fromOffset(Space.XXL, 270), UDim2.new(1, -Space.XXL * 2, 0, 40), Str.GetKey)
    end

    local footer = create("TextLabel", {
        Text = "", FontFace = Fonts.Regular, TextSize = 11, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.new(0, Space.XXL, 1, -36), Size = UDim2.new(1, -Space.XXL * 2, 0, 16), Parent = card,
    })
    local function updateFooter()
        local left = cfg.MaxAttempts - attempts
        footer.Text = left == 1 and string.format(Str.AttemptsOne, cfg.Title) or string.format(Str.AttemptsMany, cfg.Title, left)
    end
    updateFooter()

    -- velo para la salida (la cara se funde con el fondo antes de ocultarse)
    local veil = create("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Background, BackgroundTransparency = 1,
        Visible = false, ZIndex = 50, Parent = card,
    })
    corner(veil, 20)

    local clock = 0
    table.insert(conns, RunService.RenderStepped:Connect(function(dt)
        if not dots.Visible then return end
        clock = clock + dt
        for i, d in ipairs(dotList) do
            d.BackgroundTransparency = 0.2 + 0.6 * (0.5 + 0.5 * math.sin(clock * 6 - i))
        end
    end))

    -- entrada: escala sutil y la sombra aparece (sin rebotes)
    tween(scale, { Scale = base }, Motion.Slow)
    win.set(Level.Window, Motion.Slow)

    -- arrastre desde la cabecera
    do
        local start, startPos
        card.InputBegan:Connect(function(i)
            if not isPress(i) then return end
            if i.Position.Y - card.AbsolutePosition.Y > 80 * scale.Scale then return end
            start, startPos = i.Position, holder.Position
        end)
        table.insert(conns, UserInputService.InputChanged:Connect(function(i)
            if not start then return end
            if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                local d = i.Position - start
                tween(holder, { Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) }, 0.08)
            end
        end))
        table.insert(conns, UserInputService.InputEnded:Connect(function(i) if isPress(i) then start = nil end end))
    end

    -- logica
    local function shake()
        glyph(Theme.Error, 0.1)
        task.spawn(function()
            for _, dx in ipairs({ -8, 7, -5, 4, -2, 0 }) do
                tween(inputFrame, { Position = inputPos + UDim2.fromOffset(dx, 0) }, 0.05)
                task.wait(0.05)
            end
            task.wait(0.5)
            if not box:IsFocused() then glyph(Theme.Muted, Motion.Slow) end
        end)
    end

    local function setLoading(on)
        busy = on
        dots.Visible = on
        vText.Text = on and Str.Verifying or Str.Verify
    end

    local function saveKey(k)
        if not cfg.SaveKey or not hasFS() then return end
        pcall(function()
            if not isfolder(cfg.Folder) then makefolder(cfg.Folder) end
            if not isfolder(cfg.Folder .. "/keys") then makefolder(cfg.Folder .. "/keys") end
            writefile(keyPath, k)
        end)
    end
    local function readSaved()
        if not cfg.SaveKey or not hasFS() then return nil end
        local ok, k = pcall(function() if isfile(keyPath) then return readfile(keyPath) end end)
        k = ok and trim(k) or nil
        return (k and k ~= "") and k or nil
    end
    local function clearSaved()
        if hasFS() and type(delfile) == "function" then pcall(function() if isfile(keyPath) then delfile(keyPath) end end) end
    end

    local cache, cacheAt = nil, 0
    local function norm(k) return cfg.CaseSensitive and k or string.lower(k) end
    -- devuelve: ok, mensaje, transitorio (error de red: no gasta intentos)
    local function check(key)
        if type(opts.Validate) == "function" then
            local ok, a, b = pcall(opts.Validate, key)
            if not ok then return false, Str.ErrValidate, true end
            return a == true, b
        end
        local list = opts.Keys
        if opts.KeyUrl then
            if cache and os.clock() - cacheAt < 30 then
                list = cache
            else
                local ok, body = pcall(function() return game:HttpGet(opts.KeyUrl) end)
                if not ok then return false, Str.ErrServer, true end
                list = {}
                for line in tostring(body):gmatch("[^\r\n]+") do
                    local k = trim(line)
                    if k ~= "" then table.insert(list, k) end
                end
                cache, cacheAt = list, os.clock()
            end
        end
        if type(list) ~= "table" then return false, Str.NotConfigured, true end
        local want = norm(key)
        for _, k in ipairs(list) do if norm(tostring(k)) == want then return true end end
        return false
    end

    local function cleanup()
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        pcall(function() gui:Destroy() end)
    end
    local function outro(after)
        tween(scale, { Scale = base * 0.96 }, Motion.Base, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        win.set(Level.Flat, Motion.Base)
        veil.Visible = true
        tween(veil, { BackgroundTransparency = 0 }, Motion.Fast)
        tween(dim, { BackgroundTransparency = 1 }, Motion.Slow)
        task.delay(Motion.Base, function() holder.Visible = false end)
        task.delay(Motion.Slow + 0.02, function()
            cleanup()
            if after then after() end
        end)
    end
    local function finish(success, key)
        if self.Done then return end
        self.Done, self.Success, self.Key = true, success, key
        self._event:Fire(success, key)
    end

    local function startCooldown()
        locked = true
        task.spawn(function()
            for s = cfg.Cooldown, 1, -1 do
                if self.Done then return end
                vText.Text = string.format(Str.Locked, s)
                verifyColor = Theme.Inset
                verifyS.face.BackgroundColor3 = Theme.Inset
                vText.TextColor3 = Theme.Muted
                verifyS.set(Level.Flat, 0)
                task.wait(1)
            end
            locked = false
            attempts = 0
            updateFooter()
            vText.Text = Str.Verify
            verifyColor = Theme.AccentStrong
            verifyS.face.BackgroundColor3 = Theme.AccentStrong
            vText.TextColor3 = Theme.OnAccent
            verifyS.set(Level.Control, Motion.Base)
            setStatus(Str.TryAgain, Theme.Muted)
        end)
    end

    local function submit(key, auto)
        key = trim(key)
        if busy or locked or self.Done then return end
        if key == "" then
            setStatus(Str.PasteFirst, Theme.Warning)
            shake()
            return
        end
        setLoading(true)
        local ok, msg, transient = check(key)
        setLoading(false)
        if ok then
            saveKey(key)
            setStatus(Str.Granted, Theme.Success)
            vText.Text = Str.Unlocked
            verifyColor = Theme.Success
            tween(verifyS.face, { BackgroundColor3 = Theme.Success }, Motion.Base)
            glyph(Theme.Success, Motion.Base)
            task.delay(0.7, function()
                outro(function()
                    if type(opts.OnSuccess) == "function" then task.spawn(opts.OnSuccess, key) end
                    finish(true, key)
                end)
            end)
            return
        end
        if auto then
            clearSaved()
            setStatus(Str.Expired, Theme.Warning)
            return
        end
        shake()
        if transient then
            setStatus(msg or Str.ConnError, Theme.Warning)
            return
        end
        attempts = attempts + 1
        updateFooter()
        if type(opts.OnFail) == "function" then task.spawn(opts.OnFail, key, msg) end
        if attempts >= cfg.MaxAttempts then
            setStatus(string.format(Str.TooMany, cfg.Cooldown), Theme.Error)
            startCooldown()
        else
            setStatus(tr(msg) or Str.Invalid, Theme.Error)
        end
    end

    verify.MouseButton1Click:Connect(function() submit(box.Text) end)
    box.FocusLost:Connect(function(enter) if enter then submit(box.Text) end end)
    getKey.MouseButton1Click:Connect(function()
        if opts.KeyLink and copy(opts.KeyLink) then
            setStatus(Str.LinkCopied, Theme.AccentText)
        elseif opts.KeyLink then
            setStatus(string.format(Str.Link, opts.KeyLink), Theme.Muted)
        else
            setStatus(Str.NoLink, Theme.Warning)
        end
    end)
    if discord then
        discord.MouseButton1Click:Connect(function()
            if copy(opts.DiscordLink) then setStatus(Str.DiscordCopied, Theme.Accent2Text)
            else setStatus(opts.DiscordLink, Theme.Muted) end
        end)
    end
    local function closeUI()
        if self.Done then return end
        outro(function()
            if type(opts.OnClose) == "function" then task.spawn(opts.OnClose) end
            finish(false, nil)
        end)
    end
    closeBtn.MouseButton1Click:Connect(closeUI)

    function self:Wait()
        if not self.Done then self._event.Event:Wait() end
        return self.Success, self.Key
    end
    function self:SetStatus(text, kind)
        setStatus(text, Theme[kind or "Muted"] or Theme.Muted)
    end
    function self:Close() closeUI() end
    function self:Destroy() cleanup() finish(false, nil) end

    -- key guardada: se verifica sola
    local saved = readSaved()
    if saved then
        box.Text = saved
        setStatus(Str.Checking, Theme.Muted)
        task.delay(0.5, function() submit(saved, true) end)
    else
        setStatus(string.format(Str.Welcome, LocalPlayer.DisplayName), Theme.Muted)
    end
    return self
end

function KeySystem.Prompt(opts)
    return KeySystem.new(opts):Wait()
end

return KeySystem
