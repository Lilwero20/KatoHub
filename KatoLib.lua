--[[
    Kato Lib  v3.5.0
    Libreria de UI para Kato Hub (Roblox / Luau). Estilo Soft UI (neumorphism claro) con contraste:
    3 niveles de superficie (Sidebar < Background < Card), sombras marcadas y bordes accesibles
    (texto >= 4.5:1, bordes de controles >= 3:1). Ver Theme.ControlEdges.

    USO RAPIDO
        local Kato = loadstring(game:HttpGet("URL/KatoLib.lua"))()
        local Window = Kato:CreateWindow({
            Title = "Kato Hub", Subtitle = "v3.0 Premium",
            Icon = "rbxassetid://110461677380547",
            ToggleKey = Enum.KeyCode.RightShift, Folder = "KatoHub",
        })
        Window:AddCategory("Main")
        local Home = Window:CreateTab({ Name = "Home", Icon = "home", Description = "Welcome to Kato Hub" })
        local Farm = Home:CreateSection({ Name = "Farming", Icon = "bolt", Description = "Automate your progress" })
        Farm:AddToggle({ Name = "Auto Farm", Icon = "target", Flag = "AutoFarm", Callback = function(v) end })

    ICONOS
        Icon acepta un nombre del set integrado (Kato:GetIcons()), un rbxassetid / numero, o 1-2 letras.

    SECCIONES
        Tab:CreateSection({ Name, Description, Icon, Side = "Left"|"Right", Wide = true })

    ELEMENTOS (Section)
        AddButton, AddToggle, AddSlider, AddDropdown, AddInput (AddTextbox/AddTextBox), AddKeybind,
        AddColorPicker, AddProgress, AddLabel, AddParagraph, AddDivider
        Opciones comunes: Name, Description, Icon, Flag, Tooltip, Disabled, Callback
        Objetos: :Set(v) :Get() :SetVisible(b) :SetDisabled(b) :OnChanged(fn) :Destroy()

    WINDOW
        CreateTab, AddCategory, SelectTab, GetTab, Notify, Dialog, Toggle/Show/Hide/SetVisible,
        SetTitle, SetSubtitle, SetGlass, SetGlassStrength, SetBlur, SetScale, SetToggleKey,
        CreateSettingsTab, CreateWatermark, SaveConfig, LoadConfig, DeleteConfig, GetConfigs,
        SetAutoload, GetAutoload, LoadAutoloadConfig, Destroy

    LIBRERIA
        Kato:Notify, Kato:SetTheme(nombre|tabla), Kato:SetAccent(c1, c2), Kato:GetThemes(),
        Kato:AddTheme(nombre, tabla), Kato:GetIcons(), Kato:OnUnload(fn), Kato:Unload(), Kato.Flags
        Kato.Style  -> tabla Theme completa (colores, radios, espacios, textos, tiempos, sombras)
        Kato.Theme  -> solo los colores (compatibilidad con v1/v2)
        Kato.Neu    -> helpers de sombras (Neu.raised, Neu.inset) para tus propios elementos

    BARRA (v3.5)
        Window:CreateWatermark() crea la barra (logo, fps, ping, hora) arriba al centro. Con el menu abierto se
        oculta; al minimizar, la ventana se transforma en la barra y un click en ella la vuelve a abrir (reemplaza
        al boton flotante). Al pasar el raton aparece una flecha; al minimizar la barra rebota con una onda de acento.
        CreateWatermark({ Toggle = false }) = barra fija solo informativa, como antes.
        Otras opciones: Position, AnchorPoint, Text, FPS, Ping, Time.

    IDIOMAS (v3.3)
        La interfaz sale en espanol por defecto. CreateWindow({ Language = "en" }) cambia el idioma inicial;
        lo que el jugador elija en Ajustes > Idioma se guarda en settings.json y tiene prioridad.
        Cualquier texto (Name, Description, Title, Content, Placeholder, Tooltip, Badge, AddCategory,
        AddDivider, AddLabel...) acepta un string o una tabla de traducciones:
            Farm:AddToggle({ Name = { es = "Granjeo automatico", en = "Auto Farm" }, Flag = "AutoFarm" })
        Dropdowns: el valor no cambia, solo lo que se ve -> Labels = { Nearest = { es = "Mas cercano", en = "Nearest" } }
        Kato:SetLanguage("en"), Kato:GetLanguage(), Kato:GetLanguages(), Kato:GetLanguageName(code),
        Kato:AddLanguage("pt", "Portugues", { None = "Nenhum", ... }), Kato:OnLanguageChanged(fn), Kato:Tr(texto)
    TEMAS
        "Kato" (por defecto) y "Orchid" (lila + violeta + fucsia), ademas de Sakura, Mint, Ocean, Sand,
        Graphite y Midnight. Accent2 es el segundo acento (badges, barra de progreso, notificaciones Info);
        si un tema no lo define vale lo mismo que Accent y se ve igual que con un solo acento.

    SOMBRAS
        Roblox no tiene box-shadow. Por defecto cada sombra se dibuja con Frames redondeados
        concentricos (uno cada SHADOW_STEP px de difuminado; no hace falta ningun asset). Si quieres un difuminado mas fino, sube esta imagen
        y pon su id en SHADOW_IMAGE:
          - PNG de 160 x 160 px con fondo transparente.
          - Un cuadrado blanco (#FFFFFF) de 96 x 96 px centrado (32 px de margen a cada lado),
            con esquinas redondeadas de 16 px.
          - Desenfoque gaussiano de 12 px de radio. El difuminado tiene que acabar antes del borde.
          - SliceCenter = Rect.new(64, 64, 96, 96)  (la zona central queda totalmente opaca).
        La libreria tine la imagen con ImageColor3 (blanco para la luz, #A9B0CB para la sombra).
]]

local SHADOW_IMAGE = ""                         -- rbxassetid de la sombra 9-slice (opcional, ver arriba)
local SHADOW_SLICE = Rect.new(64, 64, 96, 96)   -- SliceCenter de esa imagen
local SHADOW_EDGE = 32                          -- px entre el borde de la imagen y el de la forma
local SHADOW_STEP = 2.5                         -- sin imagen: px de difuminado por capa (menos = mas suave)
local SHADOW_MAX_LAYERS = 10                    -- tope de capas por sombra
local DEFAULT_ICON = "rbxassetid://110461677380547"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local Kato = {
    Version = "3.5.0",
    Flags = {},
    Windows = {},
    Unloaded = false,
    CurrentTheme = "Kato",
    _conns = {},
    _onUnload = {},
    _binding = false,
}
Kato.Options = Kato.Flags

Kato.Config = {
    Animations = true,
    AnimationSpeed = 1,
    Folder = "KatoHub",
    Notify = { Duration = 4, Width = 320, Max = 5 },
    Tooltip = { Enabled = true, Delay = 0.4 },
    Dropdown = { MaxVisible = 6, SearchAt = 8 },
}

----------------------------------------------------------------------------------------------------
-- IDIOMAS
--   Kato.Strings tiene los textos internos del idioma activo (la misma tabla de siempre).
--   Cualquier texto de la API (Name, Description, Title, Content, Placeholder, Tooltip, Badge...)
--   acepta un string o una tabla de traducciones: { es = "Velocidad", en = "Speed" }.
--   Kato:SetLanguage("en") cambia todo en vivo. Para traducir textos internos edita Kato.Languages.
----------------------------------------------------------------------------------------------------
Kato.Language = "es"
Kato.LanguageOrder = { "es", "en" }
Kato.LanguageNames = { es = "Español", en = "English" }
Kato.Languages = {
    es = {
        None = "Ninguno", Search = "Buscar...", SearchTab = "Buscar...",
        Confirm = "Haz clic otra vez para confirmar", Listening = "Pulsa una tecla",
        CloseTitle = "¿Cerrar Kato Hub?", CloseBody = "La interfaz se descargará. Vuelve a ejecutar el script para abrirla.",
        Cancel = "Cancelar", Close = "Cerrar", Hidden = "Pulsa %s para volver a abrir el menú",
        HiddenBar = "Haz clic en la barra de arriba o pulsa %s para volver a abrir el menú", OpenMenu = "Abrir el menú",
        Selected = "%d seleccionados", NoResults = "Sin resultados",
        -- pestaña de ajustes
        Settings = "Ajustes", SettingsDesc = "Interfaz, tema y configuraciones",
        Appearance = "Apariencia", AppearanceDesc = "Tema, color e idioma",
        Theme = "Tema", Accent = "Color", Language = "Idioma", LanguageDesc = "Cambia el idioma de todo el menú",
        Translucent = "Ventana translúcida", Translucency = "Transparencia",
        Blur = "Desenfoque", BlurDesc = "Con el menú abierto",
        Interface = "Interfaz", InterfaceDesc = "Escala, animaciones y teclas",
        UIScale = "Tamaño de la interfaz", Animations = "Animaciones", Tooltips = "Ayudas al pasar el ratón",
        MenuKey = "Tecla del menú",
        Configs = "Configuraciones", ConfigsDesc = "Guarda y carga tus ajustes",
        ConfigName = "Nombre", ConfigPlaceholder = "mi-config", Saved = "Guardadas", Autoload = "Carga automática",
        SaveConfig = "Guardar configuración", LoadConfig = "Cargar configuración", SetAutoload = "Cargar al iniciar",
        RefreshList = "Actualizar lista", DeleteConfig = "Borrar configuración",
        ConfigSaved = "Configuración guardada", ConfigLoaded = "Configuración cargada", ConfigDeleted = "Configuración borrada",
        Error = "Error", AutoloadSet = "%s se cargará al iniciar",
        About = "Acerca de", AboutBody = "Hecho para <b>%s</b>. Pulsa <b>%s</b> para mostrar u ocultar el menú.",
        Unload = "Cerrar la interfaz",
        InvalidName = "Nombre no válido", NoFiles = "Tu executor no tiene funciones de archivos",
        WriteFailed = "No se pudo guardar el archivo", NotFound = "No se encontró la configuración",
    },
    en = {
        None = "None", Search = "Search...", SearchTab = "Search...",
        Confirm = "Click again to confirm", Listening = "Press a key",
        CloseTitle = "Close Kato Hub?", CloseBody = "The interface will be unloaded. Run the script again to reopen it.",
        Cancel = "Cancel", Close = "Close", Hidden = "Press %s to open the menu again",
        HiddenBar = "Click the bar at the top or press %s to open the menu again", OpenMenu = "Open the menu",
        Selected = "%d selected", NoResults = "No results",
        Settings = "Settings", SettingsDesc = "Interface, theme and configs",
        Appearance = "Appearance", AppearanceDesc = "Theme, color and language",
        Theme = "Theme", Accent = "Accent color", Language = "Language", LanguageDesc = "Changes the language of the whole menu",
        Translucent = "Translucent window", Translucency = "Translucency",
        Blur = "Blur background", BlurDesc = "Blurs the game while the menu is open",
        Interface = "Interface", InterfaceDesc = "Scale, motion and keys",
        UIScale = "UI scale", Animations = "Animations", Tooltips = "Tooltips",
        MenuKey = "Menu key",
        Configs = "Configs", ConfigsDesc = "Save and load your settings",
        ConfigName = "Config name", ConfigPlaceholder = "my-config", Saved = "Saved", Autoload = "Autoload",
        SaveConfig = "Save config", LoadConfig = "Load config", SetAutoload = "Set as autoload",
        RefreshList = "Refresh list", DeleteConfig = "Delete config",
        ConfigSaved = "Config saved", ConfigLoaded = "Config loaded", ConfigDeleted = "Config deleted",
        Error = "Error", AutoloadSet = "%s will load automatically",
        About = "About", AboutBody = "Made for <b>%s</b>. Press <b>%s</b> to toggle the menu.",
        Unload = "Unload interface",
        InvalidName = "Invalid name", NoFiles = "Your executor has no file functions",
        WriteFailed = "Could not write the file", NotFound = "Config not found",
    },
}
-- textos internos del idioma activo (puedes cambiarlos en caliente; SetLanguage los reemplaza)
Kato.Strings = {}
for k, v in pairs(Kato.Languages.es) do Kato.Strings[k] = v end

-- resuelve un texto: string, tabla de traducciones, referencia a Kato.Strings (__s) o funcion (__f)
local function tr(v)
    if v == nil then return nil end
    if type(v) ~= "table" then return tostring(v) end
    if v.__s then return tostring(Kato.Strings[v.__s] or v.__s) end
    if v.__f then
        local ok, s = pcall(v.__f)
        return ok and tostring(s or "") or ""
    end
    local s = v[Kato.Language]
    if s == nil then s = v.en end
    if s == nil then s = v.es end
    if s == nil then for _, x in pairs(v) do s = x break end end
    return tostring(s or "")
end
-- normaliza un parametro de texto: deja las tablas (traducibles) y convierte el resto a string
local function txt(v, default)
    if v == nil then return default end
    if type(v) == "table" then return v end
    return tostring(v)
end
-- true si la tabla es un texto traducible ({ es = ..., en = ... }, SK o TF) y no una tabla de opciones
local function isTrText(v)
    if type(v) ~= "table" then return false end
    if v.__s ~= nil or v.__f ~= nil then return true end
    for k in pairs(v) do
        if type(k) ~= "string" or not string.match(k, "^%l%l$") then return false end
    end
    return next(v) ~= nil
end
local function SK(key) return { __s = key } end     -- texto interno por llave
local function TF(fn) return { __f = fn } end       -- texto calculado (se recalcula al cambiar idioma)
function Kato:Tr(v) return tr(v) end

-- si se re-ejecuta el script, se descarga la copia anterior
local function genv()
    local ok, g = pcall(function() return getgenv and getgenv() end)
    if ok and type(g) == "table" then return g end
    return _G
end
do
    local prev = genv().__KatoLib
    if type(prev) == "table" and type(prev.Unload) == "function" then pcall(prev.Unload, prev) end
    genv().__KatoLib = Kato
end

----------------------------------------------------------------------------------------------------
-- THEME: todos los valores de diseno viven aqui. Los componentes no usan numeros sueltos.
----------------------------------------------------------------------------------------------------
local rgb = Color3.fromRGB
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)

-- Variantes del acento. Accent se usa en rellenos sin texto (toggle, slider, progreso, logo);
-- AccentStrong es el fondo del boton primario (texto blanco >= 4.5:1); AccentText es el acento
-- usado COMO texto sobre superficies claras (>= 4.5:1 incluso sobre AccentSoft).
local function accentKeys(c, accent, dark)
    c.Accent = accent
    c.AccentStrong = dark and accent or accent:Lerp(BLACK, 0.1)
    c.AccentHover = dark and accent:Lerp(WHITE, 0.12) or accent:Lerp(BLACK, 0.2)
    c.AccentText = dark and accent:Lerp(WHITE, 0.3) or accent:Lerp(BLACK, 0.25)
    c.AccentSoft = dark and c.Background:Lerp(accent, 0.28) or WHITE:Lerp(accent, 0.22)
    c.Accent2 = c.Accent2 or accent
    return c
end

-- Segundo acento (badges, barra de progreso, notificaciones Info). Si es igual al primero, sus variantes
-- son exactamente las del primero: los temas que no lo definen se ven igual que antes.
local function accent2Keys(c, dark)
    local a2 = c.Accent2 or c.Accent
    c.Accent2 = a2
    local a1 = c.Accent
    if a2.R == a1.R and a2.G == a1.G and a2.B == a1.B then
        c.Accent2Soft, c.Accent2Text = c.AccentSoft, c.AccentText
    else
        c.Accent2Text = dark and a2:Lerp(WHITE, 0.3) or a2:Lerp(BLACK, 0.25)
        c.Accent2Soft = dark and c.Background:Lerp(a2, 0.28) or WHITE:Lerp(a2, 0.16)
    end
    return c
end

-- Cada paleta sale de 3 colores (fondo de ventana, acento, texto). De ahi salen 3 niveles de superficie
-- (Sidebar < Background < Card), los hundidos (Inset, Track), la luz/sombra y los bordes accesibles.
-- `over` permite fijar valores exactos (el tema Kato los usa).
local function makeTheme(bg, accent, text, dark, over)
    local danger = rgb(229, 72, 77)
    local c
    if dark then
        c = {
            Background = bg, Sidebar = bg:Lerp(BLACK, 0.22), Card = bg:Lerp(WHITE, 0.06),
            Inset = bg:Lerp(BLACK, 0.28), Track = bg:Lerp(WHITE, 0.16),
            Light = bg:Lerp(WHITE, 0.1), Shadow = bg:Lerp(BLACK, 0.62), Knob = bg:Lerp(WHITE, 0.85),
            Edge = bg:Lerp(WHITE, 0.42), WindowStroke = bg:Lerp(WHITE, 0.14),
            Text = text, Muted = text:Lerp(bg, 0.32), Caption = text:Lerp(bg, 0.32), Dim = text:Lerp(bg, 0.55),
            DangerSoft = bg:Lerp(danger, 0.25), DangerText = rgb(255, 128, 132),
        }
    else
        c = {
            Background = bg, Sidebar = bg:Lerp(text, 0.045), Card = bg:Lerp(WHITE, 0.2),
            Inset = bg:Lerp(text, 0.08), Track = bg:Lerp(text, 0.12),
            Light = WHITE, Shadow = bg:Lerp(text, 0.27), Knob = WHITE,
            Edge = bg:Lerp(text, 0.55), WindowStroke = bg:Lerp(text, 0.14),
            Text = text, Muted = text:Lerp(bg, 0.24), Caption = text:Lerp(bg, 0.24), Dim = text:Lerp(bg, 0.5),
            DangerSoft = rgb(249, 220, 226), DangerText = rgb(190, 38, 46),
        }
    end
    c.Surface, c.Element = c.Card, c.Card
    c.Hover = c.Card:Lerp(c.Light, 0.35)
    c.OnAccent, c.White, c.Black = WHITE, WHITE, BLACK
    c.Success, c.Warning, c.Error = rgb(36, 140, 92), rgb(196, 118, 12), danger
    accentKeys(c, accent, dark)
    for k, v in pairs(over or {}) do c[k] = v end
    -- variantes del segundo acento: derivadas salvo que `over` las fije
    local fixed2 = over and (over.Accent2Soft or over.Accent2Text)
    if not fixed2 then accent2Keys(c, dark) end
    -- llaves de compatibilidad (temas y scripts de v1/v2)
    c.Input, c.Stroke, c.StrokeSoft = c.Inset, c.Shadow, c.Track
    return c
end

Kato.Themes = {
    -- valores exactos del tema principal (contrastes verificados, ver README del encabezado)
    Kato = makeTheme(rgb(220, 224, 236), rgb(123, 97, 255), rgb(35, 39, 61), false, {
        Sidebar = rgb(211, 215, 230),      -- #D3D7E6
        Card = rgb(227, 230, 241),         -- #E3E6F1
        Surface = rgb(227, 230, 241), Element = rgb(227, 230, 241), Hover = rgb(236, 238, 246),
        Inset = rgb(205, 210, 227),        -- #CDD2E3
        Track = rgb(197, 202, 220),        -- #C5CADC
        Shadow = rgb(169, 176, 203),       -- #A9B0CB
        Edge = rgb(119, 125, 156),         -- #777D9C  borde de controles (>= 3:1)
        WindowStroke = rgb(195, 200, 218), -- #C3C8DA
        Muted = rgb(84, 89, 120),          -- #545978  (>= 4.5:1 en Card, Sidebar e Inset)
        Caption = rgb(84, 89, 120),
        Dim = rgb(130, 136, 166),          -- #8288A6  solo decorativo / deshabilitado
    }),
    -- Orchid: superficies lila-rosadas, violeta orquidea como acento principal y fucsia como segundo acento
    Orchid = makeTheme(rgb(228, 218, 238), rgb(150, 64, 240), rgb(42, 28, 62), false, {
        Sidebar = rgb(217, 204, 231),      -- #D9CCE7
        Card = rgb(240, 233, 247),         -- #F0E9F7
        Surface = rgb(240, 233, 247), Element = rgb(240, 233, 247), Hover = rgb(246, 241, 251),
        Inset = rgb(214, 201, 229),        -- #D6C9E5
        Track = rgb(204, 189, 223),        -- #CCBDDF
        Shadow = rgb(178, 160, 204),       -- #B2A0CC
        Edge = rgb(128, 100, 164),         -- #8064A4
        WindowStroke = rgb(200, 186, 220), -- #C8BADC
        Muted = rgb(92, 70, 122),          -- #5C467A
        Caption = rgb(92, 70, 122),
        Dim = rgb(140, 120, 168),          -- #8C78A8
        AccentStrong = rgb(138, 54, 228),  -- #8A36E4
        AccentHover = rgb(118, 40, 200),   -- #7628C8
        AccentText = rgb(112, 38, 190),    -- #7026BE
        AccentSoft = rgb(236, 220, 255),   -- #ECDCFF
        Accent2 = rgb(208, 34, 138),       -- #D0228A fucsia
        Accent2Soft = rgb(252, 221, 239),  -- #FCDDEF
        Accent2Text = rgb(172, 20, 110),   -- #AC146E
        DangerSoft = rgb(252, 220, 226), DangerText = rgb(186, 30, 52),
    }),
    Sakura   = makeTheme(rgb(234, 221, 228), rgb(212, 64, 128), rgb(56, 34, 48)),
    Mint     = makeTheme(rgb(214, 228, 223), rgb(20, 140, 102), rgb(26, 48, 42)),
    Ocean    = makeTheme(rgb(214, 223, 236), rgb(40, 104, 226), rgb(24, 36, 62)),
    Sand     = makeTheme(rgb(230, 224, 214), rgb(186, 96, 28), rgb(54, 42, 32)),
    Graphite = makeTheme(rgb(44, 46, 58), rgb(139, 118, 255), rgb(232, 234, 244), true),
    Midnight = makeTheme(rgb(30, 30, 46), rgb(123, 97, 255), rgb(228, 226, 246), true),
}
Kato.ThemeOrder = { "Kato", "Orchid", "Sakura", "Mint", "Ocean", "Sand", "Graphite", "Midnight" }

-- Builder Sans con pesos reales; Gotham como respaldo
local function family(enumName, fallback)
    local ok, f = pcall(function() return Font.fromEnum(Enum.Font[enumName]) end)
    if ok and f then return f.Family end
    return Font.fromEnum(fallback).Family
end
local SANS = family("BuilderSans", Enum.Font.Gotham)
local function weight(w)
    local ok, f = pcall(function() return Font.new(SANS, w) end)
    return ok and f or Font.fromEnum(Enum.Font.GothamMedium)
end

local Theme = {
    Color = {},
    Radius = { Window = 20, Card = 16, Row = 12, Control = 10, Small = 6, Round = 999 },
    Space = { XS = 4, S = 8, M = 12, L = 16, XL = 20, XXL = 24, XXXL = 32 },
    TextSize = { Title = 20, Dialog = 17, Brand = 15, Section = 15, Label = 14, Body = 13, Desc = 12, Caption = 11 },
    Font = {
        Bold = weight(Enum.FontWeight.Bold),
        Semi = weight(Enum.FontWeight.SemiBold),
        Medium = weight(Enum.FontWeight.Medium),
        Regular = weight(Enum.FontWeight.Regular),
    },
    Motion = { Fast = 0.15, Base = 0.2, Slow = 0.3, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
    -- Offset: desplazamiento de la sombra oscura (abajo-derecha). LightOffset: el de la luz (arriba-izquierda).
    -- Blur: difuminado en px. Dark/Light: opacidad maxima (0..1). Tight: segunda sombra corta y definida.
    Shadow = {
        Window      = { Offset = 10, Blur = 26, Dark = 0.42, Light = 0, DarkKey = "Black", Tight = { Offset = 2, Blur = 4, Dark = 0.22 } },
        Float       = { Offset = 6, Blur = 18, Dark = 0.3, Light = 0, DarkKey = "Black", Tight = { Offset = 1, Blur = 3, Dark = 0.16 } },
        Panel       = { Offset = 0, Blur = 0, Dark = 0, Light = 0 },
        Card        = { Offset = 6, LightOffset = 4, Blur = 14, Dark = 0.62, Light = 0.95 },
        Popup       = { Offset = 8, LightOffset = 4, Blur = 18, Dark = 0.62, Light = 0.95 },
        Tile        = { Offset = 5, LightOffset = 4, Blur = 10, Dark = 0.58, Light = 0.95 },
        TileLift    = { Offset = 6, LightOffset = 5, Blur = 12, Dark = 0.68, Light = 1 },
        Control     = { Offset = 3, LightOffset = 3, Blur = 6, Dark = 0.62, Light = 0.95 },
        ControlLift = { Offset = 4, LightOffset = 4, Blur = 8, Dark = 0.72, Light = 1 },
        Knob        = { Offset = 2, LightOffset = 0, Blur = 4, Dark = 0.75, Light = 0, DarkKey = "Edge" },
        KnobLift    = { Offset = 3, LightOffset = 0, Blur = 5, Dark = 0.8, Light = 0, DarkKey = "Edge" },
        Flat        = { Offset = 0, Blur = 0, Dark = 0, Light = 0 },
    },
    -- Inset: opacidad de la sombra interior (arriba) y de la luz interior (abajo)
    Inset = { Dark = 0.85, DarkReach = 0.45, Light = 0.8, LightReach = 0.6 },
    -- borde de 1 px (color Edge, >= 3:1) en controles interactivos: inputs, toggles, botones secundarios
    ControlEdges = true,
    Layout = {
        Width = 820, Height = 540, MinWidth = 460, MinHeight = 340,
        -- header: titulo (24) + 2 + subtitulo (16) empieza en HeaderTop; las paginas empiezan en TopBar
        HeaderTop = 16, FadeTop = 20, FadeBottom = 12,
        Margin = 16, TopBar = 64, Sidebar = 200, SidebarCompact = 68, CompactBelow = 700, SingleBelow = 520,
        PagePad = 20, Gap = 16, Row = 44, RowDesc = 56, Control = 32, TabHeight = 40, Brand = 36, Profile = 56,
        Toggle = Vector2.new(44, 24), Knob = 18, Track = 6, Icon = 18, IconSmall = 14, TopButton = 36,
    },
}
for k, v in pairs(Kato.Themes.Kato) do Theme.Color[k] = v end
local Color = Theme.Color
local R, S, TS, F, M, L = Theme.Radius, Theme.Space, Theme.TextSize, Theme.Font, Theme.Motion, Theme.Layout
Kato.Style = Theme
Kato.Theme = Color
-- nombres de v1/v2 para scripts que usan Kato.Fonts
Kato.Fonts = { Title = F.Bold, Semi = F.Semi, Body = F.Medium, Regular = F.Regular, Mono = F.Medium }

----------------------------------------------------------------------------------------------------
-- UTILIDADES
----------------------------------------------------------------------------------------------------
local function conn(c) table.insert(Kato._conns, c) return c end

local function tween(obj, props, t, style, dir)
    t = t or M.Base
    if not Kato.Config.Animations then t = 0 end
    t = t / math.max(Kato.Config.AnimationSpeed or 1, 0.05)
    if t <= 0 then
        for k, v in pairs(props) do obj[k] = v end
        return nil
    end
    local tw = TweenService:Create(obj, TweenInfo.new(t, style or M.Style, dir or M.Direction), props)
    tw:Play()
    return tw
end

-- Registro de colores: cada instancia recuerda que llave del tema usa cada propiedad
local Bound = setmetatable({}, { __mode = "k" })
local Repaints = {}

local function T(key) return { __tk = key } end

-- Registro de textos traducibles: instancia -> { propiedad = fuente }. Debil: no retiene instancias.
local Texts = setmetatable({}, { __mode = "k" })
-- funciones a re-ejecutar al cambiar de idioma (textos armados a mano: valores de dropdown, etc.)
local LangHooks = {}
local LangListeners = {}

local function setText(inst, prop, v)
    local map = Texts[inst]
    if type(v) == "table" and v.__tk == nil then
        if not map then map = {} Texts[inst] = map end
        map[prop] = v
    elseif map then
        map[prop] = nil
    end
    inst[prop] = tr(v) or ""
end

local function onLanguage(inst, fn)
    -- poda periodica de ganchos de instancias destruidas (evita crecer sin limite)
    if #LangHooks >= 64 and #LangHooks % 64 == 0 then
        local i = 1
        while i <= #LangHooks do
            local h = LangHooks[i]
            if h.inst ~= nil and h.inst.Parent == nil then table.remove(LangHooks, i) else i = i + 1 end
        end
    end
    table.insert(LangHooks, { inst = inst, fn = fn })
end

local function paint(inst, prop, key, t)
    local map = Bound[inst]
    if not map then map = {} Bound[inst] = map end
    map[prop] = key
    local c = Color[key]
    if c == nil then return end
    if t and t > 0 then tween(inst, { [prop] = c }, t) else inst[prop] = c end
end

local function create(class, props, children)
    local inst = Instance.new(class)
    if inst:IsA("GuiObject") then inst.BorderSizePixel = 0 end
    if inst:IsA("GuiButton") then inst.AutoButtonColor = false end
    if class == "TextButton" or class == "TextLabel" or class == "TextBox" then
        inst.Text = ""
        inst.FontFace = F.Medium
    end
    if class == "TextLabel" or class == "ImageLabel" then inst.BackgroundTransparency = 1 end
    local parent
    if props then
        for k, v in pairs(props) do
            if k == "Parent" then
                parent = v
            elseif type(v) == "table" and v.__tk then
                paint(inst, k, v.__tk)
            elseif type(v) == "table" and (k == "Text" or k == "PlaceholderText") then
                setText(inst, k, v)
            else
                inst[k] = v
            end
        end
    end
    if children then for _, c in ipairs(children) do c.Parent = inst end end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(parent, r)
    return create("UICorner", { CornerRadius = UDim.new(0, r or R.Row), Parent = parent })
end

local function pad(parent, l, t, r, b)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or l or 0),
        PaddingRight = UDim.new(0, r or l or 0), PaddingBottom = UDim.new(0, b or t or l or 0), Parent = parent,
    })
end

local function list(parent, padding, horizontal)
    return create("UIListLayout", {
        Padding = UDim.new(0, padding or 0), SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical, Parent = parent,
    })
end

local function label(props)
    local p = {
        BackgroundTransparency = 1, FontFace = F.Medium, TextSize = TS.Body, TextColor3 = T("Text"),
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }
    for k, v in pairs(props) do p[k] = v end
    return create("TextLabel", p)
end

local function nseq(points)
    local kps = {}
    for i, p in ipairs(points) do kps[i] = NumberSequenceKeypoint.new(p[1], p[2]) end
    return NumberSequence.new(kps)
end

local function repaint(animate, only)
    for inst, map in pairs(Bound) do
        for prop, key in pairs(map) do
            if not only or only[key] then
                local c = Color[key]
                if c ~= nil then
                    if animate then
                        pcall(tween, inst, { [prop] = c }, M.Slow)
                    else
                        pcall(function() inst[prop] = c end)
                    end
                end
            end
        end
    end
    for _, fn in ipairs(Repaints) do pcall(fn) end
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local args = { ... }
    local n = select("#", ...)
    task.spawn(function()
        local ok, err = pcall(fn, (table.unpack or unpack)(args, 1, n))
        if not ok then warn("[Kato Lib] callback error: " .. tostring(err)) end
    end)
end

local function isPress(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

-- arrastre generico (mouse y touch). began puede devolver false para cancelar.
local function onDrag(handle, began, moved, ended)
    handle.InputBegan:Connect(function(input)
        if not isPress(input) then return end
        if began and began(input) == false then return end
        local mc, ec
        mc = UserInputService.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                if moved then moved(i) end
            end
        end)
        ec = UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == input.UserInputType then
                mc:Disconnect()
                ec:Disconnect()
                if ended then ended(i) end
            end
        end)
    end)
end

local function toHex(c)
    return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function fromHex(s)
    s = tostring(s or ""):gsub("#", ""):gsub("%s", "")
    if #s == 3 then s = s:sub(1, 1):rep(2) .. s:sub(2, 2):rep(2) .. s:sub(3, 3):rep(2) end
    if #s ~= 6 then return nil end
    local r, g, b = tonumber(s:sub(1, 2), 16), tonumber(s:sub(3, 4), 16), tonumber(s:sub(5, 6), 16)
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r, g, b)
end

local KEY_SHORT = {
    LeftShift = "LShift", RightShift = "RShift", LeftControl = "LCtrl", RightControl = "RCtrl",
    LeftAlt = "LAlt", RightAlt = "RAlt", MouseButton1 = "MB1", MouseButton2 = "MB2", MouseButton3 = "MB3",
    Return = "Enter", Backquote = "`", Space = "Space",
}
local function keyName(k)
    if k == nil then return Kato.Strings.None end
    if typeof(k) == "EnumItem" then return KEY_SHORT[k.Name] or k.Name end
    return tostring(k)
end

local function toKey(v)
    if typeof(v) == "EnumItem" then return v end
    if type(v) == "string" and v ~= "" and v ~= "None" then
        local ok, k = pcall(function() return Enum.KeyCode[v] end)
        if ok and k then return k end
        ok, k = pcall(function() return Enum.UserInputType[v] end)
        if ok and k then return k end
    end
    return nil
end

local function trim(s) return (tostring(s or ""):match("^%s*(.-)%s*$")) end

----------------------------------------------------------------------------------------------------
-- NEU: sombras de Soft UI
--   Neu.raised(parent, props, level, radius, auto, faceKey) -> superficie elevada (contenedor + sombras + cara)
--   Neu.inset(frame, radius, hidden, keepColor, withEdge, colorKey) -> efecto hundido dentro de un frame
-- Las sombras van DETRAS de la cara como hermanas (ZIndex 0) dentro de un contenedor transparente,
-- porque en Roblox un hijo siempre se dibuja encima de su padre.
----------------------------------------------------------------------------------------------------
local Neu = {}
Kato.Neu = Neu

local function spec(level)
    if type(level) == "table" then return level end
    return Theme.Shadow[level or "Tile"] or Theme.Shadow.Tile
end

-- una sombra (luz o sombra). sign: -1 = arriba-izquierda, 1 = abajo-derecha
local function newShadow(box, key, sign, radius, count)
    local sh = { sign = sign, radius = radius, layers = {} }
    if SHADOW_IMAGE ~= "" then
        sh.img = create("ImageLabel", {
            Image = SHADOW_IMAGE, ScaleType = Enum.ScaleType.Slice, SliceCenter = SHADOW_SLICE,
            ImageColor3 = T(key), ImageTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), Parent = box,
        })
    else
        for i = 1, count do
            local f = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = T(key), BackgroundTransparency = 1, Parent = box,
            })
            sh.layers[i] = { f = f, c = corner(f, radius) }
        end
    end
    return sh
end

local function applyShadow(sh, offset, blur, alpha, t)
    local o = offset * sh.sign
    alpha = math.clamp(alpha or 0, 0, 0.99)
    if sh.img then
        sh.img.SliceScale = math.max(blur, 1) / SHADOW_EDGE
        tween(sh.img, {
            Position = UDim2.new(0.5, o, 0.5, o), Size = UDim2.new(1, blur * 2, 1, blur * 2), ImageTransparency = 1 - alpha,
        }, t)
        return
    end
    -- capas concentricas: donde se solapan todas la opacidad total es alpha y hacia afuera se desvanece
    local n = #sh.layers
    local a = 1 - (1 - alpha) ^ (1 / n)
    for i, l in ipairs(sh.layers) do
        local e = blur * i / n
        l.c.CornerRadius = UDim.new(0, sh.radius + e)
        tween(l.f, {
            Position = UDim2.new(0.5, o, 0.5, o), Size = UDim2.new(1, e * 2, 1, e * 2),
            BackgroundTransparency = alpha <= 0 and 1 or 1 - a,
        }, t)
    end
end

local function shadowKey(sh, key)
    if sh.img then paint(sh.img, "ImageColor3", key) return end
    for _, l in ipairs(sh.layers) do paint(l.f, "BackgroundColor3", key) end
end

-- faceKey: color de la cara (por defecto Card, un tono mas claro que el fondo para que "salga")
-- auto: true / "Y" (alto segun el contenido) o "X" (ancho segun el contenido).
-- IMPORTANTE: el contenedor NUNCA usa AutomaticSize. Las sombras se dimensionan con escala respecto al
-- contenedor; si el contenedor se auto-ajustara a sus hijos, las sombras lo agrandarian en cada
-- recalculo (crecimiento sin fin). La cara es la que se auto-ajusta y el contenedor copia su tamano.
function Neu.raised(parent, props, level, radius, auto, faceKey)
    radius = radius or R.Row
    local axis = auto == "X" and "X" or (auto and "Y" or nil)
    local holder = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
    for k, v in pairs(props or {}) do holder[k] = v end
    holder.AutomaticSize = Enum.AutomaticSize.None
    -- caja de sombras: escala pura (1,1) para no alterar el AutomaticSize del contenedor
    local box = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 0, Parent = holder })
    -- tantas capas como pida el mayor difuminado que usara esta superficie (reposo o hover)
    local base = spec(level)
    local lift = Theme.Shadow[tostring(level) .. "Lift"]
    local blur = math.max(base.Blur, lift and lift.Blur or 0)
    local count = math.clamp(math.ceil(blur / SHADOW_STEP), 2, SHADOW_MAX_LAYERS)
    local light = newShadow(box, "Light", -1, radius, count)
    local dark = newShadow(box, base.DarkKey or "Shadow", 1, radius, count)
    -- sombra corta y definida debajo de la difusa (ventana, notificaciones): separa del fondo del juego
    local tight = base.Tight and newShadow(box, base.DarkKey or "Shadow", 1, radius, 2)
    local faceSize = UDim2.fromScale(1, 1)
    if axis == "Y" then faceSize = UDim2.new(1, 0, 0, 0) elseif axis == "X" then faceSize = UDim2.new(0, 0, 1, 0) end
    local face = create("Frame", {
        Size = faceSize, BackgroundColor3 = T(faceKey or "Card"), ZIndex = 1, Parent = holder,
    })
    if axis then face.AutomaticSize = Enum.AutomaticSize[axis] end
    corner(face, radius)
    holder.Parent = parent

    local s = { Holder = holder, Face = face, Radius = radius, Level = level or "Tile" }

    if axis then
        -- sonda de 1000 px: da la escala real (UIScale de la ventana, etc.) para pasar el tamano
        -- absoluto de la cara a pixeles logicos del contenedor
        local probe = create("Frame", { Size = UDim2.fromOffset(1000, 0), BackgroundTransparency = 1, Parent = holder })
        local function sync()
            local k = probe.AbsoluteSize.X / 1000
            if k <= 0 then return end
            local hs = holder.Size
            if axis == "Y" then
                local h = math.ceil(face.AbsoluteSize.Y / k - 0.05)
                if hs.Y.Scale ~= 0 or hs.Y.Offset ~= h then holder.Size = UDim2.new(hs.X.Scale, hs.X.Offset, 0, h) end
            else
                local w = math.ceil(face.AbsoluteSize.X / k - 0.05)
                if hs.X.Scale ~= 0 or hs.X.Offset ~= w then holder.Size = UDim2.new(0, w, hs.Y.Scale, hs.Y.Offset) end
            end
        end
        face:GetPropertyChangedSignal("AbsoluteSize"):Connect(sync)
        probe:GetPropertyChangedSignal("AbsoluteSize"):Connect(sync)
        task.defer(sync)
        s.Sync = sync
    end
    function s:Set(lv, t)
        local d = spec(lv)
        if d.DarkKey then
            shadowKey(dark, d.DarkKey)
            if tight then shadowKey(tight, d.DarkKey) end
        end
        applyShadow(dark, d.Offset, d.Blur, d.Dark, t)
        applyShadow(light, d.LightOffset or d.Offset, d.Blur, d.Light, t)
        if tight then
            local ti = d.Tight or { Offset = 0, Blur = 0, Dark = 0 }
            applyShadow(tight, ti.Offset, ti.Blur, ti.Dark, t)
        end
    end
    -- hover: la sombra sube un nivel (Tile -> TileLift)
    function s:Lift(on, t)
        local up = Theme.Shadow[tostring(self.Level) .. "Lift"] and (tostring(self.Level) .. "Lift") or self.Level
        self:Set(on and up or self.Level, t)
    end
    -- presionado: la superficie se hunde
    function s:Press(on, t)
        if not self.inset then self.inset = Neu.inset(face, radius, true, true) end
        self:Set(on and "Flat" or self.Level, t)
        self.inset:Show(on, t)
    end
    s:Set(s.Level, 0)
    return s
end

-- borde accesible de 1 px (Edge >= 3:1 contra Card y Background) para controles interactivos
local function edge(frame, key)
    if not Theme.ControlEdges then return nil end
    return create("UIStroke", {
        Color = T(key or "Edge"), Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = frame,
    })
end
Neu.edge = edge

-- efecto hundido: relleno Inset + sombra interior arriba (Shadow) + luz interior abajo (Light).
-- La sombra interior usa la sombra oscura del tema y llega hasta ~45% del alto; la luz, el 40% inferior.
-- colorKey: "Inset" (por defecto) o "Track". withEdge: anade el borde accesible.
function Neu.inset(frame, radius, hidden, keepColor, withEdge, colorKey)
    radius = radius or R.Control
    local I = Theme.Inset
    if not keepColor then paint(frame, "BackgroundColor3", colorKey or "Inset") end
    local function layer(key, seq)
        local f = create("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = T(key), BackgroundTransparency = hidden and 1 or 0,
            ZIndex = 0, Parent = frame,
        })
        corner(f, radius)
        create("UIGradient", { Rotation = 90, Transparency = seq, Parent = f })
        return f
    end
    local dark = layer("Shadow", nseq({ { 0, 1 - I.Dark }, { I.DarkReach * 0.4, 1 - I.Dark * 0.55 }, { I.DarkReach, 1 }, { 1, 1 } }))
    local lite = layer("Light", nseq({ { 0, 1 }, { I.LightReach, 1 }, { 1, 1 - I.Light } }))
    local api = { Dark = dark, Light = lite }
    if withEdge then api.Edge = edge(frame) end
    function api:Show(on, t)
        tween(dark, { BackgroundTransparency = on and 0 or 1 }, t)
        tween(lite, { BackgroundTransparency = on and 0 or 1 }, t)
    end
    return api
end

-- superficie pulsable: elevada en reposo, sube con el mouse, se hunde al presionar
local function pressable(s, btn, style, onHover)
    local over, down = false, false
    local function refresh(t)
        if style == "Primary" then
            s:Set(down and "Flat" or (over and (s.Level .. "Lift") or s.Level), t)
            paint(s.Face, "BackgroundColor3", (over or down) and "AccentHover" or "AccentStrong", t)
        elseif down then
            s:Press(true, t)
        else
            if s.inset then s.inset:Show(false, t) end
            s:Lift(over, t)
        end
        if onHover then onHover(over, down, t) end
    end
    btn.MouseEnter:Connect(function() over = true refresh(M.Fast) end)
    btn.MouseLeave:Connect(function() over = false down = false refresh(M.Base) end)
    btn.InputBegan:Connect(function(i) if isPress(i) then down = true refresh(M.Fast) end end)
    btn.InputEnded:Connect(function(i) if isPress(i) and down then down = false refresh(M.Base) end end)
    return refresh
end

-- linea grabada (sombra + luz de 1 px): separador sin bordes
local function groove(parent, props)
    local f = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 2), Parent = parent })
    for k, v in pairs(props or {}) do f[k] = v end
    create("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T("Shadow"), BackgroundTransparency = 0.15, Parent = f })
    create("Frame", { Position = UDim2.fromOffset(0, 1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T("Light"), BackgroundTransparency = 0.1, Parent = f })
    return f
end

----------------------------------------------------------------------------------------------------
-- ICONOS VECTORIALES (dibujados con frames: nitidos a cualquier escala, sin assets externos)
-- coordenadas en escala 0..1 del cuadro del icono
----------------------------------------------------------------------------------------------------
local Icons = {}
local SQ = 0.22 -- radio de esquina para formas "cuadradas"

Icons.home = function(b, r)
    b(0.31, 0.37, 0.52, 0.13, -42) b(0.69, 0.37, 0.52, 0.13, 42)
    r(0.5, 0.68, 0.54, 0.4, 0.11, 0.16) b(0.5, 0.78, 0.16, 0.22, 0)
end
Icons.user = function(b, r, d) d(0.5, 0.3, 0.38) b(0.5, 0.82, 0.78, 0.36, 0) end
Icons.users = function(b, r, d)
    d(0.38, 0.32, 0.32) b(0.38, 0.8, 0.62, 0.32, 0) d(0.74, 0.36, 0.24) b(0.8, 0.78, 0.4, 0.26, 0)
end
Icons.eye = function(b, r, d) r(0.5, 0.5, 0.94, 0.58, 0.1, 0.5) d(0.5, 0.5, 0.3) end
Icons.box = function(b, r)
    r(0.5, 0.54, 0.76, 0.7, 0.1, SQ) b(0.5, 0.4, 0.76, 0.1, 0, SQ) b(0.5, 0.29, 0.1, 0.22, 0, SQ)
end
Icons.settings = function(b, r)
    for k = 0, 7 do
        local a = math.rad(k * 45)
        b(0.5 + 0.37 * math.cos(a), 0.5 + 0.37 * math.sin(a), 0.2, 0.2, k * 45, SQ)
    end
    r(0.5, 0.5, 0.44, 0.44, 0.15, 0.5)
end
Icons.bolt = function(b) b(0.6, 0.27, 0.15, 0.48, 24) b(0.5, 0.5, 0.48, 0.14, -14) b(0.4, 0.73, 0.15, 0.48, 24) end
Icons.star = function(b) b(0.5, 0.5, 0.6, 0.6, 0, 0.18) b(0.5, 0.5, 0.6, 0.6, 45, 0.18) end
Icons.heart = function(b, r, d) d(0.34, 0.4, 0.38) d(0.66, 0.4, 0.38) b(0.5, 0.56, 0.5, 0.5, 45, 0.12) end
Icons.sword = function(b)
    b(0.58, 0.42, 0.13, 0.76, 45) b(0.31, 0.69, 0.44, 0.12, 45) b(0.2, 0.8, 0.12, 0.24, 45)
end
Icons.target = function(b, r, d)
    r(0.5, 0.5, 0.62, 0.62, 0.1, 0.5) d(0.5, 0.5, 0.18)
    b(0.5, 0.07, 0.1, 0.22) b(0.5, 0.93, 0.1, 0.22) b(0.07, 0.5, 0.22, 0.1) b(0.93, 0.5, 0.22, 0.1)
end
Icons.clock = function(b, r) r(0.5, 0.5, 0.82, 0.82, 0.1, 0.5) b(0.5, 0.38, 0.1, 0.3) b(0.59, 0.55, 0.24, 0.1, 30) end
Icons.palette = function(b, r, d)
    r(0.5, 0.5, 0.84, 0.84, 0.1, 0.5) d(0.35, 0.38, 0.15) d(0.6, 0.3, 0.15) d(0.7, 0.55, 0.15) d(0.42, 0.66, 0.15)
end
Icons.key = function(b, r) r(0.3, 0.5, 0.38, 0.38, 0.12, 0.5) b(0.66, 0.5, 0.48, 0.11) b(0.8, 0.62, 0.1, 0.22) b(0.66, 0.6, 0.1, 0.16) end
Icons.list = function(b, r, d)
    for _, y in ipairs({ 0.24, 0.5, 0.76 }) do d(0.14, y, 0.14) b(0.6, y, 0.62, 0.11) end
end
Icons.grid = function(b)
    b(0.28, 0.28, 0.38, 0.38, 0, SQ) b(0.72, 0.28, 0.38, 0.38, 0, SQ)
    b(0.28, 0.72, 0.38, 0.38, 0, SQ) b(0.72, 0.72, 0.38, 0.38, 0, SQ)
end
Icons.search = function(b, r) r(0.43, 0.43, 0.56, 0.56, 0.11, 0.5) b(0.77, 0.77, 0.11, 0.3, -45) end
Icons.info = function(b, r, d) r(0.5, 0.5, 0.84, 0.84, 0.1, 0.5) b(0.5, 0.6, 0.11, 0.3) d(0.5, 0.33, 0.13) end
Icons.i = function(b, r, d) b(0.5, 0.62, 0.13, 0.42) d(0.5, 0.24, 0.16) end
Icons.check = function(b) b(0.33, 0.6, 0.13, 0.36, -45) b(0.6, 0.5, 0.13, 0.66, 40) end
Icons.x = function(b) b(0.5, 0.5, 0.12, 0.84, 45) b(0.5, 0.5, 0.12, 0.84, -45) end
Icons.warning = function(b, r, d) b(0.5, 0.4, 0.14, 0.5) d(0.5, 0.82, 0.16) end
Icons.chart = function(b)
    b(0.2, 0.75, 0.17, 0.3, 0, 0.3) b(0.5, 0.6, 0.17, 0.6, 0, 0.3) b(0.8, 0.47, 0.17, 0.86, 0, 0.3)
end
Icons.folder = function(b, r) r(0.5, 0.57, 0.84, 0.62, 0.1, 0.16) b(0.3, 0.22, 0.38, 0.14, 0, 0.3) end
Icons.trash = function(b, r) r(0.5, 0.6, 0.58, 0.64, 0.1, 0.16) b(0.5, 0.21, 0.84, 0.1) b(0.5, 0.1, 0.3, 0.1) end
Icons.globe = function(b, r) r(0.5, 0.5, 0.84, 0.84, 0.1, 0.5) r(0.5, 0.5, 0.36, 0.84, 0.1, 0.5) b(0.5, 0.5, 0.84, 0.09) end
Icons.bell = function(b, r, d) b(0.5, 0.48, 0.6, 0.6, 0, 0.45) b(0.5, 0.72, 0.84, 0.12) d(0.5, 0.88, 0.18) end
Icons.lock = function(b, r) r(0.5, 0.33, 0.44, 0.5, 0.11, 0.5) b(0.5, 0.68, 0.72, 0.5, 0, SQ) end
Icons.shield = function(b) b(0.5, 0.38, 0.7, 0.46, 0, 0.18) b(0.5, 0.6, 0.5, 0.5, 45, 0.15) end
Icons.chat = function(b, r) r(0.5, 0.44, 0.84, 0.62, 0.1, 0.25) b(0.3, 0.8, 0.1, 0.24, 35) end
Icons.code = function(b)
    b(0.22, 0.38, 0.11, 0.32, 45) b(0.22, 0.62, 0.11, 0.32, -45)
    b(0.78, 0.38, 0.11, 0.32, -45) b(0.78, 0.62, 0.11, 0.32, 45) b(0.5, 0.5, 0.1, 0.7, 20)
end
Icons.play = function(b) b(0.45, 0.33, 0.13, 0.46, -50) b(0.45, 0.67, 0.13, 0.46, 50) b(0.3, 0.5, 0.13, 0.62, 0) end
Icons.plus = function(b) b(0.5, 0.5, 0.12, 0.8) b(0.5, 0.5, 0.8, 0.12) end
Icons.minus = function(b) b(0.5, 0.5, 0.8, 0.12) end
Icons.crown = function(b, r, d)
    b(0.5, 0.78, 0.8, 0.14, 0, 0.3) b(0.2, 0.5, 0.12, 0.5, -12) b(0.8, 0.5, 0.12, 0.5, 12) b(0.5, 0.5, 0.12, 0.5)
    b(0.35, 0.62, 0.36, 0.12, 30) b(0.65, 0.62, 0.36, 0.12, -30) d(0.2, 0.22, 0.16) d(0.5, 0.2, 0.16) d(0.8, 0.22, 0.16)
end
Icons.layers = function(b, r) r(0.38, 0.38, 0.52, 0.52, 0.1, 0.18) r(0.62, 0.62, 0.52, 0.52, 0.1, 0.18) end
Icons.run = function(b, r, d)
    d(0.62, 0.15, 0.22) b(0.5, 0.42, 0.14, 0.4, 20) b(0.38, 0.75, 0.13, 0.36, 30) b(0.62, 0.75, 0.13, 0.36, -25)
    b(0.66, 0.4, 0.3, 0.11, 25) b(0.32, 0.38, 0.3, 0.11, -25)
end
Icons.dollar = function(b, r) r(0.5, 0.5, 0.84, 0.84, 0.1, 0.5) b(0.5, 0.5, 0.1, 0.56) b(0.5, 0.42, 0.34, 0.1, 30) b(0.5, 0.58, 0.34, 0.1, 30) end
Icons.link = function(b, r) r(0.36, 0.64, 0.5, 0.3, 0.1, 0.5, -45) r(0.64, 0.36, 0.5, 0.3, 0.1, 0.5, -45) end
Icons.refresh = function(b, r) r(0.5, 0.5, 0.72, 0.72, 0.1, 0.5) b(0.8, 0.22, 0.26, 0.12, 0) b(0.88, 0.32, 0.12, 0.26, 0) end
Icons.dot = function(b, r, d) d(0.5, 0.5, 0.42) end
Icons.chevron = function(b) b(0.42, 0.34, 0.12, 0.42, -45) b(0.42, 0.66, 0.12, 0.42, 45) end

local ICON_ALIAS = {
    house = "home", main = "home", player = "user", person = "user", profile = "user", visuals = "eye", view = "eye",
    misc = "box", package = "box", cube = "box", items = "box", cog = "settings", gear = "settings", config = "settings",
    flash = "bolt", lightning = "bolt", zap = "bolt", combat = "sword", pvp = "sword", keyboard = "key", keybind = "key",
    color = "palette", theme = "palette", time = "clock", timer = "clock", stats = "chart", save = "folder", files = "folder",
    alert = "warning", error = "x", close = "x", success = "check", world = "globe", teleport = "globe", aim = "target",
    crosshair = "target", sparkles = "star", favorite = "heart", message = "chat", discord = "chat", dev = "code",
    premium = "crown", farm = "bolt", money = "dollar", speed = "run", movement = "run", reload = "refresh",
    arrow = "chevron", next = "chevron",
}

local function iconName(name)
    if type(name) ~= "string" then return nil end
    local n = string.lower(name)
    n = ICON_ALIAS[n] or n
    return Icons[n] and n or nil
end

-- dibuja un icono; devuelve un objeto con :Paint(llave, t) o nil si el nombre no existe
local function drawIcon(name, parent, size, key, props)
    local n = iconName(name)
    if not n then return nil end
    local holder = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Parent = parent })
    for k, v in pairs(props or {}) do holder[k] = v end
    local parts = {}
    local function bar(x, y, w, h, rot, rad)
        local f = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h),
            Rotation = rot or 0, BackgroundColor3 = T(key), Parent = holder,
        })
        create("UICorner", { CornerRadius = rad and UDim.new(rad, 0) or UDim.new(1, 0), Parent = f })
        table.insert(parts, { f, "BackgroundColor3" })
        return f
    end
    local function ring(x, y, w, h, th, rad, rot)
        local f = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h),
            Rotation = rot or 0, BackgroundTransparency = 1, Parent = holder,
        })
        create("UICorner", { CornerRadius = UDim.new(rad or 0.5, 0), Parent = f })
        local s = create("UIStroke", { Thickness = math.max(1, size * (th or 0.1)), Color = T(key), Parent = f })
        table.insert(parts, { s, "Color" })
        return f
    end
    local function dot(x, y, d) return bar(x, y, d, d, 0) end
    Icons[n](bar, ring, dot)
    local api = { Holder = holder }
    function api:Paint(k, t) for _, p in ipairs(parts) do paint(p[1], p[2], k, t) end end
    return api
end

-- icono flexible: nombre del set, asset (imagen) o letra. Devuelve objeto con :Paint
local function makeIcon(spec0, parent, size, key, props, fallbackText)
    if spec0 == nil or spec0 == "" then
        if not fallbackText then return nil end
        spec0 = fallbackText
    end
    local api = drawIcon(spec0, parent, size, key, props)
    if api then return api end
    local s = tostring(spec0)
    local isImage = type(spec0) == "number" or s:match("^rbxasset") or s:match("^https?://") or s:match("^%d+$")
    if isImage then
        if not s:match("^rbx") and not s:match("^http") then s = "rbxassetid://" .. s end
        local img = create("ImageLabel", { Image = s, Size = UDim2.fromOffset(size, size), ImageColor3 = T(key), Parent = parent })
        for k, v in pairs(props or {}) do img[k] = v end
        return { Holder = img, Paint = function(_, k, t) paint(img, "ImageColor3", k, t) end }
    end
    local n = utf8.len(s)
    local text = (n and n <= 2) and s or s:sub(1, 1):upper()
    local l = label({
        Text = text, FontFace = F.Bold, TextSize = math.floor(size * 0.85), TextColor3 = T(key),
        TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.None,
        Size = UDim2.fromOffset(size, size), Parent = parent,
    })
    for k, v in pairs(props or {}) do l[k] = v end
    return { Holder = l, Paint = function(_, k, t) paint(l, "TextColor3", k, t) end }
end

function Kato:GetIcons()
    local out = {}
    for k in pairs(Icons) do table.insert(out, k) end
    table.sort(out)
    return out
end

local function centered(props)
    local p = { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }
    for k, v in pairs(props or {}) do p[k] = v end
    return p
end

----------------------------------------------------------------------------------------------------
-- ARCHIVOS (configs y ajustes)
----------------------------------------------------------------------------------------------------
local function hasFS()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
        and type(makefolder) == "function" and type(isfolder) == "function"
end

local function ensureFolder(path)
    if not hasFS() then return end
    local acc = ""
    for part in tostring(path):gmatch("[^/]+") do
        acc = acc == "" and part or (acc .. "/" .. part)
        pcall(function() if not isfolder(acc) then makefolder(acc) end end)
    end
end

local function readJSON(path)
    if not hasFS() then return nil end
    local ok, data = pcall(function()
        if not isfile(path) then return nil end
        return HttpService:JSONDecode(readfile(path))
    end)
    return ok and data or nil
end

local function writeJSON(path, data)
    if not hasFS() then return false end
    ensureFolder(path:match("^(.*)/[^/]+$") or "")
    return pcall(function() writefile(path, HttpService:JSONEncode(data)) end)
end

Kato._state = {}
local saveToken = 0
local function saveState()
    if not Kato._stateOn then return end
    saveToken = saveToken + 1
    local my = saveToken
    task.delay(0.6, function()
        if my == saveToken and not Kato.Unloaded then writeJSON(Kato.Config.Folder .. "/settings.json", Kato._state) end
    end)
end

----------------------------------------------------------------------------------------------------
-- SCREENGUI GLOBAL
----------------------------------------------------------------------------------------------------
local gui = create("ScreenGui", {
    Name = "KatoLib", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 60, IgnoreGuiInset = false,
})
do
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    local placed = pcall(function()
        local h = gethui and gethui()
        if typeof(h) ~= "Instance" then error("no gethui") end
        local old = h:FindFirstChild("KatoLib")
        if old then old:Destroy() end
        gui.Parent = h
    end)
    if not placed then
        placed = pcall(function()
            local cg = game:GetService("CoreGui")
            local old = cg:FindFirstChild("KatoLib")
            if old then old:Destroy() end
            gui.Parent = cg
        end)
    end
    if not placed then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end
Kato.Gui = gui

----------------------------------------------------------------------------------------------------
-- TOOLTIP (uno solo, compartido): pastilla oscura con texto del color del fondo
----------------------------------------------------------------------------------------------------
local tip = create("Frame", {
    Visible = false, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
    BackgroundColor3 = T("Text"), ZIndex = 300, Parent = gui,
})
corner(tip, R.Small)
pad(tip, S.S, S.XS + 1, S.S, S.XS + 2)
local tipText = label({
    Parent = tip, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), TextSize = TS.Desc,
    TextColor3 = T("Background"), TextWrapped = true, TextTruncate = Enum.TextTruncate.None, ZIndex = 301,
})
create("UISizeConstraint", { MaxSize = Vector2.new(240, 300), Parent = tipText })
local tipToken, tipConn = 0, nil

local function tipMove()
    local m = UserInputService:GetMouseLocation()
    local inset = GuiService:GetGuiInset()
    local vp = gui.AbsoluteSize
    local x, y = m.X - inset.X + 14, m.Y - inset.Y + 18
    local sz = tip.AbsoluteSize
    if x + sz.X > vp.X - 8 then x = m.X - inset.X - sz.X - 10 end
    if y + sz.Y > vp.Y - 8 then y = m.Y - inset.Y - sz.Y - 10 end
    tip.Position = UDim2.fromOffset(x, y)
end

local function hideTip()
    tipToken = tipToken + 1
    tip.Visible = false
    if tipConn then tipConn:Disconnect() tipConn = nil end
end

local function bindTooltip(inst, text)
    if not text or text == "" then return end
    inst.MouseEnter:Connect(function()
        if not Kato.Config.Tooltip.Enabled then return end
        tipToken = tipToken + 1
        local my = tipToken
        task.delay(Kato.Config.Tooltip.Delay, function()
            if my ~= tipToken or Kato.Unloaded then return end
            local value = text
            if type(text) == "function" then value = text() end
            if value == nil or value == "" then return end
            tipText.Text = tr(value) or ""
            tip.BackgroundTransparency = 1
            tipText.TextTransparency = 1
            tip.Visible = true
            tipMove()
            tween(tip, { BackgroundTransparency = 0 }, M.Fast)
            tween(tipText, { TextTransparency = 0 }, M.Fast)
            if tipConn then tipConn:Disconnect() end
            tipConn = RunService.RenderStepped:Connect(tipMove)
        end)
    end)
    inst.MouseLeave:Connect(hideTip)
end

----------------------------------------------------------------------------------------------------
-- NOTIFICACIONES: tarjeta clara elevada, el tipo se indica con un punto de color
----------------------------------------------------------------------------------------------------
local notifyHolder = create("Frame", {
    AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -S.XL, 1, -S.XL),
    Size = UDim2.new(0, Kato.Config.Notify.Width, 1, -S.XXXL), BackgroundTransparency = 1, ZIndex = 150, Parent = gui,
})
do
    local l = list(notifyHolder, S.M)
    l.VerticalAlignment = Enum.VerticalAlignment.Bottom
    l.HorizontalAlignment = Enum.HorizontalAlignment.Right
end
local function fitNotifyWidth()
    local w = math.min(Kato.Config.Notify.Width, math.max(gui.AbsoluteSize.X - S.XXXL - S.S, 200))
    notifyHolder.Size = UDim2.new(0, w, 1, -S.XXXL)
end
conn(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitNotifyWidth))
fitNotifyWidth()

local notifyCount, activeNotifs = 0, {}
local TYPE_KEY = { Info = "Accent2", Success = "Success", Warning = "Warning", Error = "Error" }

function Kato:Notify(o)
    -- Notify("texto") o Notify({ es = "...", en = "..." }) = solo titulo
    if type(o) == "string" or (type(o) == "table" and o.Title == nil and o.Content == nil and (o.es or o.en or o.__s or o.__f)) then
        o = { Title = o }
    end
    o = o or {}
    local kind = TYPE_KEY[o.Type or "Info"] and (o.Type or "Info") or "Info"
    local key = TYPE_KEY[kind]
    local duration = tonumber(o.Duration) or Kato.Config.Notify.Duration
    notifyCount = notifyCount + 1

    local wrap = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = notifyCount, Parent = notifyHolder,
    })
    local surf = Neu.raised(wrap, { Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(1, 40, 0, 0) }, "Float", R.Card, true)
    local card = surf.Face
    local hit = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = card })

    -- punto de color + icono opcional
    local dot = create("Frame", {
        Position = UDim2.fromOffset(S.L, S.L + 5), Size = UDim2.fromOffset(S.S, S.S), BackgroundColor3 = T(key), Parent = card,
    })
    corner(dot, R.Round)
    local textX = S.L + S.S + S.M
    if o.Icon then
        makeIcon(o.Icon, card, L.IconSmall, key, { Position = UDim2.fromOffset(textX, S.L + 1) })
        textX = textX + L.IconSmall + S.S
    end

    local inner = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card,
    })
    pad(inner, textX, S.M + 2, S.XXXL + S.S, S.L + S.XS)
    list(inner, S.XS)
    local titleLbl = label({
        Parent = inner, LayoutOrder = 1, Text = txt(o.Title, "Kato Hub"), FontFace = F.Semi, TextSize = TS.Label,
        Size = UDim2.new(1, 0, 0, 18),
    })
    local bodyLbl = label({
        Parent = inner, LayoutOrder = 2, Text = txt(o.Content, ""), TextColor3 = T("Muted"), TextSize = TS.Desc,
        FontFace = F.Regular, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0), RichText = true, Visible = o.Content ~= nil and tr(o.Content) ~= "",
    })
    local closeX = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -S.S, 0, S.S), Size = UDim2.fromOffset(28, 28),
        BackgroundTransparency = 1, ZIndex = 3, Parent = card,
    })
    local xi = makeIcon("x", closeX, 10, "Muted", centered())
    closeX.MouseEnter:Connect(function() xi:Paint("Text", M.Fast) end)
    closeX.MouseLeave:Connect(function() xi:Paint("Muted", M.Base) end)

    -- tiempo restante: linea fina hundida
    local track = create("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, S.L, 1, -S.S), Size = UDim2.new(1, -S.L * 2, 0, 3),
        BackgroundColor3 = T("Inset"), Parent = card,
    })
    corner(track, R.Round)
    local bar = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T(key), BackgroundTransparency = 0.35, Parent = track })
    corner(bar, R.Round)

    local handle, closed, hovered = {}, false, false
    local sizeConn
    local function fitWrap(t)
        if closed then return end
        tween(wrap, { Size = UDim2.new(1, 0, 0, surf.Holder.AbsoluteSize.Y) }, t or M.Slow)
    end
    function handle:Close()
        if closed then return end
        closed = true
        if sizeConn then sizeConn:Disconnect() end
        local idx = table.find(activeNotifs, handle)
        if idx then table.remove(activeNotifs, idx) end
        tween(surf.Holder, { Position = UDim2.new(1, 40, 0, 0) }, M.Base, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        surf:Set("Flat", M.Base)
        task.delay(M.Base, function()
            tween(wrap, { Size = UDim2.new(1, 0, 0, 0) }, M.Base)
            task.delay(M.Base + 0.02, function() wrap:Destroy() end)
        end)
    end
    function handle:SetTitle(t) setText(titleLbl, "Text", txt(t, "")) end
    function handle:SetContent(t)
        setText(bodyLbl, "Text", txt(t, ""))
        bodyLbl.Visible = t ~= nil and tr(t) ~= ""
    end

    hit.MouseEnter:Connect(function() hovered = true end)
    hit.MouseLeave:Connect(function() hovered = false end)
    closeX.MouseButton1Click:Connect(function() handle:Close() end)
    hit.MouseButton1Click:Connect(function()
        if type(o.Callback) == "function" then safeCall(o.Callback) end
        handle:Close()
    end)
    table.insert(activeNotifs, handle)
    while #activeNotifs > Kato.Config.Notify.Max do activeNotifs[1]:Close() end

    task.spawn(function()
        RunService.Heartbeat:Wait()
        RunService.Heartbeat:Wait()
        if closed then return end
        fitWrap(M.Base)
        sizeConn = surf.Holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() fitWrap(M.Fast) end)
        tween(surf.Holder, { Position = UDim2.new(0, 0, 0, 0) }, M.Slow)
        -- el tiempo se pausa mientras el mouse esta encima
        local elapsed = 0
        while elapsed < duration and not closed and not Kato.Unloaded do
            local dt = task.wait()
            if not hovered then
                elapsed = elapsed + dt
                bar.Size = UDim2.fromScale(math.max(0, 1 - elapsed / duration), 1)
            end
        end
        handle:Close()
    end)
    return handle
end

----------------------------------------------------------------------------------------------------
-- API DE TEMAS
----------------------------------------------------------------------------------------------------
function Kato:GetThemes() return table.clone(Kato.ThemeOrder) end

-- t: { Background, Accent, Text, Dark = bool } + cualquier llave de color para sobrescribir
function Kato:AddTheme(name, t)
    if type(t) ~= "table" then return end
    local base = makeTheme(
        t.Background or rgb(220, 224, 236), t.Accent or rgb(123, 97, 255), t.Text or rgb(35, 39, 61), t.Dark == true
    )
    for k, v in pairs(t) do if typeof(v) == "Color3" then base[k] = v end end
    if not (t.Accent2Soft or t.Accent2Text) then accent2Keys(base, t.Dark == true) end
    Kato.Themes[name] = base
    if not table.find(Kato.ThemeOrder, name) then table.insert(Kato.ThemeOrder, name) end
end

function Kato:SetTheme(t, silent)
    local src = type(t) == "string" and Kato.Themes[t] or t
    if type(src) ~= "table" then return false end
    for k, v in pairs(src) do Color[k] = v end
    if type(t) == "string" then
        Kato.CurrentTheme = t
        Kato._state.Theme = t
        Kato._state.Accent, Kato._state.Accent2 = nil, nil
        if not silent then saveState() end
    end
    repaint(not silent)
    return true
end

-- un solo color de acento; el segundo se guarda por compatibilidad
function Kato:SetAccent(a, b)
    local light = (Color.Background.R + Color.Background.G + Color.Background.B) / 3 > 0.5
    if typeof(a) == "Color3" then
        -- si el tema usa un solo acento (Accent2 == Accent), el segundo sigue al primero
        local old1, old2 = Color.Accent, Color.Accent2
        local linked = old2 == nil or (old1 and old2.R == old1.R and old2.G == old1.G and old2.B == old1.B)
        accentKeys(Color, a, not light)
        if linked and typeof(b) ~= "Color3" then Color.Accent2 = a end
    end
    if typeof(b) == "Color3" then Color.Accent2 = b end
    accent2Keys(Color, not light)
    repaint(false, {
        Accent = true, AccentStrong = true, AccentHover = true, AccentText = true, AccentSoft = true,
        Accent2 = true, Accent2Soft = true, Accent2Text = true,
    })
    Kato._state.Accent, Kato._state.Accent2 = toHex(Color.Accent), toHex(Color.Accent2)
    saveState()
end

----------------------------------------------------------------------------------------------------
-- API DE IDIOMAS
----------------------------------------------------------------------------------------------------
function Kato:GetLanguage() return Kato.Language end
function Kato:GetLanguages() return table.clone(Kato.LanguageOrder) end
function Kato:GetLanguageName(code) return Kato.LanguageNames[code or Kato.Language] or tostring(code) end

-- agrega o amplia un idioma; lo que falte se toma del ingles
function Kato:AddLanguage(code, name, strings)
    if type(code) ~= "string" then return end
    local pack = Kato.Languages[code] or {}
    for k, v in pairs(Kato.Languages.en) do if pack[k] == nil then pack[k] = v end end
    for k, v in pairs(strings or {}) do pack[k] = v end
    Kato.Languages[code] = pack
    Kato.LanguageNames[code] = name or Kato.LanguageNames[code] or code
    if not table.find(Kato.LanguageOrder, code) then table.insert(Kato.LanguageOrder, code) end
end

function Kato:OnLanguageChanged(fn) table.insert(LangListeners, fn) end

function Kato:SetLanguage(code, silent)
    local pack = Kato.Languages[code]
    if not pack then return false end
    Kato.Language = code
    for k, v in pairs(pack) do Kato.Strings[k] = v end
    for inst, map in pairs(Texts) do
        for prop, src in pairs(map) do pcall(function() inst[prop] = tr(src) end) end
    end
    -- ganchos: se descartan los de instancias ya destruidas
    local alive = {}
    for _, h in ipairs(LangHooks) do
        if h.inst == nil or h.inst.Parent ~= nil then
            pcall(h.fn)
            table.insert(alive, h)
        end
    end
    table.clear(LangHooks)
    for _, h in ipairs(alive) do table.insert(LangHooks, h) end
    Kato._state.Language = code
    if not silent then saveState() end
    for _, fn in ipairs(LangListeners) do safeCall(fn, code) end
    return true
end

----------------------------------------------------------------------------------------------------
-- BLUR opcional: desenfoca el mundo 3D detras del menu
----------------------------------------------------------------------------------------------------
local blurFx
local function setBlur(on)
    if on and not blurFx then
        blurFx = Instance.new("BlurEffect")
        blurFx.Name = "KatoBlur"
        blurFx.Size = 0
        blurFx.Parent = Lighting
    end
    if blurFx then tween(blurFx, { Size = on and 14 or 0 }, M.Slow) end
end

----------------------------------------------------------------------------------------------------
-- CLASES
----------------------------------------------------------------------------------------------------
local Window = {} Window.__index = Window
local Tab = {} Tab.__index = Tab
local Section = {} Section.__index = Section

local function opts(o)
    if type(o) == "string" or isTrText(o) then return { Name = o } end
    return o or {}
end

-- boton invisible que cubre una superficie
local function hitbox(parent, z)
    return create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z or 4, Parent = parent })
end

----------------------------------------------------------------------------------------------------
-- VENTANA
----------------------------------------------------------------------------------------------------
function Kato:CreateWindow(o)
    o = o or {}
    local self = setmetatable({}, Window)
    -- Title/Subtitle guardan el texto ya traducido; la fuente traducible va en _titleSrc/_subtitleSrc
    self._titleSrc = txt(o.Title, "Kato Hub")
    self._subtitleSrc = txt(o.Subtitle, "v" .. Kato.Version)
    self.Title, self.Subtitle = tr(self._titleSrc), tr(self._subtitleSrc)
    self.Icon = o.Icon or DEFAULT_ICON
    self.BaseW, self.BaseH = o.Width or L.Width, o.Height or L.Height
    self.W, self.H = self.BaseW, self.BaseH
    self.MinW, self.MinH = o.MinWidth or L.MinWidth, o.MinHeight or L.MinHeight
    self.SW = o.SidebarWidth or L.Sidebar
    self.ToggleKey = toKey(o.ToggleKey) or Enum.KeyCode.RightShift
    self.Glass = o.Glass == true
    self.GlassStrength = o.Transparency or 0.5
    self.Blur = o.Blur == true
    self.UserScale = 1
    self.Visible = false
    self._tabs, self._glassParts = {}, {}
    self._listY = 0
    Kato.Config.Folder = o.Folder or Kato.Config.Folder
    table.insert(Kato.Windows, self)

    -- ajustes guardados (tema, acento, transparencia, escala, tecla)
    Kato._stateOn = o.SaveSettings ~= false and hasFS()
    if Kato._stateOn then
        local st = readJSON(Kato.Config.Folder .. "/settings.json")
        if type(st) == "table" then
            Kato._state = st
            if st.Theme and Kato.Themes[st.Theme] then Kato:SetTheme(st.Theme, true) end
            if st.Accent or st.Accent2 then Kato:SetAccent(fromHex(st.Accent), fromHex(st.Accent2)) end
            if type(st.Glass) == "boolean" then self.Glass = st.Glass end
            if type(st.GlassStrength) == "number" then self.GlassStrength = math.clamp(st.GlassStrength, 0, 1) end
            if type(st.Scale) == "number" then self.UserScale = math.clamp(st.Scale, 0.6, 1.4) end
            if type(st.Blur) == "boolean" then self.Blur = st.Blur end
            self.ToggleKey = toKey(st.ToggleKey) or self.ToggleKey
        end
    end
    -- idioma: el elegido por el jugador (settings.json) manda; si no hay, o.Language (por defecto "es")
    local lang = o.Language
    if Kato._stateOn and type(Kato._state.Language) == "string" and Kato.Languages[Kato._state.Language] then
        lang = Kato._state.Language
    end
    if lang and Kato.Languages[lang] and lang ~= Kato.Language then Kato:SetLanguage(lang, true) end
    self.Title, self.Subtitle = tr(self._titleSrc), tr(self._subtitleSrc)

    -- la ventana es una superficie elevada con sombra difusa que sigue su radio
    local surf = Neu.raised(gui, {
        Name = "KatoWindow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(self.W, self.H), Visible = false,
    }, "Window", R.Window, false, "Background")
    surf:Set("Flat", 0)
    local holder, root = surf.Holder, surf.Face
    self._holder, self._surface, self._root = holder, surf, root
    self._uiScale = create("UIScale", { Parent = holder })
    self:_glass(root, 0, 0.12)
    -- unico borde decorativo: el contorno exterior de la ventana (separa del fondo del juego)
    self._outline = create("UIStroke", {
        Color = T("WindowStroke"), Thickness = 1, Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = root,
    })

    ------------------------------------------------------------------------------------------------
    -- SIDEBAR (zona un tono mas oscura que la ventana: se separa sin lineas)
    ------------------------------------------------------------------------------------------------
    local side = Neu.raised(root, {
        Position = UDim2.fromOffset(L.Margin, L.Margin), Size = UDim2.new(0, self.SW, 1, -L.Margin * 2),
    }, "Panel", R.Card, false, "Sidebar")
    local sidebar = side.Face
    self._side = side.Holder

    local brand = create("Frame", {
        Position = UDim2.fromOffset(S.L, S.L), Size = UDim2.new(1, -S.L * 2, 0, L.Brand), BackgroundTransparency = 1, Parent = sidebar,
    })
    local brandIcon = create("ImageLabel", { Image = self.Icon, Size = UDim2.fromOffset(L.Brand, L.Brand), Parent = brand })
    corner(brandIcon, R.Control)
    local brandText = create("Frame", {
        Position = UDim2.fromOffset(L.Brand + S.M, 0), Size = UDim2.new(1, -(L.Brand + S.M), 1, 0), BackgroundTransparency = 1, Parent = brand,
    })
    self._title = label({
        Parent = brandText, Text = self._titleSrc, FontFace = F.Bold, TextSize = TS.Brand, Position = UDim2.fromOffset(0, 1), Size = UDim2.new(1, 0, 0, 19),
    })
    self._subtitle = label({
        Parent = brandText, Text = self._subtitleSrc, FontFace = F.Regular, TextSize = TS.Desc, TextColor3 = T("Muted"),
        Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 16),
    })
    self._brandText = brandText
    -- Title/Subtitle (strings) siguen al idioma activo
    local winRef = self
    onLanguage(self._title, function()
        winRef.Title, winRef.Subtitle = tr(winRef._titleSrc), tr(winRef._subtitleSrc)
    end)
    -- 5 clicks rapidos en el logo = giro
    do
        local clicks, last = 0, 0
        brandIcon.InputBegan:Connect(function(i)
            if not isPress(i) then return end
            local now = os.clock()
            clicks = (now - last < 0.45) and clicks + 1 or 1
            last = now
            if clicks >= 5 then
                clicks = 0
                brandIcon.Rotation = 0
                tween(brandIcon, { Rotation = 360 }, 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
                task.delay(0.62, function() brandIcon.Rotation = 0 end)
            end
        end)
    end

    -- lista de tabs (posicion manual: permite un indicador que se desliza)
    local listY = S.L + L.Brand + S.XL
    self._tabListY = listY
    self._tabList = create("ScrollingFrame", {
        Position = UDim2.fromOffset(S.M, listY), Size = UDim2.new(1, -S.M * 2, 1, -(listY + L.Profile + S.M * 2)),
        BackgroundTransparency = 1, ScrollBarThickness = 0, CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y, Parent = sidebar,
    })
    -- un solo indicador: fondo lavanda que se desliza
    self._indicator = create("Frame", {
        Size = UDim2.new(1, 0, 0, L.TabHeight), BackgroundColor3 = T("AccentSoft"), Visible = false, Parent = self._tabList,
    })
    corner(self._indicator, R.Row)

    -- tarjeta de perfil
    local prof = Neu.raised(sidebar, {
        Position = UDim2.new(0, S.M, 1, -(L.Profile + S.M)), Size = UDim2.new(1, -S.M * 2, 0, L.Profile),
    }, "Tile", R.Row)
    local profile = prof.Face
    local avatar = create("ImageLabel", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, S.M, 0.5, 0), Size = UDim2.fromOffset(36, 36),
        BackgroundTransparency = 0, BackgroundColor3 = T("Inset"), Parent = profile,
    })
    corner(avatar, R.Round)
    local online = create("Frame", {
        AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 1, 1, 1), Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = T("Success"), Parent = avatar,
    })
    corner(online, R.Round)
    create("UIStroke", { Color = T("Card"), Thickness = 2, Parent = online })
    local profText = create("Frame", {
        Position = UDim2.fromOffset(S.M + 36 + S.M, 0), Size = UDim2.new(1, -(S.M * 2 + 36 + 36), 1, 0),
        BackgroundTransparency = 1, Parent = profile,
    })
    label({ Parent = profText, Text = LocalPlayer.DisplayName, FontFace = F.Semi, TextSize = TS.Label, Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 18) })
    label({
        Parent = profText, Text = txt(o.ProfileSubtitle, "@" .. LocalPlayer.Name), FontFace = F.Regular, TextSize = TS.Desc,
        TextColor3 = T("Muted"), Position = UDim2.fromOffset(0, 29), Size = UDim2.new(1, 0, 0, 16),
    })
    local gearBtn = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -S.XS, 0.5, 0), Size = UDim2.fromOffset(32, 32),
        BackgroundTransparency = 1, Parent = profile,
    })
    local gearIcon = makeIcon("settings", gearBtn, 16, "Muted", centered())
    gearBtn.MouseEnter:Connect(function() gearIcon:Paint("Accent", M.Fast) end)
    gearBtn.MouseLeave:Connect(function() gearIcon:Paint("Muted", M.Base) end)
    gearBtn.MouseButton1Click:Connect(function() if self._settingsTab then self:SelectTab(self._settingsTab) end end)
    bindTooltip(gearBtn, SK("Settings"))
    self._profile, self._profText, self._gearBtn, self._avatar = prof.Holder, profText, gearBtn, avatar
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok and img then avatar.Image = img end
    end)

    ------------------------------------------------------------------------------------------------
    -- CONTENIDO: barra superior + paginas
    ------------------------------------------------------------------------------------------------
    local content = create("Frame", { BackgroundTransparency = 1, Parent = root })
    self._content = content
    -- fondo solido del header (detras del topbar, que sigue recibiendo el arrastre). Deja libre la franja
    -- derecha de R.Window px para no tapar la esquina redondeada de la ventana; ahi se ve la cara de la ventana,
    -- que tiene el mismo color.
    self._headerBg = create("Frame", {
        Size = UDim2.new(1, -R.Window, 0, L.TopBar), BackgroundColor3 = T("Background"), ZIndex = 0, Parent = content,
    })
    local topbar = create("Frame", { Size = UDim2.new(1, 0, 0, L.TopBar), BackgroundTransparency = 1, Parent = content })
    -- bloque titulo + subtitulo: 24 + 2 + 16 = 42 px desde HeaderTop
    local headBlock = 24 + 2 + 16
    local heading = create("Frame", {
        Position = UDim2.fromOffset(L.PagePad, 0), Size = UDim2.new(1, -300, 1, 0), BackgroundTransparency = 1, Parent = topbar,
    })
    self._pageTitle = label({
        Parent = heading, Text = "", FontFace = F.Bold, TextSize = TS.Title, Position = UDim2.fromOffset(0, L.HeaderTop), Size = UDim2.new(1, 0, 0, 24),
    })
    self._pageDesc = label({
        Parent = heading, Text = "", FontFace = F.Regular, TextSize = TS.Desc, TextColor3 = T("Muted"),
        Position = UDim2.fromOffset(0, L.HeaderTop + 26), Size = UDim2.new(1, 0, 0, 16),
    })
    self._heading = heading

    -- buscador y botones centrados exactamente con el bloque titulo + subtitulo
    local controls = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -L.PagePad, 0, L.HeaderTop + headBlock / 2),
        Size = UDim2.fromOffset(320, L.TopButton), BackgroundTransparency = 1, Parent = topbar,
    })
    self._controls = controls
    local btnsW = L.TopButton * 2 + S.M
    local search = create("Frame", { Size = UDim2.new(1, -(btnsW + S.M), 1, 0), Parent = controls })
    corner(search, R.Round)
    local searchInset = Neu.inset(search, R.Round, false, false, true)
    local lens = makeIcon("search", search, L.IconSmall, "Muted", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, S.L, 0.5, 0) })
    local searchBox = create("TextBox", {
        Position = UDim2.fromOffset(S.L + L.IconSmall + S.S, 0), Size = UDim2.new(1, -(S.L * 2 + L.IconSmall + S.S), 1, 0),
        BackgroundTransparency = 1, PlaceholderText = SK("SearchTab"), PlaceholderColor3 = T("Muted"),
        TextColor3 = T("Text"), TextSize = TS.Body, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = search,
    })
    self._searchBox, self._search = searchBox, search
    searchBox.Focused:Connect(function() lens:Paint("Accent", M.Fast) tween(searchInset.Dark, { BackgroundTransparency = 0 }, M.Fast) end)
    searchBox.FocusLost:Connect(function() lens:Paint("Muted", M.Base) end)
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if self._active then self._active:_filter(searchBox.Text) end
    end)

    -- botones redondos elevados (minimizar / cerrar)
    local function topButton(fromRight, iconId, hoverKey)
        local sb = Neu.raised(controls, {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -fromRight, 0, 0), Size = UDim2.fromOffset(L.TopButton, L.TopButton),
        }, "Control", R.Round)
        local b = hitbox(sb.Face)
        edge(sb.Face)
        local icon = makeIcon(iconId, sb.Face, 12, "Text", centered())
        pressable(sb, b, "Default", function(over, _, t) icon:Paint(over and hoverKey or "Text", t) end)
        return b
    end
    local closeBtn = topButton(0, "x", "Error")
    local minBtn = topButton(L.TopButton + S.M, "minus", "Text")
    minBtn.MouseButton1Click:Connect(function()
        self:SetVisible(false)
        if not self._hintShown then
            self._hintShown = true
            local wmk = self._watermark
            local key = (wmk and wmk._usable and wmk:_usable()) and "HiddenBar" or "Hidden"
            Kato:Notify({ Title = self._titleSrc or self.Title, Content = string.format(Kato.Strings[key], keyName(self.ToggleKey)), Duration = 3 })
        end
    end)
    closeBtn.MouseButton1Click:Connect(function()
        self:Dialog({
            Title = SK("CloseTitle"), Content = SK("CloseBody"), Icon = "warning",
            Buttons = {
                { Name = SK("Cancel") },
                { Name = SK("Close"), Primary = true, Callback = function() Kato:Unload() end },
            },
        })
    end)

    -- las paginas empiezan donde termina el header (nada se dibuja debajo del titulo)
    local pagesY = L.TopBar
    -- ClipsDescendants recorta en rectangulo (no sigue el radio de la ventana): el area de paginas se separa
    -- S.S px del borde derecho e inferior para que su esquina quede dentro de la esquina redondeada
    -- ((R.Window - S.S)^2 * 2 <= R.Window^2), asi ninguna tarjeta ni la barra de scroll tapan la curva.
    self._pages = create("Frame", {
        Position = UDim2.fromOffset(0, pagesY), Size = UDim2.new(1, -S.S, 1, -(pagesY + S.S)), BackgroundTransparency = 1,
        ClipsDescendants = true, Parent = content,
    })
    -- desvanecidos en los bordes del area con scroll: el contenido se funde con el fondo en vez de cortarse.
    -- Solo aparecen si hay contenido oculto en esa direccion (ver Window:_updateFades).
    local function fade(top)
        local f = create("Frame", {
            AnchorPoint = Vector2.new(0, top and 0 or 1), Position = UDim2.fromScale(0, top and 0 or 1),
            Size = UDim2.new(1, 0, 0, top and L.FadeTop or L.FadeBottom), BackgroundColor3 = T("Background"),
            BackgroundTransparency = 1, ZIndex = 5, Parent = self._pages,
        })
        -- opaco en el borde -> transparente hacia el contenido. La visibilidad se anima con
        -- BackgroundTransparency (se multiplica con el gradiente), porque un UIGradient no se puede tweenear.
        create("UIGradient", {
            Rotation = 90, Parent = f,
            Transparency = top and nseq({ { 0, 0 }, { 0.45, 0.35 }, { 1, 1 } }) or nseq({ { 0, 1 }, { 0.55, 0.35 }, { 1, 0 } }),
        })
        return { frame = f, top = top, on = false }
    end
    self._fades = { fade(true), fade(false) }

    -- agarre para redimensionar (puntos grabados)
    local grip = create("TextButton", {
        AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -S.S, 1, -S.S), Size = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1, ZIndex = 20, Parent = root,
    })
    for _, p in ipairs({ { 12, 4 }, { 8, 8 }, { 12, 8 }, { 4, 12 }, { 8, 12 }, { 12, 12 } }) do
        local d = create("Frame", { Position = UDim2.fromOffset(p[1], p[2]), Size = UDim2.fromOffset(2, 2), BackgroundColor3 = T("Dim"), Parent = grip })
        corner(d, R.Round)
    end

    -- velo para las animaciones de abrir / cerrar
    self._veil = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T("Background"), ZIndex = 90, Parent = root })
    corner(self._veil, R.Window)

    ------------------------------------------------------------------------------------------------
    -- ARRASTRE Y REDIMENSION
    ------------------------------------------------------------------------------------------------
    local function overControls(pos)
        local ap, as = controls.AbsolutePosition, controls.AbsoluteSize
        return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
    end
    local dragStart, startPos
    local function dragBegan(i)
        if overControls(i.Position) then return false end
        dragStart, startPos = i.Position, holder.Position
        self:_closePopup()
    end
    local function dragMoved(i)
        if not dragStart then return end
        local d = i.Position - dragStart
        tween(holder, {
            Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y),
        }, 0.08)
    end
    onDrag(topbar, dragBegan, dragMoved, function() dragStart = nil end)
    onDrag(brand, dragBegan, dragMoved, function() dragStart = nil end)

    local rStart, rSize, rPos
    onDrag(grip, function(i)
        rStart, rSize, rPos = i.Position, Vector2.new(self.W, self.H), holder.Position
        self:_closePopup()
    end, function(i)
        if not rStart then return end
        local sc = self._uiScale.Scale
        local d = i.Position - rStart
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        local w = math.clamp(rSize.X + d.X / sc, self.MinW, (vp.X - 20) / sc)
        local h = math.clamp(rSize.Y + d.Y / sc, self.MinH, (vp.Y - 20) / sc)
        self.W, self.H = w, h
        self.BaseW, self.BaseH = w, h
        holder.Size = UDim2.fromOffset(w, h)
        holder.Position = UDim2.new(rPos.X.Scale, rPos.X.Offset + (w - rSize.X) * sc / 2, rPos.Y.Scale, rPos.Y.Offset + (h - rSize.Y) * sc / 2)
        self:_layout()
    end, function() rStart = nil end)

    ------------------------------------------------------------------------------------------------
    -- ESCALADO: en pantallas chicas primero reduce el tamano logico y luego la escala,
    -- asi el texto no queda diminuto. Nunca se sale de la pantalla.
    ------------------------------------------------------------------------------------------------
    local function fit()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        local maxW, maxH = vp.X - 20, vp.Y - 20
        local sc = math.clamp(math.min(maxW / self.BaseW, maxH / self.BaseH, 1), 0.6, 1)
        self.W = math.max(math.min(self.BaseW, maxW / sc), math.min(self.MinW, maxW / sc))
        self.H = math.max(math.min(self.BaseH, maxH / sc), math.min(self.MinH, maxH / sc))
        self._fit = sc
        holder.Size = UDim2.fromOffset(self.W, self.H)
        if self.Visible then self._uiScale.Scale = sc * self.UserScale end
        self:_layout()
    end
    self._refit = fit
    fit()
    if workspace.CurrentCamera then conn(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)) end

    -- TECLA PARA ABRIR / CERRAR
    conn(UserInputService.InputBegan:Connect(function(input)
        if Kato._binding or UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == self.ToggleKey and self.ToggleKey ~= Enum.KeyCode.Unknown then self:Toggle() end
    end))

    if o.FloatingButton ~= false then self:_buildFloating() end

    self:_applyGlass(0)
    if o.Intro ~= false then
        self._introActive = true
        self:_intro(function()
            self._introActive = false
            self:SetVisible(true)
        end)
    else
        self:SetVisible(true)
    end
    return self
end

-- adapta sidebar, buscador y columnas al tamano actual de la ventana
function Window:_layout()
    if not self._side then return end
    local compact = self.W < L.CompactBelow
    local sw = compact and L.SidebarCompact or self.SW
    self._compact = compact
    self._side.Size = UDim2.new(0, sw, 1, -L.Margin * 2)
    local cx = L.Margin + sw + S.S
    self._content.Position = UDim2.fromOffset(cx, 0)
    self._content.Size = UDim2.new(1, -cx, 1, 0)
    self._brandText.Visible = not compact
    self._profText.Visible = not compact
    self._gearBtn.Visible = not compact
    local inner = sw - S.M * 2
    self._avatar.Position = UDim2.new(0, compact and math.floor((inner - 36) / 2) or S.M, 0.5, 0)
    for _, t in ipairs(self._tabs) do if t._setCompact then t:_setCompact(compact) end end
    for _, c in ipairs(self._categories or {}) do c.text.Visible = not compact c.line.Visible = compact and c.index > 1 end

    -- buscador: se encoge antes que el titulo
    local cw = self.W - cx
    local btnsW = L.TopButton * 2 + S.M
    local searchW = math.clamp(cw - L.PagePad * 2 - btnsW - S.M - 220, 120, 240)
    self._controls.Size = UDim2.fromOffset(searchW + btnsW + S.M, L.TopButton)
    self._heading.Size = UDim2.new(1, -(searchW + btnsW + S.M + L.PagePad * 2 + S.M), 1, 0)

    local single = (cw - L.PagePad * 2) < L.SingleBelow
    if single ~= self._single then
        self._single = single
        for _, t in ipairs(self._tabs) do t:_setColumns(single) end
    end
    if self._active then self:_moveIndicator(self._active, false) end
end

-- muestra u oculta los desvanecidos del area de paginas segun la posicion del scroll
-- force: reaplica aunque el estado no cambie (por ejemplo al cambiar la transparencia de la ventana)
function Window:_updateFades(t, force)
    local fades = self._fades
    if not fades then return end
    local page = self._active and self._active._page
    local showTop, showBottom = false, false
    if page and page.Parent then
        local y = page.CanvasPosition.Y
        -- CanvasPosition y AbsoluteCanvasSize pueden venir en escalas distintas con UIScale:
        -- se usa el maximo mas pequeno de los dos para no mostrar nunca el fade inferior al final
        local m = page.AbsoluteCanvasSize.Y - page.AbsoluteWindowSize.Y
        local sc = math.max(self._uiScale.Scale, 0.01)
        local maxY = math.min(m, m / sc)
        showTop = y > 1
        showBottom = maxY > 2 and y < maxY - 2
    end
    local base = self._rootT or 0
    for _, f in ipairs(fades) do
        local on = (f.top and showTop) or ((not f.top) and showBottom)
        if on ~= f.on or force then
            f.on = on
            tween(f.frame, { BackgroundTransparency = on and base or 1 }, t)
        end
    end
end

-- transparencia opcional de la ventana (API SetGlass / SetGlassStrength)
function Window:_glass(inst, solid, glass)
    table.insert(self._glassParts, { inst, solid, glass })
    inst.BackgroundTransparency = self.Glass and (solid + (glass - solid) * self.GlassStrength) or solid
end

function Window:_applyGlass(t)
    for _, p in ipairs(self._glassParts) do
        local inst = p[1]
        if inst.Parent then
            local v = self.Glass and (p[2] + (p[3] - p[2]) * self.GlassStrength) or p[2]
            tween(inst, { BackgroundTransparency = v }, t or M.Slow)
            if inst == self._root then self._rootT = v end
        end
    end
    -- el fondo del header no tiene nada debajo: en modo translucido desaparece para no oscurecer esa franja
    if self._headerBg then tween(self._headerBg, { BackgroundTransparency = self.Glass and 1 or 0 }, t or M.Slow) end
    self:_updateFades(t or M.Slow, true)
end

function Window:SetGlass(on)
    self.Glass = on ~= false
    self:_applyGlass(M.Slow)
    Kato._state.Glass = self.Glass
    saveState()
end

function Window:SetGlassStrength(v)
    self.GlassStrength = math.clamp(tonumber(v) or 0.5, 0, 1)
    self:_applyGlass(M.Fast)
    Kato._state.GlassStrength = self.GlassStrength
    saveState()
end

function Window:SetBlur(on)
    self.Blur = on == true
    setBlur(self.Blur and self.Visible)
    Kato._state.Blur = self.Blur
    saveState()
end

function Window:SetScale(v)
    self.UserScale = math.clamp(tonumber(v) or 1, 0.6, 1.4)
    if self.Visible then tween(self._uiScale, { Scale = self._fit * self.UserScale }, M.Base) end
    Kato._state.Scale = self.UserScale
    saveState()
end

function Window:SetToggleKey(k)
    self.ToggleKey = toKey(k) or self.ToggleKey
    Kato._state.ToggleKey = self.ToggleKey.Name
    saveState()
end

function Window:SetTitle(t)
    self._titleSrc = txt(t, "")
    self.Title = tr(self._titleSrc)
    setText(self._title, "Text", self._titleSrc)
end
function Window:SetSubtitle(t)
    self._subtitleSrc = txt(t, "")
    self.Subtitle = tr(self._subtitleSrc)
    setText(self._subtitle, "Text", self._subtitleSrc)
end

-- tamano de la pantalla (area del ScreenGui)
local function screenSize()
    local ok, v = pcall(function() return gui.AbsoluteSize end)
    if ok and v and v.X > 0 then return v end
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end
-- duracion real de una animacion (respeta Config.Animations y Config.AnimationSpeed)
local function dur(t)
    if not Kato.Config.Animations then return 0 end
    return t / math.max(Kato.Config.AnimationSpeed or 1, 0.05)
end

-- "fantasma" que transforma la ventana en la barra (o al reves): centro, tamano, radio y color.
-- Todo se calcula con posiciones/tamanos logicos (no con AbsoluteSize de algo oculto).
local GhostParts = setmetatable({}, { __mode = "k" })
function Window:_morph(a, b, iconIn, t, style, dir, done)
    if self._ghost then pcall(function() self._ghost:Destroy() end) end
    local g = create("Frame", {
        Name = "KatoMorph", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(a.c.X, a.c.Y), Size = UDim2.fromOffset(a.s.X, a.s.Y),
        BackgroundColor3 = Color[a.key] or Color.Background, ZIndex = 115, Parent = gui,
    })
    local gc = create("UICorner", { CornerRadius = UDim.new(0, a.r), Parent = g })
    local gs = create("UIStroke", { Color = Color.WindowStroke or Color.Edge, Transparency = 0.5, Thickness = 1, Parent = g })
    -- sombra suave que acompana a la forma (se ve "volar" sobre el juego)
    local sh = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 6), Size = UDim2.new(1, 10, 1, 10),
        BackgroundColor3 = Color.Shadow, BackgroundTransparency = 0.82, ZIndex = 114, Parent = g,
    })
    local shc = create("UICorner", { CornerRadius = UDim.new(0, a.r + 5), Parent = sh })
    local ic = create("ImageLabel", centered({
        Size = UDim2.fromOffset(26, 26), Image = self.Icon, ImageTransparency = iconIn and 1 or 0, ZIndex = 116, Parent = g,
    }))
    corner(ic, R.Round)
    GhostParts[g] = { icon = ic, stroke = gs, shadow = sh }
    self._ghost = g
    tween(g, { Position = UDim2.fromOffset(b.c.X, b.c.Y), Size = UDim2.fromOffset(b.s.X, b.s.Y), BackgroundColor3 = Color[b.key] or Color.Card }, t, style, dir)
    tween(gc, { CornerRadius = UDim.new(0, b.r) }, t, style, dir)
    tween(shc, { CornerRadius = UDim.new(0, b.r + 5) }, t, style, dir)
    tween(ic, { ImageTransparency = iconIn and 0 or 1, Size = UDim2.fromOffset(iconIn and 22 or 30, iconIn and 22 or 30) }, t * 0.7)
    task.delay(dur(t), function()
        if self._ghost ~= g then return end
        if done then done(g) end
    end)
end

-- quita el fantasma con un fundido corto (deja ver lo que hay debajo)
function Window:_dropGhost(g, fadeT)
    if not g or not g.Parent then return end
    if self._ghost == g then self._ghost = nil end
    local parts = GhostParts[g]
    if parts then
        tween(parts.icon, { ImageTransparency = 1 }, fadeT)
        tween(parts.stroke, { Transparency = 1 }, fadeT)
        tween(parts.shadow, { BackgroundTransparency = 1 }, fadeT)
    end
    tween(g, { BackgroundTransparency = 1 }, fadeT)
    task.delay(dur(fadeT) + 0.03, function() pcall(function() g:Destroy() end) end)
end

-- rectangulo logico de la ventana en pantalla: centro + tamano escalado
function Window:_windowRect(scale)
    local gs = screenSize()
    local p = self._holder.Position
    local c = Vector2.new(gs.X * p.X.Scale + p.X.Offset, gs.Y * p.Y.Scale + p.Y.Offset)
    return c, Vector2.new(self.W, self.H) * scale
end

local MORPH_CLOSE, MORPH_OPEN = 0.55, 0.5

function Window:SetVisible(v)
    v = v ~= false
    local was = self.Visible
    self.Visible = v
    local holder, veil = self._holder, self._veil
    local target = (self._fit or 1) * self.UserScale
    self._animToken = (self._animToken or 0) + 1
    local my = self._animToken
    hideTip()
    local bar = self._watermark
    local barMode = bar and bar._usable and bar:_usable()
    -- la transformacion solo se usa en aperturas/cierres del jugador (no en la intro)
    local morph = barMode and Kato.Config.Animations and self._opened and was ~= v
    if self._ghost then self:_dropGhost(self._ghost, 0) end

    local function showWindow(fromMorph)
        holder.Visible = true
        veil.Visible = true
        veil.BackgroundTransparency = 0
        self._uiScale.Scale = target * (fromMorph and 1 or 0.97)
        tween(self._uiScale, { Scale = target }, M.Slow)
        tween(veil, { BackgroundTransparency = 1 }, fromMorph and 0.35 or M.Slow)
        self._surface:Set("Window", M.Slow)
        task.delay(dur(0.35) + 0.02, function() if my == self._animToken then veil.Visible = false end end)
        if self._active then self._active:_reveal(0.08) end
    end

    if v then
        if morph then
            -- la barra se hunde un instante y crece hasta convertirse en la ventana
            local bc, bs = bar:_rect()
            bar:_show(false)
            holder.Visible = false
            self._uiScale.Scale = target
            self._surface:Set("Flat", 0)
            local wc, wsz = self:_windowRect(target)
            self:_morph(
                { c = bc, s = bs, r = bs.Y / 2, key = "Card" },
                { c = wc, s = wsz, r = R.Window * target, key = "Background" },
                false, MORPH_OPEN, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
                function(g)
                    if my ~= self._animToken then return end
                    showWindow(true)
                    self:_dropGhost(g, 0.25)
                end)
        else
            if bar and bar._show then bar:_show(false) end
            showWindow(false)
        end
        self._opened = true
    else
        self:_closePopup()
        if morph then
            -- el contenido se funde, la ventana se "aspira" hacia la barra y la barra rebota al recibirla
            local wc, wsz = self:_windowRect(target)
            veil.Visible = true
            tween(veil, { BackgroundTransparency = 0 }, 0.12)
            tween(self._uiScale, { Scale = target * 0.985 }, 0.12)
            self._surface:Set("Flat", 0.12)
            task.delay(dur(0.12), function()
                if my ~= self._animToken then return end
                holder.Visible = false
                self._uiScale.Scale = target
                local bc, bs = bar:_rect()
                self:_morph(
                    { c = wc, s = wsz * 0.985, r = R.Window * target, key = "Background" },
                    { c = bc, s = bs, r = bs.Y / 2, key = "Card" },
                    true, MORPH_CLOSE, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut,
                    function(g)
                        if my ~= self._animToken or self.Visible then return end
                        bar:_show(true)
                        bar:_land()
                        self:_dropGhost(g, 0.12)
                    end)
            end)
        else
            veil.Visible = true
            tween(veil, { BackgroundTransparency = 0 }, M.Fast)
            tween(self._uiScale, { Scale = target * 0.97 }, M.Base, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            self._surface:Set("Flat", M.Fast)
            task.delay(dur(M.Base) + 0.02, function()
                if my ~= self._animToken then return end
                holder.Visible = false
                if barMode and not self.Visible then
                    bar:_show(true)
                    if self._opened then bar:_land() end
                end
            end)
        end
    end
    setBlur(self.Blur and v)
    if self._floatRefresh then self._floatRefresh() end
end

function Window:Toggle() self:SetVisible(not self.Visible) end
function Window:Show() self:SetVisible(true) end
function Window:Hide() self:SetVisible(false) end
function Window:Notify(o) return Kato:Notify(o) end
function Window:Destroy() Kato:Unload() end

-- boton flotante: siempre en moviles; en PC aparece cuando el menu esta oculto
function Window:_buildFloating()
    local fs = Neu.raised(gui, {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 56, 0.5, 0), Size = UDim2.fromOffset(52, 52),
        Visible = false, ZIndex = 120,
    }, "Float", R.Round)
    local fb = fs.Holder
    local hit = hitbox(fs.Face)
    local img = create("ImageLabel", centered({ Size = UDim2.fromOffset(30, 30), Image = self.Icon, Parent = fs.Face }))
    corner(img, R.Small)
    local sc = create("UIScale", { Parent = fb })
    local function refresh()
        -- con la barra en modo boton, ella reemplaza al boton flotante
        local barOn = self._watermark and self._watermark._usable and self._watermark:_usable()
        local show = (UserInputService.TouchEnabled or not self.Visible) and not Kato.Unloaded and not barOn
        if show == fb.Visible then return end
        if show then
            fb.Visible = true
            sc.Scale = 0.6
            tween(sc, { Scale = 1 }, M.Base)
        else
            tween(sc, { Scale = 0.6 }, M.Fast)
            task.delay(M.Fast, function()
                local on = self._watermark and self._watermark._usable and self._watermark:_usable()
                if on or not (UserInputService.TouchEnabled or not self.Visible) then fb.Visible = false end
            end)
        end
    end
    self._floatRefresh = refresh

    local start, startPos, moved
    onDrag(hit, function(i)
        start, startPos, moved = i.Position, fb.Position, false
        fs:Press(true, M.Fast)
    end, function(i)
        if not start then return end
        local d = i.Position - start
        if not moved and d.Magnitude > 6 then moved = true end
        if moved then
            fb.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end, function()
        fs:Press(false, M.Base)
        if not moved then self:Toggle() end
        start = nil
    end)
    refresh()
end

-- INTRO: logo en una tarjeta elevada, titulo y barra hundida. Click para saltar.
function Window:_intro(done)
    local layer = create("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = T("Background"), BackgroundTransparency = 1, ZIndex = 200, Parent = gui,
    })
    local skip = false
    layer.MouseButton1Click:Connect(function() skip = true end)
    local center = create("Frame", centered({ Size = UDim2.fromOffset(280, 200), BackgroundTransparency = 1, Parent = layer }))
    local tile = Neu.raised(center, {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(84, 84),
    }, "Card", R.Window)
    tile:Set("Flat", 0)
    tile.Face.BackgroundTransparency = 1
    local icon = create("ImageLabel", centered({ Size = UDim2.fromOffset(52, 52), Image = self.Icon, ImageTransparency = 1, Parent = tile.Face }))
    corner(icon, R.Control)
    local title = label({
        Parent = center, Text = self._titleSrc, FontFace = F.Bold, TextSize = TS.Title + 4, TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 84 + S.XL), Size = UDim2.new(1, 0, 0, 28),
    })
    local sub = label({
        Parent = center, Text = self._subtitleSrc, FontFace = F.Regular, TextSize = TS.Desc, TextColor3 = T("Muted"), TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 84 + S.XL + 30), Size = UDim2.new(1, 0, 0, 16),
    })
    local track = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 84 + S.XL + 30 + S.XXL), Size = UDim2.fromOffset(160, L.Track),
        BackgroundTransparency = 1, Parent = center,
    })
    corner(track, R.Round)
    local trackInset = Neu.inset(track, R.Round, true)
    local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = T("Accent"), BackgroundTransparency = 1, Parent = track })
    corner(fill, R.Round)

    local function sleep(t)
        local s0 = os.clock()
        while os.clock() - s0 < t and not skip do task.wait() end
    end
    task.spawn(function()
        tween(layer, { BackgroundTransparency = 0.06 }, M.Slow)
        tween(tile.Face, { BackgroundTransparency = 0 }, M.Slow)
        tile:Set("Card", M.Slow)
        tween(icon, { ImageTransparency = 0 }, M.Slow)
        sleep(0.15)
        tween(title, { TextTransparency = 0 }, M.Slow)
        tween(sub, { TextTransparency = 0 }, M.Slow)
        tween(track, { BackgroundTransparency = 0 }, M.Slow)
        trackInset:Show(true, M.Slow)
        fill.BackgroundTransparency = 0
        tween(fill, { Size = UDim2.fromScale(1, 1) }, 1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        sleep(1.25)
        tween(layer, { BackgroundTransparency = 1 }, M.Slow)
        tile:Set("Flat", M.Base)
        tween(tile.Face, { BackgroundTransparency = 1 }, M.Base)
        tween(icon, { ImageTransparency = 1 }, M.Base)
        tween(title, { TextTransparency = 1 }, M.Base)
        tween(sub, { TextTransparency = 1 }, M.Base)
        tween(track, { BackgroundTransparency = 1 }, M.Base)
        trackInset:Show(false, M.Base)
        tween(fill, { BackgroundTransparency = 1 }, M.Base)
        task.wait(0.1)
        if not Kato.Unloaded then done() end
        task.wait(M.Slow)
        layer:Destroy()
    end)
end

----------------------------------------------------------------------------------------------------
-- POPUP FLOTANTE (dropdowns y color pickers). Se ancla a un control y nunca sale de la ventana.
----------------------------------------------------------------------------------------------------
function Window:_closePopup()
    if self._popupApi then self._popupApi.Close() end
end

function Window:_popup(anchor, w, h, build, onClose)
    self:_closePopup()
    local root = self._root
    local sc = root.AbsoluteSize.X / math.max(self.W, 1)
    if sc <= 0 then sc = 1 end
    h = math.min(h, self.H - 24)
    w = math.min(w, self.W - 24)
    local ap = (anchor.AbsolutePosition - root.AbsolutePosition) / sc
    local asz = anchor.AbsoluteSize / sc
    local x = math.clamp(ap.X + asz.X - w, S.M, self.W - w - S.M)
    local y = ap.Y + asz.Y + S.S
    local up = false
    if y + h > self.H - S.M then
        if ap.Y - h - S.S >= S.M then
            y, up = ap.Y - h - S.S, true
        else
            y = math.max(S.M, self.H - h - S.M)
        end
    end

    local catcher = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 70, Parent = root })
    local ps = Neu.raised(catcher, {
        Position = UDim2.fromOffset(x, y + (up and 6 or -6)), Size = UDim2.fromOffset(w, h),
    }, "Popup", R.Card)
    ps:Set("Flat", 0)
    ps:Set("Popup", M.Base)
    local panel = ps.Face
    panel.ClipsDescendants = true
    -- velo: el panel aparece con un fundido sin perder nitidez en el texto
    local veil = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T("Card"), ZIndex = 50, Parent = panel })
    corner(veil, R.Card)
    tween(veil, { BackgroundTransparency = 1 }, M.Base)
    tween(ps.Holder, { Position = UDim2.fromOffset(x, y) }, M.Base)

    local api, closed = { Panel = panel }, false
    function api.Close()
        if closed then return end
        closed = true
        if self._popupApi == api then self._popupApi = nil end
        tween(veil, { BackgroundTransparency = 0 }, M.Fast)
        ps:Set("Flat", M.Fast)
        tween(ps.Holder, { Position = UDim2.fromOffset(x, y + (up and 4 or -4)) }, M.Fast)
        task.delay(M.Fast, function() catcher:Destroy() end)
        if onClose then onClose() end
    end
    catcher.MouseButton1Click:Connect(api.Close)
    self._popupApi = api
    build(panel, api)
    return api
end

----------------------------------------------------------------------------------------------------
-- DIALOGO MODAL
----------------------------------------------------------------------------------------------------
-- boton de dialogo / accion: elevado (secundario) o morado solido (primario)
local function actionButton(parent, text, style, props)
    local primary = style == "Primary"
    local sb = Neu.raised(parent, props, "Control", R.Row)
    if primary then paint(sb.Face, "BackgroundColor3", "AccentStrong") end
    if style == "Danger" then paint(sb.Face, "BackgroundColor3", "DangerSoft") end
    if not primary then edge(sb.Face, style == "Danger" and "Error" or "Edge") end
    local btn = create("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = txt(text, ""), FontFace = F.Semi, TextSize = TS.Label,
        TextColor3 = T(primary and "OnAccent" or (style == "Danger" and "DangerText" or "Text")), ZIndex = 4, Parent = sb.Face,
    })
    pressable(sb, btn, primary and "Primary" or "Default")
    return btn, sb
end

function Window:Dialog(o)
    o = o or {}
    self:_closePopup()
    local overlay = create("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = T("Background"), BackgroundTransparency = 1, ZIndex = 80, Parent = self._root,
    })
    corner(overlay, R.Window)
    local width = math.min(360, self.W - S.XXXL * 2)
    local ds = Neu.raised(overlay, centered({ Size = UDim2.fromOffset(width, 0), Position = UDim2.new(0.5, 0, 0.5, S.S) }), "Popup", R.Card, true)
    ds:Set("Flat", 0)
    local card = ds.Face
    local veil = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T("Card"), ZIndex = 50, Parent = card })
    corner(veil, R.Card)
    local inner = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card })
    pad(inner, S.XL, S.XL, S.XL, S.XL)
    list(inner, S.M)

    local head = create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 1, Parent = inner })
    makeIcon(o.Icon or "info", head, 20, "Accent", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) })
    label({
        Parent = head, Text = txt(o.Title, "Kato Hub"), FontFace = F.Bold, TextSize = TS.Dialog,
        Position = UDim2.fromOffset(20 + S.M, 0), Size = UDim2.new(1, -(20 + S.M), 1, 0),
    })
    if o.Content then
        label({
            Parent = inner, LayoutOrder = 2, Text = txt(o.Content, ""), TextColor3 = T("Muted"), TextSize = TS.Body,
            FontFace = F.Regular, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0), RichText = true, LineHeight = 1.15,
        })
    end
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 40 + S.S), BackgroundTransparency = 1, LayoutOrder = 3, Parent = inner })
    local rl = list(row, S.M, true)
    rl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    rl.VerticalAlignment = Enum.VerticalAlignment.Bottom

    local closed = false
    local function close()
        if closed then return end
        closed = true
        tween(overlay, { BackgroundTransparency = 1 }, M.Base)
        tween(veil, { BackgroundTransparency = 0 }, M.Fast)
        ds:Set("Flat", M.Fast)
        task.delay(M.Fast, function() card.Visible = false end)
        task.delay(M.Base + 0.02, function() overlay:Destroy() end)
    end
    local buttons = o.Buttons or { { Name = "OK", Primary = true } }
    local bw = math.floor((width - S.XL * 2 - S.M * (#buttons - 1)) / #buttons)
    for i, b in ipairs(buttons) do
        local btn = actionButton(row, b.Name or "OK", b.Primary and "Primary" or (b.Danger and "Danger" or "Default"), {
            Size = UDim2.fromOffset(bw, 40), LayoutOrder = i,
        })
        btn.MouseButton1Click:Connect(function()
            close()
            safeCall(b.Callback)
        end)
    end
    tween(overlay, { BackgroundTransparency = 0.3 }, M.Base)
    tween(veil, { BackgroundTransparency = 1 }, M.Slow)
    tween(ds.Holder, { Position = UDim2.fromScale(0.5, 0.5) }, M.Slow)
    ds:Set("Popup", M.Slow)
    return { Close = close }
end

----------------------------------------------------------------------------------------------------
-- WATERMARK / BARRA (logo, fps, ping, hora): pastilla clara elevada
----------------------------------------------------------------------------------------------------
-- Por defecto la barra va arriba al centro y hace de boton del menu (Toggle = true):
-- con el menu abierto se oculta; al minimizar, la ventana se transforma en la barra y un click la vuelve a abrir.
-- Toggle = false: la barra queda siempre visible y solo muestra datos (comportamiento de v3.2).
-- El ancho se calcula con TextService (no con AutomaticSize): asi la barra tiene su tamano exacto
-- incluso mientras esta oculta, y la animacion siempre sabe a donde ir.
local TextService = game:GetService("TextService")
local MEASURE_FONT = (function()
    local ok, f = pcall(function() return Enum.Font.BuilderSansMedium end)
    return ok and f or Enum.Font.GothamMedium
end)()
local function textWidth(s, size, bold)
    s = tostring(s or "")
    if s == "" then return 0 end
    local ok, v = pcall(function()
        local font = MEASURE_FONT
        if bold then
            local ok2, fb = pcall(function() return Enum.Font.BuilderSansBold end)
            if ok2 and fb then font = fb end
        end
        return TextService:GetTextSize(s, size, font, Vector2.new(4000, 100)).X
    end)
    if ok and type(v) == "number" and v > 0 then return math.ceil(v * 1.04) + 1 end
    return math.ceil(#s * size * 0.56)
end


local BAR_H, BAR_ARROW = 36, 18

function Window:CreateWatermark(o)
    o = o or {}
    local win = self
    if self._watermark then self._watermark:Destroy() end
    local toggleMode = o.Toggle ~= false
    local ws = Neu.raised(gui, {
        AnchorPoint = o.AnchorPoint or (o.Position and Vector2.new(0, 0) or Vector2.new(0.5, 0)),
        Position = o.Position or UDim2.new(0.5, 0, 0, S.L), Size = UDim2.fromOffset(160, BAR_H), ZIndex = 110,
    }, "Float", R.Round)
    local wm, face = ws.Holder, ws.Face
    local pop = create("UIScale", { Parent = wm })
    -- contorno de acento suave: indica que la barra es un boton (solo en modo Toggle)
    local ring = toggleMode and create("UIStroke", {
        Color = T("Accent"), Thickness = 1.5, Transparency = 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = face,
    }) or nil

    local ic = create("ImageLabel", {
        Image = self.Icon, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 7, 0.5, 0), Size = UDim2.fromOffset(22, 22),
        ZIndex = 2, Parent = face,
    })
    corner(ic, R.Round)
    local titleSrc = txt(o.Text, self._titleSrc)
    local title = label({
        Parent = face, Text = titleSrc, FontFace = F.Semi, TextSize = TS.Body, ZIndex = 2,
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 37, 0.5, 0), Size = UDim2.fromOffset(60, 20),
        TextTruncate = Enum.TextTruncate.None,
    })
    local sep = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 100, 0.5, 0), Size = UDim2.fromOffset(4, 4),
        BackgroundColor3 = T("Dim"), ZIndex = 2, Parent = face,
    })
    corner(sep, R.Round)
    local info = label({
        Parent = face, Text = "", FontFace = F.Regular, TextSize = TS.Desc, TextColor3 = T("Muted"), ZIndex = 2,
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 112, 0.5, 0), Size = UDim2.fromOffset(60, 18),
        TextTruncate = Enum.TextTruncate.None,
    })
    -- flecha (solo modo Toggle): aparece al pasar el raton, deslizandose desde el borde derecho
    local arrowClip, arrow
    if toggleMode then
        arrowClip = create("Frame", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(0, 16),
            BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 2, Parent = face,
        })
        arrow = makeIcon("chevron", arrowClip, 12, "Accent", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), ZIndex = 2 })
    end

    local hover, pressing, nudge = false, false, nil
    local baseW = 160
    -- recoloca el contenido y devuelve el ancho base (sin la flecha)
    local function layoutBar(animate)
        local tw = textWidth(title.Text, TS.Body, true)
        local iw = textWidth(info.Text, TS.Desc, false)
        title.Size = UDim2.fromOffset(tw, 20)
        local x = 37 + tw
        local hasInfo = iw > 0
        sep.Visible, info.Visible = hasInfo, hasInfo
        if hasInfo then
            sep.Position = UDim2.new(0, x + 8, 0.5, 0)
            info.Position = UDim2.new(0, x + 20, 0.5, 0)
            info.Size = UDim2.fromOffset(iw, 18)
            x = x + 20 + iw
        end
        baseW = x + 14
        local w = baseW + ((toggleMode and hover) and BAR_ARROW or 0)
        tween(wm, { Size = UDim2.fromOffset(w, BAR_H) }, animate and M.Base or 0)
        return baseW
    end
    layoutBar(false)
    onLanguage(title, function() layoutBar(true) end)

    local function setHover(on)
        if not toggleMode then return end
        hover = on
        layoutBar(true)
        tween(arrowClip, { Size = UDim2.fromOffset(on and 12 or 0, 16) }, on and M.Base or M.Fast)
        paint(title, "TextColor3", on and "AccentText" or "Text", M.Fast)
        if ring then tween(ring, { Transparency = on and 0.15 or 0.55 }, M.Fast) end
        ws:Lift(on, on and M.Fast or M.Base)
        -- la flecha "empuja" hacia la derecha mientras el raton esta encima
        if nudge then pcall(function() nudge:Cancel() end) nudge = nil end
        arrowClip.Position = UDim2.new(1, -12, 0.5, 0)
        if on and Kato.Config.Animations then
            local okT, tw = pcall(function()
                return TweenService:Create(arrowClip, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                    { Position = UDim2.new(1, -8, 0.5, 0) })
            end)
            if okT and tw then nudge = tw tw:Play() end
        end
    end

    -- arrastrar mueve la barra; un click sin arrastrar abre el menu (modo Toggle)
    local start, startPos, moved
    onDrag(face, function(i)
        start, startPos, moved = i.Position, wm.Position, false
        if toggleMode then
            pressing = true
            tween(pop, { Scale = 0.94 }, M.Fast)
        end
    end, function(i)
        if not start then return end
        local d = i.Position - start
        if not moved and d.Magnitude > 6 then moved = true end
        if moved then
            wm.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end, function()
        if not start then return end
        start = nil
        if toggleMode then
            pressing = false
            tween(pop, { Scale = 1 }, M.Base, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            if not moved and not win.Visible then
                setHover(false)
                win:SetVisible(true)
            end
        end
    end)
    if toggleMode then
        face.MouseEnter:Connect(function() if not start then setHover(true) end end)
        face.MouseLeave:Connect(function() if not pressing then setHover(false) end end)
        bindTooltip(face, function() return not win.Visible and SK("OpenMenu") or nil end)
    end

    local frames, last = 0, os.clock()
    local hb = RunService.Heartbeat:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - last < 0.5 then return end
        local parts = {}
        if o.FPS ~= false then table.insert(parts, math.floor(frames / (now - last) + 0.5) .. " fps") end
        if o.Ping ~= false then
            local ok, p = pcall(function() return LocalPlayer:GetNetworkPing() end)
            if ok and p then table.insert(parts, math.floor(p * 1000 + 0.5) .. " ms") end
        end
        if o.Time ~= false then table.insert(parts, os.date("%H:%M")) end
        local s = table.concat(parts, "  ·  ")
        frames, last = 0, now
        if s ~= info.Text then
            info.Text = s
            layoutBar(wm.Visible)
        end
    end)
    conn(hb)

    local obj = { Frame = wm, Toggle = toggleMode, _surface = ws }
    local userHidden = false
    -- rectangulo exacto en pantalla (relativo al ScreenGui), calculado sin depender de que este visible
    function obj:_rect()
        local gs = screenSize()
        local p, a = wm.Position, wm.AnchorPoint
        local size = Vector2.new(baseW, BAR_H)
        local topLeft = Vector2.new(gs.X * p.X.Scale + p.X.Offset, gs.Y * p.Y.Scale + p.Y.Offset) - size * a
        return topLeft + size / 2, size
    end
    function obj:_usable() return toggleMode and not userHidden and wm.Parent ~= nil end
    -- _show: lo usa la ventana (la barra se oculta mientras el menu esta abierto)
    function obj:_show(v)
        v = v and not userHidden
        if v and not wm.Visible then
            hover, pressing = false, false
            if arrowClip then arrowClip.Size = UDim2.fromOffset(0, 16) end
            paint(title, "TextColor3", "Text", 0)
            layoutBar(false)
            ws:Lift(false, 0)
            pop.Scale = 1
        end
        if not v and nudge then pcall(function() nudge:Cancel() end) nudge = nil end
        wm.Visible = v
    end
    -- llegada: rebote + onda de acento (deja claro que el menu "vive" en la barra)
    function obj:_land()
        if not wm.Visible then return end
        pop.Scale = 0.82
        tween(pop, { Scale = 1 }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        if not Kato.Config.Animations then return end
        local c, size = self:_rect()
        local wave = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(c.X, c.Y), Size = UDim2.fromOffset(size.X, size.Y),
            BackgroundTransparency = 1, ZIndex = 109, Parent = gui,
        })
        corner(wave, R.Round)
        local st = create("UIStroke", { Color = Color.Accent, Thickness = 2, Transparency = 0.1, Parent = wave })
        tween(wave, { Size = UDim2.fromOffset(size.X + 34, size.Y + 26) }, 0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        tween(st, { Transparency = 1, Thickness = 0.5 }, 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        task.delay(dur(0.6) + 0.05, function() pcall(function() wave:Destroy() end) end)
    end
    function obj:SetVisible(v)
        userHidden = v == false
        if toggleMode then self:_show(not win.Visible and not win._introActive) else wm.Visible = not userHidden end
        if win._floatRefresh then win._floatRefresh() end
    end
    function obj:Destroy()
        hb:Disconnect()
        if nudge then pcall(function() nudge:Cancel() end) end
        wm:Destroy()
        if win._watermark == self then win._watermark = nil end
        if win._floatRefresh then win._floatRefresh() end
    end
    self._watermark = obj
    if toggleMode then obj:_show(not self.Visible and not self._introActive) end
    if self._floatRefresh then self._floatRefresh() end
    return obj
end

----------------------------------------------------------------------------------------------------
-- SIDEBAR: categorias y tabs (posicion manual + indicador deslizante)
----------------------------------------------------------------------------------------------------
function Window:_place(item, h, gap)
    item.Position = UDim2.fromOffset(0, self._listY)
    self._listY = self._listY + h + (gap or S.XS)
    self._tabList.CanvasSize = UDim2.fromOffset(0, self._listY)
end

function Window:AddCategory(text)
    self._categories = self._categories or {}
    local index = #self._categories + 1
    local first = self._listY == 0
    local h = first and 22 or 34
    local f = create("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self._tabList })
    local txt = label({
        Parent = f, Text = TF(function() return string.upper(tr(text)) end), FontFace = F.Semi, TextSize = TS.Caption, TextColor3 = T("Caption"),
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, S.M, 1, -S.S), Size = UDim2.new(1, -S.M, 0, 14),
    })
    -- en modo compacto el texto se oculta y queda una linea grabada como separador
    local line = groove(f, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -S.M), Size = UDim2.new(1, -S.M, 0, 2) })
    table.insert(self._categories, { frame = f, text = txt, line = line, index = index })
    txt.Visible = not self._compact
    line.Visible = self._compact == true and index > 1
    self:_place(f, h, 2)
    return txt
end

function Window:_moveIndicator(tab, animate)
    local ind = self._indicator
    ind.Visible = true
    tween(ind, { Position = tab._btn.Position, Size = tab._btn.Size }, animate and M.Slow or 0)
    -- mantener el tab activo visible dentro de la lista
    local list0 = self._tabList
    local y = tab._btn.Position.Y.Offset
    local viewH = list0.AbsoluteSize.Y / math.max(self._uiScale.Scale, 0.01)
    if y < list0.CanvasPosition.Y then
        list0.CanvasPosition = Vector2.new(0, y)
    elseif y + L.TabHeight > list0.CanvasPosition.Y + viewH then
        list0.CanvasPosition = Vector2.new(0, y + L.TabHeight - viewH)
    end
end

function Window:CreateTab(name, icon, desc)
    local o = type(name) == "table" and name or { Name = name, Icon = icon, Description = desc }
    local win = self
    local tab = setmetatable({
        Window = self, Description = o.Description,
        _items = {}, _sections = {}, _blocks = {}, _order = 0,
    }, Tab)
    tab._nameSrc = txt(o.Name, "Tab")
    tab.Name = tr(tab._nameSrc)

    local btn = create("TextButton", { Size = UDim2.new(1, 0, 0, L.TabHeight), BackgroundTransparency = 1, Parent = self._tabList })
    self:_place(btn, L.TabHeight, S.XS)
    local iconApi = makeIcon(o.Icon, btn, L.Icon, "Muted", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, S.M, 0.5, 0),
    }, tab.Name)
    if o.IconTint == false and iconApi.Holder:IsA("ImageLabel") then
        Bound[iconApi.Holder] = nil
        iconApi.Holder.ImageColor3 = WHITE
    end
    local nameLbl = label({
        Parent = btn, Text = tab._nameSrc, FontFace = F.Medium, TextSize = TS.Label, TextColor3 = T("Muted"),
        Position = UDim2.new(0, S.M * 2 + L.Icon, 0, 0), Size = UDim2.new(1, -(S.M * 3 + L.Icon), 1, 0),
    })
    local badge
    if o.Badge then
        badge = label({
            Parent = btn, Text = txt(o.Badge, ""), FontFace = F.Semi, TextSize = TS.Caption, TextColor3 = T("Accent2Text"),
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -S.S, 0.5, 0), Size = UDim2.fromOffset(0, 18),
            AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 0, BackgroundColor3 = T("Accent2Soft"),
            TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.None,
        })
        corner(badge, R.Round)
        pad(badge, S.S, 0, S.S, 0)
    end

    -- pagina: bloques de dos columnas + tarjetas anchas
    local page = create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 4,
        ScrollBarImageColor3 = T("Dim"), ScrollBarImageTransparency = 0.3, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = self._pages,
    })
    -- el relleno deja espacio a las sombras de las tarjetas: nunca menos de lo que llega cada sombra
    -- (luz arriba-izquierda, sombra oscura abajo-derecha), asi el ScrollingFrame no las recorta
    local cs = Theme.Shadow.Card
    local lightReach = (cs.LightOffset or cs.Offset) + cs.Blur
    local darkReach = cs.Offset + cs.Blur
    local padLT, padRB = math.max(L.PagePad, lightReach), math.max(L.PagePad, darkReach)
    pad(page, padLT, padLT, padRB, padRB + S.XS)
    list(page, L.Gap)
    page:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        win:_closePopup()
        if win._active == tab then win:_updateFades(M.Fast) end
    end)
    local function refreshFades() if win._active == tab then win:_updateFades(M.Fast) end end
    page:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(refreshFades)
    page:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(refreshFades)
    tab._page, tab._btn = page, btn

    local function colors(t)
        local on, over = tab.Active, tab._hover
        local key = on and "AccentText" or (over and "Text" or "Muted")
        paint(nameLbl, "TextColor3", key, t)
        nameLbl.FontFace = on and F.Semi or F.Medium
        iconApi:Paint(key, t)
        if o.IconTint == false and iconApi.Holder:IsA("ImageLabel") then
            Bound[iconApi.Holder] = nil
            iconApi.Holder.ImageColor3 = WHITE
        end
    end
    function tab:_setActive(on, animate)
        self.Active = on
        colors(animate and M.Base or 0)
    end
    function tab:_setCompact(c)
        nameLbl.Visible = not c
        if badge then badge.Visible = not c end
        iconApi.Holder.AnchorPoint = c and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5)
        iconApi.Holder.Position = c and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, S.M, 0.5, 0)
    end
    tab:_setCompact(self._compact == true)
    btn.MouseEnter:Connect(function() tab._hover = true colors(M.Fast) end)
    btn.MouseLeave:Connect(function() tab._hover = false colors(M.Base) end)
    btn.MouseButton1Click:Connect(function() win:SelectTab(tab) end)
    -- en modo compacto (solo iconos) el tooltip muestra el nombre del tab
    bindTooltip(btn, function() return o.Tooltip or (win._compact and tab.Name) or nil end)
    -- al cambiar de idioma: nombre resuelto + cabecera de la pagina si este tab esta activo
    onLanguage(btn, function()
        tab.Name = tr(tab._nameSrc)
        if win._active == tab then win:_pageHeader(tab) end
    end)

    table.insert(self._tabs, tab)
    if not self._active then self:SelectTab(tab, true) end
    return tab
end

function Window:_pageHeader(tab)
    local win = self
    self._pageTitle.Text = tr(tab._nameSrc or tab.Name)
    if tab.Description ~= nil then
        self._pageDesc.Text = tr(tab.Description)
    else
        self._pageDesc.Text = tr(win._titleSrc or win.Title) .. "  /  " .. tr(tab._nameSrc or tab.Name)
    end
end

function Window:SelectTab(tab, instant)
    if type(tab) == "string" then tab = self:GetTab(tab) end
    if not tab or self._active == tab then return end
    self:_closePopup()
    local prev = self._active
    self._active = tab
    for _, t in ipairs(self._tabs) do t:_setActive(t == tab, not instant) end
    self:_moveIndicator(tab, not instant)
    if prev then
        prev._page.Visible = false
        prev:_filter("")
    end
    if self._searchBox.Text ~= "" then self._searchBox.Text = "" end
    tab._page.Visible = true
    tab._page.CanvasPosition = Vector2.new(0, 0)
    self:_updateFades(0)
    self:_pageHeader(tab)
    if not instant then
        tab._page.Position = UDim2.fromOffset(0, S.S)
        tween(tab._page, { Position = UDim2.fromOffset(0, 0) }, M.Slow)
        self._pageTitle.TextTransparency = 1
        self._pageDesc.TextTransparency = 1
        tween(self._pageTitle, { TextTransparency = 0 }, M.Slow)
        tween(self._pageDesc, { TextTransparency = 0 }, M.Slow)
        tab:_reveal(0)
    end
end

function Window:GetTab(name)
    for _, t in ipairs(self._tabs) do
        if t.Name == name or t._nameSrc == name then return t end
        -- tambien encuentra el tab por su nombre en cualquier idioma
        local src = t._nameSrc
        if type(src) == "table" and src.__s == nil and src.__f == nil then
            for _, s in pairs(src) do if s == name then return t end end
        end
    end
end

function Tab:Select() self.Window:SelectTab(self) end

-- aparicion progresiva: cada tarjeta "sube" (su sombra crece) mientras su velo se desvanece
function Tab:_reveal(delay0)
    if not Kato.Config.Animations then return end
    for i, sec in ipairs(self._sections) do
        local veil = sec._veil
        veil.Visible = true
        veil.BackgroundTransparency = 0
        sec._surface:Set("Flat", 0)
        local token = (sec._revealToken or 0) + 1
        sec._revealToken = token
        task.delay((delay0 or 0) + math.min(i - 1, 8) * 0.04, function()
            if sec._revealToken ~= token then return end
            tween(veil, { BackgroundTransparency = 1 }, M.Slow)
            sec._surface:Set("Card", M.Slow)
            task.delay(M.Slow + 0.02, function() if sec._revealToken == token then veil.Visible = false end end)
        end)
    end
end

function Tab:_setColumns(single)
    for _, b in ipairs(self._blocks) do
        b.layout.FillDirection = single and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
        local size = single and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -L.Gap / 2, 0, 0)
        b.left.Size, b.right.Size = size, size
    end
end

function Tab:_newBlock()
    self._order = self._order + 1
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        LayoutOrder = self._order, Parent = self._page,
    })
    local layout = list(frame, L.Gap, true)
    local function column(order)
        local c = create("Frame", {
            Size = UDim2.new(0.5, -L.Gap / 2, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            LayoutOrder = order, Parent = frame,
        })
        list(c, L.Gap)
        return c
    end
    local b = { frame = frame, layout = layout, left = column(1), right = column(2), cl = 0, cr = 0 }
    table.insert(self._blocks, b)
    self:_setColumns(self.Window._single == true)
    return b
end

function Tab:_filter(q)
    q = string.lower(trim(q))
    local secHit = {}
    for _, s in ipairs(self._sections) do secHit[s] = q ~= "" and string.find(string.lower(tr(s._nameSrc or s.Name) or ""), q, 1, true) ~= nil end
    local anyRow = {}
    for _, it in ipairs(self._items) do
        local show = q == "" or secHit[it.section] or string.find(string.lower(tr(it.src) or ""), q, 1, true) ~= nil
        if it.row.Parent then it.row.Visible = show and not it.hidden end
        if show then anyRow[it.section] = true end
    end
    for _, s in ipairs(self._sections) do
        s._card.Visible = (q == "" or anyRow[s] or secHit[s]) and not s._hidden
    end
end

----------------------------------------------------------------------------------------------------
-- SECCION: tarjeta elevada (nivel 1). Sus filas son el nivel 2. Nunca hay un tercer nivel.
----------------------------------------------------------------------------------------------------
function Tab:CreateSection(o)
    o = opts(o)
    local wide = o.Wide == true or o.Side == "Full" or o.Span == 2
    local parent
    if wide then
        self._block = nil
        self._order = self._order + 1
        parent = self._page
    else
        if not self._block then self._block = self:_newBlock() end
        local b = self._block
        local side = o.Side
        if side == "Right" or side == 2 then
            parent = b.right
        elseif side == "Left" or side == 1 then
            parent = b.left
        else
            parent = (b.cl <= b.cr) and b.left or b.right
        end
        if parent == b.left then b.cl = b.cl + 1 else b.cr = b.cr + 1 end
    end

    local nameSrc = txt(o.Name, "Section")
    local sec = setmetatable({ Window = self.Window, Tab = self, Name = tr(nameSrc), _nameSrc = nameSrc, _n = 10 }, Section)
    local surf = Neu.raised(parent, {
        Size = UDim2.new(1, 0, 0, 0), LayoutOrder = wide and self._order or (#self._sections + 1),
    }, "Card", R.Card, true)
    local card = surf.Face

    local inner = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card,
    })
    pad(inner, S.L, S.L, S.L, S.L)
    list(inner, S.M)

    -- cabecera: icono suelto + titulo + descripcion
    local hasDesc = o.Description ~= nil and o.Description ~= ""
    local head = create("Frame", { Size = UDim2.new(1, 0, 0, hasDesc and 38 or 22), BackgroundTransparency = 1, LayoutOrder = 1, Parent = inner })
    local textX = 0
    if o.Icon then
        local ic = makeIcon(o.Icon, head, L.Icon, "Accent", { Position = UDim2.fromOffset(0, 2) })
        if ic then textX = L.Icon + S.M end
    end
    sec._title = label({
        Parent = head, Text = nameSrc, FontFace = F.Semi, TextSize = TS.Section,
        TextColor3 = T((o.Accent or o.Highlight) and "AccentText" or "Text"),
        Position = UDim2.fromOffset(textX, 0), Size = UDim2.new(1, -textX, 0, 22),
    })
    onLanguage(sec._title, function() sec.Name = tr(sec._nameSrc) end)
    if hasDesc then
        label({
            Parent = head, Text = txt(o.Description, ""), FontFace = F.Regular, TextColor3 = T("Muted"), TextSize = TS.Desc,
            Position = UDim2.fromOffset(textX, 22), Size = UDim2.new(1, -textX, 0, 16),
        })
    end

    -- velo de aparicion
    local veil = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T("Card"), Visible = false, ZIndex = 9, Parent = card })
    corner(veil, R.Card)

    sec._card, sec._surface, sec._inner, sec._veil = surf.Holder, surf, inner, veil
    table.insert(self._sections, sec)
    return sec
end
Tab.AddSection = Tab.CreateSection

function Section:SetTitle(t)
    self._nameSrc = txt(t, "")
    self.Name = tr(self._nameSrc)
    setText(self._title, "Text", self._nameSrc)
end
function Section:SetVisible(v) self._hidden = v == false self._card.Visible = v ~= false end

----------------------------------------------------------------------------------------------------
-- BASE DE ELEMENTOS
----------------------------------------------------------------------------------------------------
function Section:_next()
    self._n = self._n + 1
    return self._n
end

-- fila: "tile" = baldosa elevada (nivel 2), "flat" = directamente sobre la tarjeta
-- devuelve cara (donde va el contenido), contenedor (para layout/visibilidad) y superficie
function Section:_row(h, kind)
    if kind == "flat" then
        local f = create("Frame", {
            Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = self:_next(), Parent = self._inner,
        })
        return f, f, nil
    end
    local surf = Neu.raised(self._inner, { Size = UDim2.new(1, 0, 0, h), LayoutOrder = self:_next() }, "Tile", R.Row)
    return surf.Face, surf.Holder, surf
end

function Section:_lock(on)
    self.Tab._page.ScrollingEnabled = not on
end

function Section:_finish(obj, row, o, searchName, face)
    obj.Instance = row
    local listeners = {}
    obj._emit = function(...)
        safeCall(o.Callback, ...)
        for _, fn in ipairs(listeners) do safeCall(fn, ...) end
    end
    -- la busqueda usa el texto del idioma activo (se resuelve al filtrar)
    local src = searchName
    if src == nil then src = o.Name end
    local item = { src = src or "", row = row, section = self }
    table.insert(self.Tab._items, item)
    function obj:OnChanged(fn) table.insert(listeners, fn) return self end
    function obj:SetVisible(v) item.hidden = v == false row.Visible = v ~= false end
    function obj:Get() return self.Value end
    function obj:Destroy()
        row:Destroy()
        if o.Flag and Kato.Flags[o.Flag] == self then Kato.Flags[o.Flag] = nil end
    end
    -- deshabilitado: un velo del color del fondo atenua la fila y bloquea la entrada
    local blocker
    function obj:SetDisabled(b)
        self.Disabled = b == true
        if self.Disabled and not blocker then
            blocker = create("TextButton", {
                Size = UDim2.fromScale(1, 1), BackgroundColor3 = T("Card"), BackgroundTransparency = 1, ZIndex = 12,
                Parent = face or row,
            })
            corner(blocker, R.Row)
        end
        if blocker then
            if self.Disabled then blocker.Visible = true end
            tween(blocker, { BackgroundTransparency = self.Disabled and 0.4 or 1 }, M.Base)
            if not self.Disabled then task.delay(M.Base, function() if not self.Disabled and blocker then blocker.Visible = false end end) end
        end
    end
    if o.Flag then Kato.Flags[o.Flag] = obj end
    bindTooltip(face or row, o.Tooltip)
    if o.Disabled then obj:SetDisabled(true) end
    return obj
end

-- icono + nombre + descripcion dentro de una fila de alto h
-- rightSpace: pixeles reservados a la derecha, o { escala, pixeles } cuando el control usa ancho relativo
local function rowText(row, o, rightSpace, h)
    local x = S.M
    local rScale, rOffset = 0, rightSpace
    if type(rightSpace) == "table" then rScale, rOffset = rightSpace[1], rightSpace[2] end
    local iconApi
    local desc = o.Description
    if o.Icon then
        iconApi = makeIcon(o.Icon, row, L.Icon, "Muted", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, S.M, 0, desc and 28 or math.floor(h / 2)),
        })
        if iconApi then x = S.M * 2 + L.Icon end
    end
    local name = label({
        Parent = row, Text = txt(o.Name, ""), FontFace = F.Medium, TextSize = TS.Label,
        Position = UDim2.fromOffset(x, desc and 9 or 0), Size = UDim2.new(1 - rScale, -(rOffset + x), 0, desc and 19 or h),
    })
    local d
    if desc then
        d = label({
            Parent = row, Text = txt(desc, ""), FontFace = F.Regular, TextSize = TS.Desc, TextColor3 = T("Muted"),
            Position = UDim2.fromOffset(x, 29), Size = UDim2.new(1 - rScale, -(rOffset + x), 0, 16),
        })
    end
    return name, d, iconApi
end

-- hover de una baldosa: la sombra sube un poco y el icono toma el acento
local function rowHover(surf, trigger, iconApi)
    trigger.MouseEnter:Connect(function()
        if surf then surf:Lift(true, M.Fast) end
        if iconApi then iconApi:Paint("Accent", M.Fast) end
    end)
    trigger.MouseLeave:Connect(function()
        if surf then surf:Lift(false, M.Base) end
        if iconApi then iconApi:Paint("Muted", M.Base) end
    end)
end

-- campo hundido (inputs, dropdowns, color pickers)
local function field(parent, props)
    local f = create("Frame", { Parent = parent })
    for k, v in pairs(props) do f[k] = v end
    corner(f, R.Control)
    local ins = Neu.inset(f, R.Control, false, false, true)
    return f, ins
end

-- barra de foco: linea de acento que crece desde el centro en la base del campo
local function focusBar(parent)
    local b = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = T("Accent"), ZIndex = 3, Parent = parent,
    })
    corner(b, R.Round)
    return function(on)
        tween(b, { Size = on and UDim2.new(1, -R.Control * 2, 0, 2) or UDim2.new(0, 0, 0, 2) }, M.Base)
    end
end

----------------------------------------------------------------------------------------------------
-- LABEL / PARAGRAPH / DIVIDER
----------------------------------------------------------------------------------------------------
function Section:AddLabel(o)
    if type(o) ~= "table" or isTrText(o) then o = { Text = o } end
    local l = label({
        Parent = self._inner, LayoutOrder = self:_next(), Text = txt(o.Text or o.Name, ""),
        TextColor3 = T(o.Color or "Muted"), FontFace = F.Regular, TextSize = o.TextSize or TS.Body, TextWrapped = true,
        RichText = true, TextTruncate = Enum.TextTruncate.None, AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0), LineHeight = 1.15,
    })
    pad(l, S.XS, 0, S.XS, 0)
    local obj = self:_finish({ Type = "Label", Value = l.Text }, l, {}, o.Text)
    function obj:Set(t) setText(l, "Text", txt(t, "")) self.Value = l.Text end
    return obj
end

function Section:AddParagraph(o)
    o = opts(o)
    local box = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        LayoutOrder = self:_next(), Parent = self._inner,
    })
    local x = S.XS
    if o.Icon then
        local ic = makeIcon(o.Icon, box, L.Icon, "Accent", { Position = UDim2.fromOffset(S.XS, 0) })
        if ic then x = S.XS + L.Icon + S.M end
    end
    local inner = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = box })
    pad(inner, x, 0, S.XS, S.XS)
    list(inner, S.XS)
    local title = label({
        Parent = inner, LayoutOrder = 1, Text = txt(o.Title or o.Name, ""), FontFace = F.Semi, TextSize = TS.Label,
        Size = UDim2.new(1, 0, 0, 18),
    })
    local body = label({
        Parent = inner, LayoutOrder = 2, Text = txt(o.Content, ""), TextColor3 = T("Muted"), FontFace = F.Regular,
        TextSize = TS.Body, TextWrapped = true, RichText = true, TextTruncate = Enum.TextTruncate.None, LineHeight = 1.15,
        AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
    })
    local pTitle, pContent = o.Title or o.Name, o.Content
    local obj = self:_finish({ Type = "Paragraph" }, box, {}, TF(function()
        return (tr(pTitle) or "") .. " " .. (tr(pContent) or "")
    end))
    function obj:Set(t, c)
        if type(t) == "table" and not isTrText(t) then t, c = t.Title, t.Content end
        if t then pTitle = txt(t) setText(title, "Text", pTitle) end
        if c then pContent = txt(c) setText(body, "Text", pContent) end
    end
    obj.SetTitle = function(_, t) pTitle = txt(t, "") setText(title, "Text", pTitle) end
    obj.SetContent = function(_, c) pContent = txt(c, "") setText(body, "Text", pContent) end
    return obj
end

function Section:AddDivider(text)
    local f = create("Frame", {
        Size = UDim2.new(1, 0, 0, text and 24 or S.M), BackgroundTransparency = 1, LayoutOrder = self:_next(), Parent = self._inner,
    })
    local line = groove(f, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, text and 2 or 0) })
    if text then
        local l = label({
            Parent = f, Text = TF(function() return string.upper(tr(text)) end), FontFace = F.Semi, TextSize = TS.Caption, TextColor3 = T("Caption"),
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, S.XS, 0.5, 2), Size = UDim2.fromOffset(0, 14),
            AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None,
        })
        -- la linea empieza despues del texto
        local function sync()
            local sc = math.max(self.Window._uiScale.Scale, 0.01)
            local w = l.AbsoluteSize.X / sc + S.XS + S.M
            line.Position = UDim2.new(0, w, 0.5, 2)
            line.Size = UDim2.new(1, -w, 0, 2)
        end
        l:GetPropertyChangedSignal("AbsoluteSize"):Connect(sync)
        task.defer(sync)
    end
    return { Instance = f, Destroy = function() f:Destroy() end, SetVisible = function(_, v) f.Visible = v ~= false end }
end

----------------------------------------------------------------------------------------------------
-- BUTTON: Default (elevado neutro) / Primary (morado solido) / Danger (rosa palido + rojo)
-- hover = la sombra sube, presionado = se hunde, deshabilitado = velo
----------------------------------------------------------------------------------------------------
function Section:AddButton(o)
    o = opts(o)
    local style = o.Style or (o.Primary and "Primary") or "Default"
    local primary, danger = style == "Primary", style == "Danger"
    local h = o.Description and L.RowDesc or L.Row
    local row, holder, surf = self:_row(h)
    if primary then paint(row, "BackgroundColor3", "AccentStrong") end
    if danger then paint(row, "BackgroundColor3", "DangerSoft") end if not primary then edge(row, danger and "Error" or "Edge") end
    local btn = hitbox(row)
    local name, desc, iconApi = rowText(row, o, S.XXXL, h)
    local textKey = primary and "OnAccent" or (danger and "DangerText" or "Text")
    local iconKey = primary and "OnAccent" or (danger and "DangerText" or "Muted")
    paint(name, "TextColor3", textKey)
    name.FontFace = F.Semi
    if desc then
        paint(desc, "TextColor3", primary and "OnAccent" or (danger and "DangerText" or "Muted"))
        if primary or danger then desc.TextTransparency = 0.25 end
    end
    if iconApi then iconApi:Paint(iconKey) end
    local chev = makeIcon("chevron", row, 12, iconKey, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -S.M - 2, 0.5, 0) })

    pressable(surf, btn, primary and "Primary" or "Default", function(over, _, t)
        tween(chev.Holder, { Position = UDim2.new(1, over and -S.M or -S.M - 2, 0.5, 0) }, t)
        if style == "Default" then
            chev:Paint(over and "Accent" or "Muted", t)
            if iconApi then iconApi:Paint(over and "Accent" or "Muted", t) end
        end
    end)

    local obj = { Type = "Button", Name = o.Name }
    local armed, armToken = false, 0
    local original = txt(o.Name, "")
    local function disarm()
        armed = false
        setText(name, "Text", original)
        paint(name, "TextColor3", textKey, M.Base)
    end
    btn.MouseButton1Click:Connect(function()
        if obj.Disabled then return end
        if o.Confirm and not armed then
            armed = true
            armToken = armToken + 1
            local my = armToken
            setText(name, "Text", SK("Confirm"))
            paint(name, "TextColor3", primary and "OnAccent" or "Warning", M.Fast)
            task.delay(2.5, function() if my == armToken and armed then disarm() end end)
            return
        end
        if armed then disarm() end
        obj._emit()
    end)
    self:_finish(obj, holder, o, nil, row)
    function obj:Fire() self._emit() end
    function obj:SetText(t) original = txt(t, "") setText(name, "Text", original) end
    obj.Set = obj.SetText
    return obj
end

----------------------------------------------------------------------------------------------------
-- TOGGLE: riel hundido, se llena de morado al activarse; knob blanco elevado que se desliza
----------------------------------------------------------------------------------------------------
function Section:AddToggle(o)
    o = opts(o)
    local h = o.Description and L.RowDesc or L.Row
    local row, holder, surf = self:_row(h)
    local btn = hitbox(row, 2)
    local _, _, iconApi = rowText(row, o, L.Toggle.X + S.M * 2, h)
    rowHover(surf, btn, nil)

    local track = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -S.M, 0.5, 0), Size = UDim2.fromOffset(L.Toggle.X, L.Toggle.Y), Parent = row,
    })
    corner(track, R.Round)
    local trackInset = Neu.inset(track, R.Round, false, false, true, "Track")
    local fill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T("Accent"), BackgroundTransparency = 1, Parent = track })
    corner(fill, R.Round)
    local gap = (L.Toggle.Y - L.Knob) / 2
    local knob = Neu.raised(track, {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, gap, 0.5, 0), Size = UDim2.fromOffset(L.Knob, L.Knob), ZIndex = 2,
    }, "Knob", R.Round)
    paint(knob.Face, "BackgroundColor3", "Knob")

    local obj = { Type = "Toggle", Name = o.Name, Value = o.Default == true or o.Value == true }
    local function render(animate)
        local t = animate and M.Base or 0
        local on = obj.Value
        tween(fill, { BackgroundTransparency = on and 0 or 1 }, t)
        tween(knob.Holder, { Position = on and UDim2.new(1, -(L.Knob + gap), 0.5, 0) or UDim2.new(0, gap, 0.5, 0) }, t)
        if trackInset.Edge then tween(trackInset.Edge, { Transparency = on and 1 or 0 }, t) end if iconApi then iconApi:Paint(on and "Accent" or "Muted", t) end
    end
    render(false)
    btn.MouseButton1Click:Connect(function() if not obj.Disabled then obj:Set(not obj.Value) end end)
    self:_finish(obj, holder, o, nil, row)
    function obj:Set(v, silent)
        self.Value = v == true
        render(true)
        if not silent then self._emit(self.Value) end
    end
    function obj:Toggle() self:Set(not self.Value) end
    if o.CallOnStart and obj.Value then obj._emit(true) end
    return obj
end

----------------------------------------------------------------------------------------------------
-- SLIDER: plano sobre la tarjeta. Riel hundido, relleno morado, knob blanco elevado, valor a la derecha
----------------------------------------------------------------------------------------------------
function Section:AddSlider(o)
    o = opts(o)
    local min, max = tonumber(o.Min) or 0, tonumber(o.Max) or 100
    if max <= min then max = min + 1 end
    local inc = tonumber(o.Increment or o.Rounding) or 1
    local suffix = o.Suffix or ""
    local dec = 0
    do
        local d = tostring(inc):match("%.(%d+)$")
        dec = d and #d or 0
    end
    local function fmt(v)
        if dec > 0 then return string.format("%." .. dec .. "f", v) end
        return tostring(math.floor(v + 0.5))
    end
    local function snap(v)
        v = math.clamp(v, min, max)
        v = min + math.floor((v - min) / inc + 0.5) * inc
        return tonumber(fmt(math.clamp(v, min, max)))
    end

    local hasDesc = o.Description ~= nil
    local headH = 38
    local h = hasDesc and 68 or 56
    local row, holder = self:_row(h, "flat")
    local _, _, iconApi = rowText(row, { Name = o.Name, Description = o.Description, Icon = o.Icon }, 88, headH)
    rowHover(nil, row, iconApi)

    -- valor: texto plano que se vuelve un campo hundido al editarlo
    local vf = create("Frame", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -S.XS, 0, hasDesc and 6 or 6), Size = UDim2.fromOffset(72, 26),
        BackgroundColor3 = T("Inset"), BackgroundTransparency = 1, Parent = row,
    })
    corner(vf, R.Small)
    local vfInset = Neu.inset(vf, R.Small, true, true)
    local box = create("TextBox", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, FontFace = F.Semi, TextSize = TS.Label, TextColor3 = T("Text"),
        TextXAlignment = Enum.TextXAlignment.Right, ClearTextOnFocus = false, ZIndex = 2, Parent = vf,
    })
    local boxPad = pad(box, S.S, 0, S.S, 0)

    local track = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, S.M, 1, -S.M), Size = UDim2.new(1, -S.M * 2, 0, L.Track), Parent = row,
    })
    corner(track, R.Round)
    Neu.inset(track, R.Round, false, false, true, "Track")
    local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = T("Accent"), Parent = track })
    corner(fill, R.Round)
    local knob = Neu.raised(track, {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(L.Knob, L.Knob), ZIndex = 2,
    }, "Knob", R.Round)
    paint(knob.Face, "BackgroundColor3", "Knob")
    local core = create("Frame", centered({ Size = UDim2.fromOffset(6, 6), BackgroundColor3 = T("Accent"), Parent = knob.Face }))
    corner(core, R.Round)
    local hit = create("TextButton", {
        Position = UDim2.new(0, S.XS, 1, -S.M - 14), Size = UDim2.new(1, -S.S, 0, 28), BackgroundTransparency = 1, ZIndex = 3, Parent = row,
    })

    local obj = { Type = "Slider", Name = o.Name, Min = min, Max = max }
    obj.Value = snap(tonumber(o.Default or o.Value) or min)
    local function render(t)
        local pct = (obj.Value - min) / (max - min)
        tween(fill, { Size = UDim2.fromScale(pct, 1) }, t or 0)
        tween(knob.Holder, { Position = UDim2.fromScale(pct, 0.5) }, t or 0)
        if not box:IsFocused() then box.Text = fmt(obj.Value) .. suffix end
    end
    render(0)

    local function setFromX(x)
        local pct = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local v = snap(min + pct * (max - min))
        if v ~= obj.Value then
            obj.Value = v
            render(0.06)
            obj._emit(v)
        end
    end
    onDrag(hit, function(i)
        if obj.Disabled then return false end
        self:_lock(true)
        knob:Set("KnobLift", M.Fast)
        setFromX(i.Position.X)
    end, function(i)
        setFromX(i.Position.X)
    end, function()
        self:_lock(false)
        knob:Set("Knob", M.Base)
    end)
    box.Focused:Connect(function()
        box.Text = fmt(obj.Value)
        box.TextXAlignment = Enum.TextXAlignment.Center
        tween(vf, { BackgroundTransparency = 0 }, M.Fast)
        vfInset:Show(true, M.Fast)
    end)
    box.FocusLost:Connect(function()
        box.TextXAlignment = Enum.TextXAlignment.Right
        tween(vf, { BackgroundTransparency = 1 }, M.Base)
        vfInset:Show(false, M.Base)
        local n = tonumber((box.Text:gsub("[^%d%.%-]", "")))
        if n and not obj.Disabled then obj:Set(n) else render(0) end
    end)
    local _ = boxPad

    self:_finish(obj, holder, o)
    function obj:Set(v, silent)
        v = tonumber(v)
        if not v then return end
        self.Value = snap(v)
        render(M.Base)
        if not silent then self._emit(self.Value) end
    end
    function obj:SetRange(a, b)
        min, max = tonumber(a) or min, tonumber(b) or max
        if max <= min then max = min + 1 end
        self.Min, self.Max = min, max
        self:Set(self.Value, true)
    end
    return obj
end

----------------------------------------------------------------------------------------------------
-- DROPDOWN: campo hundido + menu flotante elevado (simple o multiple, con buscador)
----------------------------------------------------------------------------------------------------
function Section:AddDropdown(o)
    o = opts(o)
    local multi = o.Multi == true
    local win = self.Window
    local h = o.Description and L.RowDesc or L.Row
    local row, holder, surf = self:_row(h)
    local _, _, iconApi = rowText(row, o, { 0.46, S.L }, h)
    rowHover(surf, row, iconApi)
    local pill = field(row, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -S.M + 4, 0.5, 0), Size = UDim2.new(0.46, 0, 0, L.Control),
    })
    create("UISizeConstraint", { MinSize = Vector2.new(96, L.Control), MaxSize = Vector2.new(200, L.Control), Parent = pill })
    local valueLbl = label({
        Parent = pill, Position = UDim2.fromOffset(S.M, 0), Size = UDim2.new(1, -(S.M + 28), 1, 0), TextSize = TS.Body,
    })
    local chev = makeIcon("chevron", pill, 10, "Muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -S.L, 0.5, 0), Rotation = 90 })
    local pillBtn = hitbox(pill, 3)
    local isOpen = false

    local obj = { Type = "Dropdown", Name = o.Name, Multi = multi, Options = {} }
    local optButtons, popup = {}, nil

    local function isSel(v)
        if multi then return table.find(obj.Value, v) ~= nil end
        return obj.Value == v
    end
    -- o.Labels = { valor = "texto" | { es = ..., en = ... } }: texto a mostrar por opcion (el valor no cambia)
    local function optText(v)
        local lb = nil
        if type(o.Labels) == "table" then lb = o.Labels[v] end
        if lb ~= nil then return tr(lb) end
        return tostring(v)
    end
    local function display()
        if multi then
            local n = #obj.Value
            if n == 0 then valueLbl.Text = Kato.Strings.None
            elseif n <= 2 then
                local parts = {}
                for i2, v2 in ipairs(obj.Value) do parts[i2] = optText(v2) end
                valueLbl.Text = table.concat(parts, ", ")
            else valueLbl.Text = optText(obj.Value[1]) .. "  +" .. (n - 1) end
        else
            valueLbl.Text = obj.Value ~= nil and optText(obj.Value) or Kato.Strings.None
        end
        paint(valueLbl, "TextColor3", (multi and #obj.Value > 0 or (not multi and obj.Value ~= nil)) and "Text" or "Muted")
    end
    local function paintOpt(b, animate)
        local t = animate and M.Fast or 0
        local sel = isSel(b.value)
        b.sel = sel
        paint(b.btn, "BackgroundColor3", sel and "AccentSoft" or "Inset", t)
        tween(b.btn, { BackgroundTransparency = sel and 0 or 1 }, t)
        paint(b.txt, "TextColor3", sel and "AccentText" or "Text", t)
        b.txt.FontFace = sel and F.Semi or F.Medium
        tween(b.markScale, { Scale = sel and 1 or 0 }, t)
    end
    local function renderAll(animate)
        for _, b in ipairs(optButtons) do paintOpt(b, animate) end
        display()
    end

    local function setOpen(state)
        isOpen = state
        tween(chev.Holder, { Rotation = state and -90 or 90 }, M.Base)
        chev:Paint(state and "Accent" or "Muted", M.Base)
    end

    local OPT_H = L.Control
    local function openMenu()
        if obj.Disabled then return end
        local count = #obj.Options
        local useSearch = o.Search == true or (o.Search ~= false and count >= Kato.Config.Dropdown.SearchAt)
        local vis = math.min(math.max(count, 1), o.MaxVisible or Kato.Config.Dropdown.MaxVisible)
        local ph = (useSearch and (L.Control + S.S) or 0) + vis * (OPT_H + S.XS) - S.XS + S.S * 2
        local sc = win._root.AbsoluteSize.X / math.max(win.W, 1)
        local pw = math.max(pill.AbsoluteSize.X / math.max(sc, 0.01), 200)
        setOpen(true)
        popup = win:_popup(pill, pw, ph, function(panel)
            optButtons = {}
            local searchBox
            if useSearch then
                local sf = field(panel, { Position = UDim2.fromOffset(S.S, S.S), Size = UDim2.new(1, -S.L, 0, L.Control) })
                makeIcon("search", sf, 12, "Muted", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, S.M, 0.5, 0) })
                searchBox = create("TextBox", {
                    Position = UDim2.fromOffset(S.M + 12 + S.S, 0), Size = UDim2.new(1, -(S.M * 2 + 12 + S.S), 1, 0), BackgroundTransparency = 1,
                    PlaceholderText = SK("Search"), PlaceholderColor3 = T("Muted"), TextColor3 = T("Text"), TextSize = TS.Body,
                    TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 2, Parent = sf,
                })
            end
            local top = useSearch and (S.S + L.Control + S.S) or S.S
            local scroll = create("ScrollingFrame", {
                Position = UDim2.fromOffset(S.S, top), Size = UDim2.new(1, -S.L, 1, -(top + S.S)),
                BackgroundTransparency = 1, ScrollBarThickness = 3, ScrollBarImageColor3 = T("Dim"),
                CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
                Parent = panel,
            })
            list(scroll, S.XS)
            local empty = label({
                Parent = panel, Text = SK("NoResults"), TextColor3 = T("Muted"), TextSize = TS.Desc, Visible = count == 0,
                TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, useSearch and 20 or 0), Size = UDim2.new(1, 0, 0, 20),
            })
            for i, v in ipairs(obj.Options) do
                local b = { value = v }
                b.btn = create("TextButton", {
                    Size = UDim2.new(1, -S.XS, 0, OPT_H), BackgroundColor3 = T("Inset"), BackgroundTransparency = 1,
                    LayoutOrder = i, Parent = scroll,
                })
                corner(b.btn, R.Control)
                b.txt = label({
                    Parent = b.btn, Text = optText(v), TextSize = TS.Body, Position = UDim2.fromOffset(S.M, 0), Size = UDim2.new(1, -(S.M + 32), 1, 0),
                })
                local mark = create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -S.M, 0.5, 0), Size = UDim2.fromOffset(12, 12),
                    BackgroundTransparency = 1, Parent = b.btn,
                })
                b.markScale = create("UIScale", { Scale = 0, Parent = mark })
                makeIcon("check", mark, 12, "Accent", centered())
                b.btn.MouseEnter:Connect(function() if not b.sel then tween(b.btn, { BackgroundTransparency = 0.4 }, M.Fast) end end)
                b.btn.MouseLeave:Connect(function() if not b.sel then tween(b.btn, { BackgroundTransparency = 1 }, M.Base) end end)
                b.btn.MouseButton1Click:Connect(function()
                    if multi then
                        local idx = table.find(obj.Value, v)
                        if idx then table.remove(obj.Value, idx) else table.insert(obj.Value, v) end
                        renderAll(true)
                        obj._emit(table.clone(obj.Value))
                    else
                        if obj.Value == v and o.AllowNone then obj.Value = nil else obj.Value = v end
                        renderAll(true)
                        obj._emit(obj.Value)
                        if popup then popup.Close() end
                    end
                end)
                table.insert(optButtons, b)
            end
            if searchBox then
                searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local q = string.lower(searchBox.Text)
                    local shown = 0
                    for _, b in ipairs(optButtons) do
                        local ok = q == "" or string.find(string.lower(optText(b.value)), q, 1, true) ~= nil
                        b.btn.Visible = ok
                        if ok then shown = shown + 1 end
                    end
                    empty.Visible = shown == 0
                end)
                if not UserInputService.TouchEnabled then task.defer(function() pcall(function() searchBox:CaptureFocus() end) end) end
            end
            renderAll(false)
            -- desplazar hasta el seleccionado
            if not multi and obj.Value ~= nil then
                local idx = table.find(obj.Options, obj.Value)
                if idx then scroll.CanvasPosition = Vector2.new(0, math.max(0, (idx - 2) * (OPT_H + S.XS))) end
            end
        end, function()
            optButtons = {}
            popup = nil
            setOpen(false)
        end)
    end
    pillBtn.MouseButton1Click:Connect(function()
        if popup then popup.Close() else openMenu() end
    end)

    -- valores iniciales
    for _, v in ipairs(o.Options or o.Values or {}) do table.insert(obj.Options, v) end
    if multi then
        obj.Value = {}
        local d = o.Default
        if type(d) == "table" then
            for _, v in ipairs(d) do if table.find(obj.Options, v) then table.insert(obj.Value, v) end end
        elseif d ~= nil and table.find(obj.Options, d) then
            table.insert(obj.Value, d)
        end
    else
        local d = o.Default
        if type(d) == "number" and not table.find(obj.Options, d) then d = obj.Options[d] end
        obj.Value = (d ~= nil and table.find(obj.Options, d)) and d or nil
    end
    display()
    -- al cambiar de idioma se cierra el menu y se re-escribe el valor ("Ninguno", etiquetas traducidas)
    onLanguage(valueLbl, function()
        if popup then popup.Close() end
        display()
    end)

    self:_finish(obj, holder, o, nil, row)
    -- cambia las etiquetas visibles de las opciones: { valor = "texto" | { es = ..., en = ... } }
    function obj:SetLabels(map)
        o.Labels = map
        if popup then popup.Close() end
        display()
    end
    function obj:Set(v, silent)
        if multi then
            self.Value = {}
            if type(v) == "table" then
                for _, x in ipairs(v) do if table.find(self.Options, x) then table.insert(self.Value, x) end end
            elseif v ~= nil and table.find(self.Options, v) then
                table.insert(self.Value, v)
            end
        else
            self.Value = (v ~= nil and table.find(self.Options, v)) and v or nil
        end
        renderAll(true)
        if not silent then self._emit(multi and table.clone(self.Value) or self.Value) end
    end
    function obj:Get() return multi and table.clone(self.Value) or self.Value end
    function obj:Refresh(newOptions, keep)
        if popup then popup.Close() end
        self.Options = {}
        for _, v in ipairs(newOptions or {}) do table.insert(self.Options, v) end
        if multi then
            local kept = {}
            if keep then for _, x in ipairs(self.Value) do if table.find(self.Options, x) then table.insert(kept, x) end end end
            self.Value = kept
        elseif not (keep and self.Value ~= nil and table.find(self.Options, self.Value)) then
            self.Value = nil
        end
        display()
    end
    obj.SetOptions = obj.Refresh
    function obj:Add(v) table.insert(self.Options, v) self:Refresh(self.Options, true) end
    function obj:Remove(v)
        local i = table.find(self.Options, v)
        if i then table.remove(self.Options, i) end
        self:Refresh(self.Options, true)
    end
    function obj:Close() if popup then popup.Close() end end
    local _ = isOpen
    return obj
end

----------------------------------------------------------------------------------------------------
-- INPUT (TextBox): campo hundido con barra de foco de acento
----------------------------------------------------------------------------------------------------
function Section:AddInput(o)
    o = opts(o)
    local h = o.Description and L.RowDesc or L.Row
    local row, holder, surf = self:_row(h)
    local _, _, iconApi = rowText(row, o, { 0.46, S.L }, h)
    rowHover(surf, row, iconApi)
    local f = field(row, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -S.M + 4, 0.5, 0), Size = UDim2.new(0.46, 0, 0, L.Control),
    })
    create("UISizeConstraint", { MinSize = Vector2.new(96, L.Control), MaxSize = Vector2.new(220, L.Control), Parent = f })
    local box = create("TextBox", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, PlaceholderText = txt(o.Placeholder, "..."),
        PlaceholderColor3 = T("Muted"), TextColor3 = T("Text"), TextSize = TS.Body, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = o.ClearOnFocus == true, Text = tostring(o.Default or ""), TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2, Parent = f,
    })
    pad(box, S.M, 0, S.M, 0)
    local setFocus = focusBar(f)
    local obj = { Type = "Input", Name = o.Name, Value = box.Text }
    local function commit()
        local t = box.Text
        if o.Numeric then
            local n = tonumber(t)
            if not n and t ~= "" then box.Text = tostring(obj.Value) return end
        end
        if o.MaxLength and #t > o.MaxLength then t = t:sub(1, o.MaxLength) box.Text = t end
        if t ~= obj.Value then
            obj.Value = t
            obj._emit(o.Numeric and tonumber(t) or t)
        end
    end
    box.Focused:Connect(function()
        if obj.Disabled then box:ReleaseFocus() return end
        setFocus(true)
        if iconApi then iconApi:Paint("Accent", M.Fast) end
    end)
    box.FocusLost:Connect(function(enter)
        setFocus(false)
        if iconApi then iconApi:Paint("Muted", M.Base) end
        commit()
        if enter and o.ClearOnEnter then box.Text = "" end
    end)
    if o.Finished == false then box:GetPropertyChangedSignal("Text"):Connect(commit) end
    self:_finish(obj, holder, o, nil, row)
    function obj:Set(v, silent)
        box.Text = tostring(v or "")
        self.Value = box.Text
        if not silent then self._emit(o.Numeric and tonumber(self.Value) or self.Value) end
    end
    obj.SetPlaceholder = function(_, t) setText(box, "PlaceholderText", txt(t, "")) end
    return obj
end
Section.AddTextbox = Section.AddInput
Section.AddTextBox = Section.AddInput

----------------------------------------------------------------------------------------------------
-- KEYBIND: tecla elevada; al escuchar se hunde y el texto toma el acento
----------------------------------------------------------------------------------------------------
function Section:AddKeybind(o)
    o = opts(o)
    local h = o.Description and L.RowDesc or L.Row
    local row, holder, surf = self:_row(h)
    local _, _, iconApi = rowText(row, o, 130, h)
    rowHover(surf, row, iconApi)
    local cs = Neu.raised(row, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -S.M, 0.5, 0), Size = UDim2.fromOffset(0, 28),
    }, "Control", R.Small, "X")
    edge(cs.Face)
    create("UISizeConstraint", { MinSize = Vector2.new(48, 28), Parent = cs.Face })
    local keyLbl = label({
        Parent = cs.Face, FontFace = F.Semi, TextSize = TS.Desc, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.None,
    })
    pad(keyLbl, S.M, 0, S.M, 0)
    local chip = hitbox(cs.Face)

    local obj = { Type = "Keybind", Name = o.Name, Value = toKey(o.Default or o.Value), Mode = o.Mode or "Press", State = false }
    local listening = false
    keyLbl.Text = keyName(obj.Value)
    onLanguage(keyLbl, function()
        keyLbl.Text = listening and Kato.Strings.Listening or keyName(obj.Value)
    end)

    local function stopListening()
        listening = false
        Kato._binding = false
        cs:Press(false, M.Base)
        paint(keyLbl, "TextColor3", "Text", M.Base)
        keyLbl.Text = keyName(obj.Value)
    end
    chip.MouseEnter:Connect(function() if not listening then cs:Lift(true, M.Fast) end end)
    chip.MouseLeave:Connect(function() if not listening then cs:Lift(false, M.Base) end end)
    chip.MouseButton1Click:Connect(function()
        if listening or obj.Disabled then return end
        task.defer(function()
            listening = true
            Kato._binding = true
            keyLbl.Text = Kato.Strings.Listening
            cs:Press(true, M.Fast)
            paint(keyLbl, "TextColor3", "AccentText", M.Fast)
        end)
    end)

    conn(UserInputService.InputBegan:Connect(function(input, gp)
        if listening then
            local t = input.UserInputType
            if t == Enum.UserInputType.Keyboard then
                local k = input.KeyCode
                if k == Enum.KeyCode.Escape then
                    stopListening()
                elseif k == Enum.KeyCode.Backspace or k == Enum.KeyCode.Delete then
                    obj:Set(nil)
                    stopListening()
                else
                    obj:Set(k)
                    stopListening()
                end
            elseif t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.MouseButton3 then
                obj:Set(t)
                stopListening()
            elseif t == Enum.UserInputType.MouseButton1 then
                stopListening()
            end
            return
        end
        if obj.Value == nil or obj.Disabled or UserInputService:GetFocusedTextBox() then return end
        if gp and input.UserInputType == Enum.UserInputType.Keyboard and o.IgnoreGameProcessed ~= true then return end
        if input.KeyCode == obj.Value or input.UserInputType == obj.Value then
            -- la tecla se hunde un instante al usarla
            cs:Press(true, 0.06)
            task.delay(0.14, function() if not listening then cs:Press(false, M.Base) end end)
            if obj.Mode == "Hold" then
                obj.State = true
                obj._emit(true)
            elseif obj.Mode == "Toggle" then
                obj.State = not obj.State
                obj._emit(obj.State)
            else
                obj._emit()
            end
        end
    end))
    conn(UserInputService.InputEnded:Connect(function(input)
        if obj.Mode ~= "Hold" or obj.Value == nil or not obj.State then return end
        if input.KeyCode == obj.Value or input.UserInputType == obj.Value then
            obj.State = false
            obj._emit(false)
        end
    end))

    self:_finish(obj, holder, o, nil, row)
    function obj:Set(k)
        self.Value = toKey(k)
        keyLbl.Text = keyName(self.Value)
        safeCall(o.ChangedCallback, self.Value)
    end
    function obj:SetMode(m) self.Mode = m end
    return obj
end

----------------------------------------------------------------------------------------------------
-- COLOR PICKER (popup HSV con vista previa y hex)
----------------------------------------------------------------------------------------------------
function Section:AddColorPicker(o)
    o = opts(o)
    local win = self.Window
    local h = o.Description and L.RowDesc or L.Row
    local row, holder, surf = self:_row(h)
    local _, _, iconApi = rowText(row, o, 140, h)
    rowHover(surf, row, iconApi)
    local pill = field(row, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -S.M + 4, 0.5, 0), Size = UDim2.fromOffset(112, L.Control),
    })
    local swatch = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, S.S, 0.5, 0), Size = UDim2.fromOffset(18, 18), Parent = pill,
    })
    corner(swatch, R.Round)
    local hexLbl = label({
        Parent = pill, Position = UDim2.fromOffset(S.S + 18 + S.S, 0), Size = UDim2.new(1, -(S.S * 3 + 18), 1, 0),
        TextSize = TS.Desc, TextColor3 = T("Text"),
    })
    local pillBtn = hitbox(pill, 3)

    local start = o.Default or o.Value or Color.Accent
    if type(start) == "string" then start = fromHex(start) or Color.Accent end
    local H, Sat, V = start:ToHSV()
    local obj = { Type = "ColorPicker", Name = o.Name, Value = start }
    local ui -- partes del popup abierto

    local function render()
        obj.Value = Color3.fromHSV(H, Sat, V)
        swatch.BackgroundColor3 = obj.Value
        hexLbl.Text = toHex(obj.Value)
        if ui then
            ui.sv.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
            ui.svCursor.Position = UDim2.fromScale(Sat, 1 - V)
            ui.svCursor.BackgroundColor3 = obj.Value
            ui.hueCursor.Position = UDim2.fromScale(H, 0.5)
            ui.preview.BackgroundColor3 = obj.Value
            if not ui.hex:IsFocused() then ui.hex.Text = toHex(obj.Value) end
        end
    end
    render()

    local function openPicker()
        if obj.Disabled then return end
        local PW, PH = 248, 236
        win:_popup(pill, PW, PH, function(panel)
            local sv = create("Frame", { Position = UDim2.fromOffset(S.M, S.M), Size = UDim2.new(1, -S.XXL, 0, 132), Parent = panel })
            corner(sv, R.Control)
            local white = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, Parent = sv })
            corner(white, R.Control)
            create("UIGradient", { Transparency = nseq({ { 0, 0 }, { 1, 1 } }), Parent = white })
            local black = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, Parent = sv })
            corner(black, R.Control)
            create("UIGradient", { Rotation = 90, Transparency = nseq({ { 0, 1 }, { 1, 0 } }), Parent = black })
            local svCursor = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14), ZIndex = 3, Parent = sv })
            corner(svCursor, R.Round)
            create("UIStroke", { Color = WHITE, Thickness = 2, Parent = svCursor })
            local svHit = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4, Parent = sv })

            local hue = create("Frame", { Position = UDim2.fromOffset(S.M, 132 + S.M * 2), Size = UDim2.new(1, -S.XXL, 0, 10), BackgroundColor3 = WHITE, Parent = panel })
            corner(hue, R.Round)
            do
                local kps = {}
                for i = 0, 6 do table.insert(kps, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i == 6 and 0.999 or i / 6, 1, 1))) end
                create("UIGradient", { Color = ColorSequence.new(kps), Parent = hue })
            end
            local hueKnob = Neu.raised(hue, {
                AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(L.Knob, L.Knob), ZIndex = 3,
            }, "Knob", R.Round)
            paint(hueKnob.Face, "BackgroundColor3", "Knob")
            local hueHit = create("TextButton", {
                Position = UDim2.fromOffset(0, -S.S), Size = UDim2.new(1, 0, 1, S.L), BackgroundTransparency = 1, ZIndex = 4, Parent = hue,
            })

            local rowY = 132 + S.M * 2 + 10 + S.L
            local preview = create("Frame", { Position = UDim2.fromOffset(S.M, rowY), Size = UDim2.fromOffset(40, 40), Parent = panel })
            corner(preview, R.Control)
            local hf = field(panel, { Position = UDim2.fromOffset(S.M + 40 + S.S, rowY), Size = UDim2.new(1, -(S.M * 2 + 40 + S.S), 0, 40) })
            local hex = create("TextBox", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextColor3 = T("Text"), FontFace = F.Semi, TextSize = TS.Body,
                ClearTextOnFocus = false, ZIndex = 2, Parent = hf,
            })
            local setFocus = focusBar(hf)
            hex.Focused:Connect(function() setFocus(true) end)
            hex.FocusLost:Connect(function()
                setFocus(false)
                local c = fromHex(hex.Text)
                if c then obj:Set(c) else hex.Text = toHex(obj.Value) end
            end)
            ui = { sv = sv, svCursor = svCursor, hueCursor = hueKnob.Holder, preview = preview, hex = hex }
            render()

            local function svFrom(i)
                local ap, as = sv.AbsolutePosition, sv.AbsoluteSize
                Sat = math.clamp((i.Position.X - ap.X) / math.max(as.X, 1), 0, 1)
                V = 1 - math.clamp((i.Position.Y - ap.Y) / math.max(as.Y, 1), 0, 1)
                render()
                obj._emit(obj.Value)
            end
            local function hueFrom(i)
                local ap, as = hue.AbsolutePosition, hue.AbsoluteSize
                H = math.clamp((i.Position.X - ap.X) / math.max(as.X, 1), 0, 0.999)
                render()
                obj._emit(obj.Value)
            end
            onDrag(svHit, function(i) tween(svCursor, { Size = UDim2.fromOffset(18, 18) }, M.Fast) svFrom(i) end, svFrom,
                function() tween(svCursor, { Size = UDim2.fromOffset(14, 14) }, M.Base) end)
            onDrag(hueHit, function(i) hueKnob:Set("KnobLift", M.Fast) hueFrom(i) end, hueFrom,
                function() hueKnob:Set("Knob", M.Base) end)
        end, function()
            ui = nil
            if iconApi then iconApi:Paint("Muted", M.Base) end
        end)
        if iconApi then iconApi:Paint("Accent", M.Fast) end
    end
    pillBtn.MouseButton1Click:Connect(openPicker)

    self:_finish(obj, holder, o, nil, row)
    function obj:Set(c, silent)
        if type(c) == "string" then c = fromHex(c) end
        if typeof(c) ~= "Color3" then return end
        H, Sat, V = c:ToHSV()
        render()
        if not silent then self._emit(self.Value) end
    end
    return obj
end

----------------------------------------------------------------------------------------------------
-- PROGRESS: plano, riel hundido con relleno morado y porcentaje a la derecha
----------------------------------------------------------------------------------------------------
function Section:AddProgress(o)
    o = opts(o)
    local max = tonumber(o.Max) or 100
    local h = o.Description and 64 or 52
    local row, holder = self:_row(h, "flat")
    rowText(row, { Name = o.Name, Description = o.Description, Icon = o.Icon }, 80, 38)
    local pct = label({
        Parent = row, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -S.M, 0, 0), Size = UDim2.fromOffset(80, 38),
        TextXAlignment = Enum.TextXAlignment.Right, FontFace = F.Semi, TextSize = TS.Label,
    })
    local track = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, S.M, 1, -S.M + 2), Size = UDim2.new(1, -S.M * 2, 0, 8), Parent = row,
    })
    corner(track, R.Round)
    Neu.inset(track, R.Round)
    local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = T("Accent2"), Parent = track })
    corner(fill, R.Round)

    local obj = { Type = "Progress", Name = o.Name, Value = 0 }
    self:_finish(obj, holder, o)
    function obj:Set(v)
        self.Value = math.clamp(tonumber(v) or 0, 0, max)
        local p = self.Value / max
        tween(fill, { Size = UDim2.fromScale(p, 1) }, M.Slow)
        pct.Text = o.ShowValue and (tostring(self.Value) .. "/" .. tostring(max)) or (math.floor(p * 100 + 0.5) .. "%")
        paint(fill, "BackgroundColor3", "Accent2", M.Base)
    end
    obj:Set(o.Default or o.Value or 0)
    return obj
end

----------------------------------------------------------------------------------------------------
-- CONFIGS
----------------------------------------------------------------------------------------------------
local function cfgFolder() return Kato.Config.Folder .. "/configs" end

local function encodeValue(obj)
    local v = obj.Value
    if obj.Type == "ColorPicker" then return { __c = toHex(v) } end
    if obj.Type == "Keybind" then return { __k = v and v.Name or "None" } end
    if type(v) == "table" then return table.clone(v) end
    return v
end

local function decodeValue(raw)
    if type(raw) == "table" and raw.__c then return fromHex(raw.__c) end
    if type(raw) == "table" and raw.__k then return toKey(raw.__k) end
    return raw
end

local function cleanName(n)
    n = trim(n):gsub("[^%w%-_ ]", "")
    return n
end

function Window:GetConfigs()
    local out = {}
    if not hasFS() or type(listfiles) ~= "function" then return out end
    ensureFolder(cfgFolder())
    local ok, files = pcall(listfiles, cfgFolder())
    if not ok or type(files) ~= "table" then return out end
    for _, f in ipairs(files) do
        local n = tostring(f):match("([^/\\]+)%.json$")
        if n then table.insert(out, n) end
    end
    table.sort(out)
    return out
end

function Window:SaveConfig(name)
    name = cleanName(name or "")
    if name == "" then return false, Kato.Strings.InvalidName end
    if not hasFS() then return false, Kato.Strings.NoFiles end
    local data = {}
    for flag, obj in pairs(Kato.Flags) do
        if obj.Type ~= "Button" and obj.Type ~= "Label" and obj.Type ~= "Paragraph" and obj.Type ~= "Progress" then
            data[flag] = encodeValue(obj)
        end
    end
    local ok = writeJSON(cfgFolder() .. "/" .. name .. ".json", data)
    if ok then return true end
    return false, Kato.Strings.WriteFailed
end

function Window:LoadConfig(name)
    name = cleanName(name or "")
    local data = readJSON(cfgFolder() .. "/" .. name .. ".json")
    if type(data) ~= "table" then return false, Kato.Strings.NotFound end
    for flag, raw in pairs(data) do
        local obj = Kato.Flags[flag]
        if obj and obj.Set then pcall(function() obj:Set(decodeValue(raw)) end) end
    end
    return true
end

function Window:DeleteConfig(name)
    name = cleanName(name or "")
    if not hasFS() or type(delfile) ~= "function" then return false end
    local path = cfgFolder() .. "/" .. name .. ".json"
    return pcall(function() if isfile(path) then delfile(path) end end)
end

function Window:SetAutoload(name)
    Kato._state.Autoload = name and cleanName(name) or nil
    saveState()
end

function Window:GetAutoload() return Kato._state.Autoload end

function Window:LoadAutoloadConfig()
    local n = Kato._state.Autoload
    if n and n ~= "" then
        local ok = self:LoadConfig(n)
        if ok then Kato:Notify({ Title = SK("ConfigLoaded"), Content = Kato.Strings.Autoload .. ": " .. n, Type = "Success", Duration = 3 }) end
        return ok
    end
    return false
end

----------------------------------------------------------------------------------------------------
-- PESTANA DE AJUSTES LISTA PARA USAR
----------------------------------------------------------------------------------------------------
function Window:CreateSettingsTab(name, icon)
    local win = self
    local tab = self:CreateTab({ Name = name or SK("Settings"), Icon = icon or "settings", Description = SK("SettingsDesc") })
    self._settingsTab = tab

    local ui = tab:CreateSection({ Name = SK("Appearance"), Icon = "palette", Description = SK("AppearanceDesc"), Side = "Left" })
    -- idioma: el valor es el codigo ("es", "en"...), lo que se ve es su nombre
    local langDd = ui:AddDropdown({
        Name = SK("Language"), Icon = "chat", Tooltip = SK("LanguageDesc"),
        Options = Kato:GetLanguages(), Labels = Kato.LanguageNames, Default = Kato.Language,
        Callback = function(code) if code and code ~= Kato.Language then Kato:SetLanguage(code) end end,
    })
    Kato:OnLanguageChanged(function(code)
        if langDd.Value ~= code then langDd:Set(code, true) end
    end)
    ui:AddDropdown({
        Name = SK("Theme"), Icon = "layers", Options = Kato:GetThemes(), Default = Kato.CurrentTheme,
        Callback = function(v) if v then Kato:SetTheme(v) end end,
    })
    local a1 = ui:AddColorPicker({ Name = SK("Accent"), Icon = "dot", Default = Color.Accent, Callback = function(c) Kato:SetAccent(c, nil) end })
    table.insert(Repaints, function() a1:Set(Color.Accent, true) end)
    ui:AddToggle({ Name = SK("Translucent"), Icon = "layers", Default = self.Glass, Callback = function(v) win:SetGlass(v) end })
    ui:AddSlider({
        Name = SK("Translucency"), Min = 0, Max = 100, Default = math.floor(self.GlassStrength * 100), Suffix = "%",
        Callback = function(v) win:SetGlassStrength(v / 100) end,
    })
    ui:AddToggle({ Name = SK("Blur"), Icon = "eye", Description = SK("BlurDesc"), Default = self.Blur, Callback = function(v) win:SetBlur(v) end })

    local sys = tab:CreateSection({ Name = SK("Interface"), Icon = "settings", Description = SK("InterfaceDesc"), Side = "Left" })
    sys:AddSlider({
        Name = SK("UIScale"), Min = 60, Max = 140, Increment = 5, Default = math.floor(self.UserScale * 100 + 0.5), Suffix = "%",
        Callback = function(v) win:SetScale(v / 100) end,
    })
    sys:AddToggle({ Name = SK("Animations"), Icon = "bolt", Default = Kato.Config.Animations, Callback = function(v) Kato.Config.Animations = v end })
    sys:AddToggle({ Name = SK("Tooltips"), Icon = "chat", Default = Kato.Config.Tooltip.Enabled, Callback = function(v) Kato.Config.Tooltip.Enabled = v end })
    sys:AddKeybind({
        Name = SK("MenuKey"), Icon = "key", Default = self.ToggleKey,
        ChangedCallback = function(k) if k then win:SetToggleKey(k) end end,
    })

    local cfg = tab:CreateSection({ Name = SK("Configs"), Icon = "folder", Description = SK("ConfigsDesc"), Side = "Right" })
    local nameBox = cfg:AddInput({ Name = SK("ConfigName"), Icon = "list", Placeholder = SK("ConfigPlaceholder") })
    local listDd = cfg:AddDropdown({ Name = SK("Saved"), Icon = "folder", Options = self:GetConfigs() })
    -- texto calculado: se actualiza solo al cambiar de idioma; auto:Set(autoText) lo refresca
    local autoText = TF(function() return Kato.Strings.Autoload .. ": " .. tostring(win:GetAutoload() or Kato.Strings.None) end)
    local auto = cfg:AddLabel({ Text = autoText })
    local function selected()
        local n = trim(nameBox.Value or "")
        if n == "" then n = listDd.Value or "" end
        return n
    end
    cfg:AddButton({
        Name = SK("SaveConfig"), Icon = "folder", Style = "Primary",
        Callback = function()
            local n = selected()
            local ok, err = win:SaveConfig(n)
            Kato:Notify({ Title = ok and SK("ConfigSaved") or SK("Error"), Content = ok and n or err, Type = ok and "Success" or "Error" })
            listDd:Refresh(win:GetConfigs(), true)
        end,
    })
    cfg:AddButton({
        Name = SK("LoadConfig"), Icon = "play",
        Callback = function()
            local n = listDd.Value or selected()
            local ok, err = win:LoadConfig(n)
            Kato:Notify({ Title = ok and SK("ConfigLoaded") or SK("Error"), Content = ok and n or err, Type = ok and "Success" or "Error" })
        end,
    })
    cfg:AddButton({
        Name = SK("SetAutoload"), Icon = "bolt",
        Callback = function()
            local n = listDd.Value or selected()
            if n == "" then return end
            win:SetAutoload(n)
            auto:Set(autoText)
            Kato:Notify({ Title = SK("Autoload"), Content = string.format(Kato.Strings.AutoloadSet, n), Type = "Info" })
        end,
    })
    cfg:AddButton({ Name = SK("RefreshList"), Icon = "refresh", Callback = function() listDd:Refresh(win:GetConfigs(), true) end })
    cfg:AddButton({
        Name = SK("DeleteConfig"), Icon = "trash", Style = "Danger", Confirm = true,
        Callback = function()
            local n = listDd.Value
            if not n then return end
            win:DeleteConfig(n)
            if win:GetAutoload() == n then win:SetAutoload(nil) end
            auto:Set(autoText)
            listDd:Refresh(win:GetConfigs(), false)
            Kato:Notify({ Title = SK("ConfigDeleted"), Content = n, Type = "Warning" })
        end,
    })

    local about = tab:CreateSection({ Name = SK("About"), Icon = "info", Side = "Right" })
    about:AddParagraph({
        Title = "Kato Lib v" .. Kato.Version,
        Content = TF(function() return string.format(Kato.Strings.AboutBody, tr(win._titleSrc or win.Title), keyName(win.ToggleKey)) end),
    })
    about:AddButton({ Name = SK("Unload"), Icon = "x", Style = "Danger", Confirm = true, Callback = function() Kato:Unload() end })
    return tab
end

function Kato:OnUnload(fn) table.insert(self._onUnload, fn) end

function Kato:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    for _, fn in ipairs(self._onUnload) do pcall(fn) end
    for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    table.clear(self._conns)
    hideTip()
    Kato._binding = false
    if blurFx then pcall(function() blurFx:Destroy() end) end
    pcall(function() gui:Destroy() end)
    table.clear(Repaints)
    table.clear(Kato.Flags)
    if genv().__KatoLib == self then genv().__KatoLib = nil end
end

return Kato
