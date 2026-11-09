<div align="center">

# 🟣 Kato Lib

**Librería de interfaz para Roblox (Luau) con estilo Soft UI — clara, moderna y en español.**

Ventana con pestañas · tarjetas con sombras suaves · 11 tipos de elementos · notificaciones · diálogos ·
configuraciones guardadas · 8 temas · español / inglés en vivo · barra animada · Key System incluido

`v3.5.0`

</div>

---

## 📑 Índice

- [Características](#-características)
- [Instalación](#-instalación)
- [Inicio rápido (30 segundos)](#-inicio-rápido-30-segundos)
- [Cómo está organizada](#-cómo-está-organizada)
- [La ventana](#-la-ventana)
- [Pestañas, categorías y secciones](#-pestañas-categorías-y-secciones)
- [Elementos](#-elementos)
- [Notificaciones y diálogos](#-notificaciones-y-diálogos)
- [La barra (watermark)](#-la-barra-watermark)
- [Pestaña de Ajustes lista para usar](#-pestaña-de-ajustes-lista-para-usar)
- [Flags y configuraciones](#-flags-y-configuraciones)
- [Idiomas (español / inglés)](#-idiomas-español--inglés)
- [Temas y colores](#-temas-y-colores)
- [Iconos](#-iconos)
- [Key System](#-key-system)
- [Ejemplos completos para copiar y pegar](#-ejemplos-completos-para-copiar-y-pegar)
- [Referencia rápida de la API](#-referencia-rápida-de-la-api)
- [Preguntas frecuentes](#-preguntas-frecuentes)

---

## ✨ Características

- **Diseño Soft UI**: tarjetas elevadas, controles hundidos y sombras suaves, con buen contraste (texto ≥ 4.5:1).
- **11 elementos**: Botón, Toggle, Slider, Dropdown (simple / múltiple / con buscador), Input, Keybind, Color Picker, Barra de progreso, Label, Párrafo y Divisor.
- **Español por defecto** y cambio a inglés **en vivo** desde los ajustes (y puedes añadir más idiomas).
- **Configuraciones**: guarda, carga, borra y carga automáticamente al iniciar.
- **8 temas** + color de acento personalizable.
- **Barra animada**: al minimizar, la ventana se transforma en una barra arriba al centro; un clic la vuelve a abrir.
- **Buscador** que filtra los elementos de la pestaña actual.
- **Responsive**: se adapta a pantallas pequeñas y móviles (modo compacto y una sola columna).
- **Key System** con el mismo estilo, que guarda la key del jugador.
- Sin assets obligatorios: todo se dibuja con Frames.

---

## 📦 Instalación

Solo necesitas un executor con `loadstring` y `game:HttpGet`.

```lua
local Kato = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lilwero20/KatoHub/refs/heads/main/KatoLib.lua"))()
```

Key System (opcional):

```lua
local KeySystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lilwero20/KatoHub/refs/heads/main/KatoKeySystem.lua"))()
```

> 💡 Si ejecutas el script dos veces, la copia anterior de la interfaz se cierra sola. No se duplica.

---

## ⚡ Inicio rápido (30 segundos)

Pega esto en tu executor: crea una ventana con una pestaña, un toggle y un slider.

```lua
local Kato = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lilwero20/KatoHub/refs/heads/main/KatoLib.lua"))()

local Window = Kato:CreateWindow({
    Title = "Mi Hub",
    Subtitle = "v1.0",
    ToggleKey = Enum.KeyCode.RightShift, -- tecla para mostrar / ocultar
})

local Main = Window:CreateTab({ Name = "Principal", Icon = "home" })
local Section = Main:CreateSection({ Name = "Jugador", Icon = "user" })

Section:AddToggle({
    Name = "Salto infinito",
    Flag = "InfJump",
    Callback = function(activado)
        print("Salto infinito:", activado)
    end,
})

Section:AddSlider({
    Name = "Velocidad",
    Min = 16, Max = 200, Default = 16,
    Callback = function(valor)
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = valor end
    end,
})

Window:CreateSettingsTab() -- tema, idioma, escala, configs...
Window:CreateWatermark()   -- barra de arriba (fps, ping, hora)
```

---

## 🧱 Cómo está organizada

```
Kato (librería)
└── Window (ventana)               Kato:CreateWindow({...})
    ├── Categoría (título gris)    Window:AddCategory("Principal")
    └── Tab (pestaña lateral)      Window:CreateTab({...})
        └── Section (tarjeta)      Tab:CreateSection({...})
            └── Elementos          Section:AddToggle / AddSlider / AddButton ...
```

- Cada **pestaña** muestra sus secciones en **dos columnas** (o una sola si la ventana es estrecha).
- Cada **sección** es una tarjeta con título, icono y descripción opcionales.
- Todos los elementos aceptan **una tabla de opciones** y devuelven un **objeto** para cambiarlos después.

---

## 🪟 La ventana

```lua
local Window = Kato:CreateWindow({
    Title = "Kato Hub",                         -- nombre en la barra lateral
    Subtitle = "v1.0",                          -- texto pequeño debajo del título
    Icon = "rbxassetid://110461677380547",      -- logo (rbxassetid o número)
    ToggleKey = Enum.KeyCode.RightShift,        -- tecla para abrir / cerrar
    Folder = "KatoHub",                         -- carpeta donde se guardan ajustes y configs
    Language = "es",                            -- idioma inicial: "es" o "en"
    ProfileSubtitle = "Miembro VIP",            -- texto bajo el nombre del jugador
    Width = 820, Height = 540,                  -- tamaño (se ajusta solo en pantallas chicas)
    Glass = false,                              -- ventana translúcida
    Blur = false,                               -- desenfocar el juego con el menú abierto
    Intro = true,                               -- animación de entrada
    SaveSettings = true,                        -- recordar tema, idioma, escala, tecla...
})
```

| Opción | Tipo | Por defecto | Descripción |
|---|---|---|---|
| `Title` | texto | `"Kato Hub"` | Título de la ventana. |
| `Subtitle` | texto | `"v" .. versión` | Subtítulo. |
| `Icon` | string / número | logo de Kato | Imagen del logo. |
| `ToggleKey` | `Enum.KeyCode` | `RightShift` | Tecla para mostrar / ocultar. |
| `Folder` | string | `"KatoHub"` | Carpeta de guardado del executor. |
| `Language` | `"es"` / `"en"` | `"es"` | Idioma inicial (el que elija el jugador en Ajustes tiene prioridad). |
| `ProfileSubtitle` | texto | `@usuario` | Texto en la tarjeta del jugador. |
| `Width`, `Height` | número | `820`, `540` | Tamaño base. |
| `MinWidth`, `MinHeight` | número | — | Tamaño mínimo al redimensionar. |
| `SidebarWidth` | número | `200` | Ancho de la barra lateral. |
| `Glass` | bool | `false` | Ventana translúcida. |
| `Transparency` | 0–1 | `0.5` | Fuerza de la translucidez. |
| `Blur` | bool | `false` | Desenfoca el juego detrás del menú. |
| `Intro` | bool | `true` | Animación de entrada. |
| `FloatingButton` | bool | `true` | Botón flotante para abrir el menú (si no usas la barra). |
| `SaveSettings` | bool | `true` | Guarda los ajustes en `Folder/settings.json`. |

**Métodos útiles:**

```lua
Window:Toggle()                 -- abre / cierra
Window:Show()  Window:Hide()
Window:SetTitle("Nuevo título")
Window:SetSubtitle("v2.0")
Window:SetToggleKey(Enum.KeyCode.K)
Window:SetScale(1.1)            -- escala de la interfaz (0.6 - 1.4)
Window:SetGlass(true)           -- translúcida
Window:SetBlur(true)            -- desenfoque
Window:SelectTab("Principal")   -- cambia de pestaña por nombre (en cualquier idioma)
Window:Destroy()                -- cierra todo (igual que Kato:Unload())
```

La ventana se puede **arrastrar** desde la parte de arriba y **redimensionar** desde la esquina inferior derecha.

---

## 🗂 Pestañas, categorías y secciones

```lua
Window:AddCategory("Principal") -- título pequeño en la barra lateral

local Home = Window:CreateTab({
    Name = "Inicio",
    Icon = "home",
    Description = "Bienvenido a mi hub", -- texto debajo del título de la página
    Badge = "Nuevo",                     -- etiqueta a la derecha (opcional)
})

-- Sección en la columna izquierda
local Farm = Home:CreateSection({
    Name = "Granjeo",
    Description = "Automatiza las partes aburridas.",
    Icon = "bolt",
    Side = "Left",   -- "Left" | "Right" (si no lo pones, se reparte sola)
})

-- Sección ancha (ocupa las dos columnas)
local Info = Home:CreateSection({ Name = "Novedades", Icon = "star", Wide = true })
```

También funciona la forma corta: `Window:CreateTab("Inicio", "home")`.

| Sección | Descripción |
|---|---|
| `Section:SetTitle(texto)` | Cambia el título. |
| `Section:SetVisible(bool)` | Muestra / oculta la tarjeta. |

---

## 🎛 Elementos

Opciones que aceptan **todos** los elementos:

| Opción | Descripción |
|---|---|
| `Name` | Texto principal. |
| `Description` | Texto pequeño debajo del nombre. |
| `Icon` | Icono a la izquierda ([ver iconos](#-iconos)). |
| `Flag` | Nombre único para guardarlo en configs y leerlo con `Kato.Flags`. |
| `Tooltip` | Texto al pasar el ratón. |
| `Disabled` | `true` para bloquearlo. |
| `Callback` | Función que se llama al cambiar. |

Métodos que tienen **todos** los objetos:

```lua
obj:Set(valor)          -- cambia el valor (y llama al Callback)
obj:Get()               -- devuelve el valor
obj:OnChanged(fn)       -- otro listener además del Callback
obj:SetVisible(bool)
obj:SetDisabled(bool)
obj:Destroy()
```

### Botón

```lua
Section:AddButton({
    Name = "Teletransportar al spawn",
    Icon = "play",
    Style = "Primary",     -- "Primary" (morado) | "Danger" (rojo) | nada (normal)
    Confirm = false,       -- true: pide un segundo clic para confirmar
    Callback = function()
        print("¡Clic!")
    end,
})
```

Métodos: `:Fire()` (lo ejecuta), `:SetText("Nuevo texto")`.

### Toggle (interruptor)

```lua
local AutoFarm = Section:AddToggle({
    Name = "Granjeo automático",
    Description = "Farmea solo mientras está activo",
    Default = false,
    Flag = "AutoFarm",
    Callback = function(activado)
        print("AutoFarm:", activado)
    end,
})

AutoFarm:Set(true)   -- lo activa
AutoFarm:Toggle()    -- lo invierte
```

`CallOnStart = true` llama al Callback al crearlo si `Default` es `true`.

### Slider

```lua
Section:AddSlider({
    Name = "Velocidad al caminar",
    Min = 16, Max = 200,
    Default = 16,
    Increment = 1,      -- paso (ej: 0.05 para decimales)
    Suffix = "",        -- texto después del número (ej: "s", "%")
    Flag = "Speed",
    Callback = function(valor) print(valor) end,
})
```

Métodos: `:SetRange(min, max)`.

### Dropdown (lista desplegable)

```lua
-- Simple
local Target = Section:AddDropdown({
    Name = "Objetivo",
    Options = { "Más cercano", "Más fuerte", "Aleatorio" },
    Default = "Más cercano",
    Flag = "Target",
    Callback = function(opcion) print(opcion) end,
})

-- Múltiple: el valor es una tabla
Section:AddDropdown({
    Name = "Partes del ESP",
    Multi = true,
    Options = { "Caja", "Nombre", "Distancia", "Vida" },
    Default = { "Caja", "Nombre" },
    Callback = function(lista) print(table.concat(lista, ", ")) end,
})
```

| Opción | Descripción |
|---|---|
| `Options` | Lista de opciones. |
| `Default` | Opción inicial (o tabla si es `Multi`). También acepta el índice. |
| `Multi` | Selección múltiple. |
| `Search` | `true`/`false` fuerza el buscador (por defecto aparece con 8+ opciones). |
| `MaxVisible` | Opciones visibles antes de hacer scroll (6). |
| `AllowNone` | Permite deseleccionar la opción actual. |
| `Labels` | Texto a mostrar por opción, sin cambiar el valor ([ver Idiomas](#-idiomas-español--inglés)). |

Métodos: `:Refresh(nuevasOpciones, mantenerSeleccion)`, `:Add(opcion)`, `:Remove(opcion)`, `:SetLabels(tabla)`, `:Close()`.

```lua
-- Lista de jugadores que se actualiza
local function nombres()
    local t = {}
    for _, p in ipairs(game.Players:GetPlayers()) do table.insert(t, p.Name) end
    return t
end
local Players = Section:AddDropdown({ Name = "Jugador", Options = nombres() })
game.Players.PlayerAdded:Connect(function() Players:Refresh(nombres(), true) end)
game.Players.PlayerRemoving:Connect(function() task.wait() Players:Refresh(nombres(), true) end)
```

### Input (campo de texto)

```lua
Section:AddInput({
    Name = "Fuerza de salto",
    Placeholder = "50",
    Numeric = true,         -- solo números; el Callback recibe un number
    Flag = "JumpPower",
    Callback = function(valor) print(valor) end,
})
```

| Opción | Descripción |
|---|---|
| `Placeholder` | Texto gris cuando está vacío. |
| `Default` | Texto inicial. |
| `Numeric` | Solo acepta números. |
| `MaxLength` | Máximo de caracteres. |
| `Finished` | `false` = llama al Callback mientras escribes (por defecto, al terminar). |
| `ClearOnFocus` / `ClearOnEnter` | Borra el texto al enfocar / al pulsar Enter. |

Métodos: `:SetPlaceholder(texto)`. Alias: `AddTextbox`, `AddTextBox`.

### Keybind (tecla)

```lua
Section:AddKeybind({
    Name = "Tecla para volar",
    Default = Enum.KeyCode.F,
    Mode = "Toggle",            -- "Press" | "Hold" | "Toggle"
    Flag = "FlyKey",
    Callback = function(estado) print("Volar:", estado) end,
    ChangedCallback = function(nuevaTecla) print("Nueva tecla:", nuevaTecla) end,
})
```

- **Press**: el Callback se llama cada vez que pulsas la tecla.
- **Hold**: `Callback(true)` al pulsar y `Callback(false)` al soltar.
- **Toggle**: alterna `true` / `false` en cada pulsación.

Para cambiar la tecla, haz clic en ella y pulsa otra. `Esc` cancela; `Backspace` la borra.

### Color Picker

```lua
Section:AddColorPicker({
    Name = "Color del ESP",
    Default = Color3.fromRGB(123, 97, 255), -- también acepta "#7B61FF"
    Flag = "EspColor",
    Callback = function(color) print(color) end,
})
```

### Barra de progreso

```lua
local Progress = Section:AddProgress({ Name = "Misiones completadas", Max = 10, Default = 3, ShowValue = true })
Progress:Set(7) -- muestra "7/10" (sin ShowValue muestra "70%")
```

### Label, Párrafo y Divisor

```lua
Section:AddLabel("Texto simple. Admite <b>RichText</b> y <font color='#7B61FF'>colores</font>.")

local P = Section:AddParagraph({
    Title = "¿Cómo se usa?",
    Content = "Activa el granjeo y deja el juego abierto.",
    Icon = "info",
})
P:SetContent("Texto nuevo")

Section:AddDivider("Avanzado") -- línea con título (o AddDivider() sin texto)
```

---

## 🔔 Notificaciones y diálogos

```lua
Kato:Notify("Mensaje rápido")

Kato:Notify({
    Title = "Listo",
    Content = "La configuración se guardó.",
    Type = "Success",       -- "Info" | "Success" | "Warning" | "Error"
    Duration = 4,           -- segundos (se pausa al pasar el ratón)
    Icon = "check",         -- opcional
    Callback = function() print("Clic en la notificación") end,
})
```

`Kato:Notify` devuelve un objeto con `:SetTitle()`, `:SetContent()` y `:Close()`.

```lua
Window:Dialog({
    Title = "¿Reiniciar personaje?",
    Content = "Perderás tu posición actual.",
    Icon = "warning",
    Buttons = {
        { Name = "Cancelar" },
        { Name = "Reiniciar", Primary = true, Callback = function()
            game.Players.LocalPlayer.Character:BreakJoints()
        end },
    },
})
```

---

## 💊 La barra (watermark)

```lua
Window:CreateWatermark()
```

Crea una barra arriba al centro con el logo, el nombre, los **FPS**, el **ping** y la **hora**.

- Con el menú **abierto**, la barra se oculta.
- Al **minimizar** (botón `–` o la tecla), la ventana **se transforma en la barra** con una animación, y la barra rebota con una onda de color.
- Al **pasar el ratón** aparece una flechita →; **un clic** abre el menú otra vez.
- Se puede arrastrar a otro sitio.

```lua
Window:CreateWatermark({
    Text = "Mi Hub",        -- texto (por defecto, el título de la ventana)
    FPS = true, Ping = true, Time = true,
    Toggle = true,          -- false = barra fija, solo informativa
    Position = UDim2.new(0.5, 0, 0, 16), AnchorPoint = Vector2.new(0.5, 0),
})
```

---

## ⚙️ Pestaña de Ajustes lista para usar

```lua
Window:CreateSettingsTab()
```

Una línea crea una pestaña completa con:

- **Apariencia**: idioma (Español / English), tema, color de acento, ventana translúcida, desenfoque.
- **Interfaz**: tamaño de la interfaz, animaciones, ayudas (tooltips) y tecla del menú.
- **Configuraciones**: guardar, cargar, borrar, actualizar la lista y elegir cuál se carga al iniciar.
- **Acerca de** y un botón para cerrar la interfaz.

Todo lo que el jugador cambie aquí se recuerda la próxima vez.

---

## 💾 Flags y configuraciones

Todo elemento con `Flag` queda registrado en `Kato.Flags` y se guarda en las configuraciones.

```lua
Section:AddToggle({ Name = "Auto Farm", Flag = "AutoFarm" })

-- leerlo desde cualquier parte del script
if Kato.Flags.AutoFarm.Value then
    print("está activado")
end

-- cambiarlo desde código
Kato.Flags.AutoFarm:Set(true)
```

> ⚠️ Cada `Flag` debe ser **único**.

Guardar y cargar desde código (también se hace desde la pestaña de Ajustes):

```lua
Window:SaveConfig("legit")       -- KatoHub/configs/legit.json
Window:LoadConfig("legit")
Window:DeleteConfig("legit")
print(Window:GetConfigs())       -- lista de nombres
Window:SetAutoload("legit")      -- se cargará al iniciar

Window:LoadAutoloadConfig()      -- ponlo al FINAL de tu script
```

---

## 🌎 Idiomas (español / inglés)

La interfaz sale en **español**. El jugador puede cambiar a **inglés** en *Ajustes → Apariencia → Idioma*, y todo cambia al instante.

Para que **tus textos** también se traduzcan, en lugar de un string usa una tabla `{ es = ..., en = ... }`:

```lua
local function T(es, en) return { es = es, en = en } end -- atajo opcional

local Home = Window:CreateTab({ Name = T("Inicio", "Home"), Icon = "home" })
local Farm = Home:CreateSection({ Name = T("Granjeo", "Farming") })

Farm:AddToggle({
    Name = T("Granjeo automático", "Auto Farm"),
    Description = T("Farmea solo", "Farms automatically"),
    Flag = "AutoFarm",
})

Kato:Notify({ Title = T("Listo", "Done"), Content = T("Todo cargado.", "Everything loaded.") })
```

Funciona en `Name`, `Description`, `Title`, `Content`, `Placeholder`, `Tooltip`, `Badge`, `AddCategory`, `AddDivider`, `AddLabel`, notificaciones y diálogos.

**Dropdowns traducidos.** El **valor** no cambia (tus callbacks y configs siguen funcionando); solo cambia lo que se ve:

```lua
Farm:AddDropdown({
    Name = T("Objetivo", "Target"),
    Options = { "Nearest", "Strongest" },             -- valores internos
    Labels = {
        Nearest   = T("Más cercano", "Nearest"),
        Strongest = T("Más fuerte", "Strongest"),
    },
    Default = "Nearest",
    Callback = function(v) print(v) end,              -- siempre "Nearest" o "Strongest"
})
```

**Desde código:**

```lua
Kato:SetLanguage("en")
print(Kato:GetLanguage())          -- "en"
Kato:OnLanguageChanged(function(code) print("Idioma:", code) end)

-- añadir otro idioma (lo que falte se toma del inglés)
Kato:AddLanguage("pt", "Português", { None = "Nenhum", Search = "Buscar...", Settings = "Configurações" })
```

---

## 🎨 Temas y colores

Temas incluidos: **Kato** (por defecto), **Orchid**, **Sakura**, **Mint**, **Ocean**, **Sand**, **Graphite** y **Midnight** (estos dos últimos son oscuros).

```lua
Kato:SetTheme("Orchid")
Kato:SetAccent(Color3.fromRGB(255, 90, 120))   -- cambia el color principal
print(Kato:GetThemes())

-- tema propio
Kato:AddTheme("Lima", {
    Background = Color3.fromRGB(226, 236, 220),
    Accent = Color3.fromRGB(70, 160, 60),
    Text = Color3.fromRGB(30, 45, 30),
    Dark = false,
})
Kato:SetTheme("Lima")
```

---

## 🖼 Iconos

`Icon` acepta:

- un **nombre** del set incluido,
- un **rbxassetid** o número (`"rbxassetid://123"` / `123`),
- o **1–2 letras** (`"A"`).

Iconos incluidos:

`home` `user` `users` `eye` `box` `settings` `bolt` `star` `heart` `sword` `target` `clock` `palette` `key` `list` `grid` `search` `info` `check` `x` `warning` `chart` `folder` `trash` `globe` `bell` `lock` `shield` `chat` `code` `play` `plus` `minus` `crown` `layers` `run` `dollar` `link` `refresh` `dot` `chevron`

```lua
print(table.concat(Kato:GetIcons(), ", ")) -- lista completa
```

---

## 🔑 Key System

Pantalla de key con el mismo estilo. Sigue el **idioma** y los **colores** de Kato Lib si le pasas `Library = Kato`.

```lua
local Kato = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lilwero20/KatoHub/refs/heads/main/KatoLib.lua"))()
local KeySystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lilwero20/KatoHub/refs/heads/main/KatoKeySystem.lua"))()

local ok, key = KeySystem.Prompt({
    Title = "Kato Hub",
    Library = Kato,                                   -- usa su tema e idioma
    Keys = { "KATO-1234", "KATO-5678" },              -- keys válidas
    KeyLink = "https://tu-link-para-sacar-key.com",   -- botón "Conseguir key" (se copia)
    DiscordLink = "https://discord.gg/tu-servidor",   -- botón "Discord" (opcional)
})

if not ok then return end -- el jugador cerró la ventana
print("Key correcta:", key)
-- aquí carga tu hub
```

**Tres formas de validar la key** (usa una):

```lua
-- 1. lista fija
KeySystem.Prompt({ Title = "Mi Hub", Keys = { "KEY-1", "KEY-2" } })

-- 2. desde internet: un archivo de texto con una key por línea
KeySystem.Prompt({ Title = "Mi Hub", KeyUrl = "https://raw.githubusercontent.com/TU_USUARIO/TU_REPO/main/keys.txt" })

-- 3. tu propia función (devuelve true/false y, si quieres, un mensaje)
KeySystem.Prompt({
    Title = "Mi Hub",
    Validate = function(key)
        return key == "secreta", "Key incorrecta"
    end,
})
```

| Opción | Por defecto | Descripción |
|---|---|---|
| `Title` / `Subtitle` / `Description` | — | Textos (aceptan `{ es, en }`). |
| `Placeholder` | `"Pega tu key aquí"` | Texto del campo. |
| `Icon` | logo de Kato | Imagen. |
| `KeyLink` / `DiscordLink` | — | Links que se copian al portapapeles. |
| `SaveKey` | `true` | Recuerda la key: la próxima vez entra solo. |
| `Folder` | `"KatoHub"` | Carpeta donde se guarda la key. |
| `MaxAttempts` / `Cooldown` | `5` / `20` | Intentos antes de bloquear y segundos de espera. |
| `CaseSensitive` | `true` | Distingue mayúsculas. |
| `Language` | idioma de `Library` o `"es"` | `"es"` / `"en"`. |
| `Library` | — | Kato Lib, para heredar tema e idioma. |
| `Accent`, `Accent2`, `Theme` | — | Colores propios si no usas `Library`. |
| `OnSuccess(key)` / `OnFail(key, msg)` / `OnClose()` | — | Callbacks. |

Uso sin esperar (asíncrono): `local ks = KeySystem.new({...})`, luego `ks:Wait()`, `ks:SetStatus("texto", "Success")`, `ks:Close()`.

---

## 📋 Ejemplos completos para copiar y pegar

### Ejemplo 1 — Hub básico en español

Ejecútalo tal cual en cualquier juego.

```lua
local Kato = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lilwero20/KatoHub/refs/heads/main/KatoLib.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local Window = Kato:CreateWindow({
    Title = "Mi Hub",
    Subtitle = "v1.0",
    ToggleKey = Enum.KeyCode.RightShift,
    Folder = "MiHub",
})

-------------------------------------------------- Jugador
Window:AddCategory("Principal")
local PlayerTab = Window:CreateTab({ Name = "Jugador", Icon = "user", Description = "Movimiento y personaje" })

local Move = PlayerTab:CreateSection({ Name = "Movimiento", Icon = "run", Side = "Left" })

Move:AddSlider({
    Name = "Velocidad", Icon = "run", Min = 16, Max = 250, Default = 16, Flag = "WalkSpeed",
    Callback = function(v)
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
    end,
})

Move:AddSlider({
    Name = "Salto", Min = 50, Max = 300, Default = 50, Flag = "JumpPower",
    Callback = function(v)
        local hum = getHumanoid()
        if hum then hum.UseJumpPower = true hum.JumpPower = v end
    end,
})

local infJump = false
Move:AddToggle({
    Name = "Salto infinito", Description = "Salta en el aire", Flag = "InfJump",
    Callback = function(v) infJump = v end,
})
game:GetService("UserInputService").JumpRequest:Connect(function()
    if infJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local Cam = PlayerTab:CreateSection({ Name = "Cámara", Icon = "eye", Side = "Right" })
Cam:AddSlider({
    Name = "Campo de visión", Min = 50, Max = 120, Default = 70, Flag = "FOV",
    Callback = function(v) workspace.CurrentCamera.FieldOfView = v end,
})
Cam:AddButton({
    Name = "Reiniciar personaje", Style = "Danger", Confirm = true,
    Callback = function()
        local hum = getHumanoid()
        if hum then hum.Health = 0 end
    end,
})

-------------------------------------------------- Otros
Window:AddCategory("Otros")
Window:CreateSettingsTab()
Window:CreateWatermark()
Window:LoadAutoloadConfig()

Kato:Notify({ Title = "Mi Hub", Content = "Cargado. Pulsa RightShift para ocultar el menú.", Type = "Success" })
```

### Ejemplo 2 — Hub completísimo: Key System + todos los elementos + español/inglés

Este ejemplo usa **todos** los componentes. Pégalo y pruébalo. La key de prueba es **`KATO-DEMO`**.

```lua
--====================================================================
--  Kato Hub · Ejemplo completo (Key System + todos los elementos)
--  Key de prueba: KATO-DEMO
--====================================================================
local Kato = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lilwero20/KatoHub/refs/heads/main/KatoLib.lua"))()
local KeySystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lilwero20/KatoHub/refs/heads/main/KatoKeySystem.lua"))()

-- atajo para textos traducibles
local function T(es, en) return { es = es, en = en } end

---------------------------------------------------------------- KEY
local ok = KeySystem.Prompt({
    Title = "Kato Hub",
    Library = Kato,
    Keys = { "KATO-DEMO" },
    KeyLink = "https://example.com/key",
    DiscordLink = "https://discord.gg/example",
})
if not ok then return end

---------------------------------------------------------------- SERVICIOS
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

---------------------------------------------------------------- VENTANA
local Window = Kato:CreateWindow({
    Title = "Kato Hub",
    Subtitle = "v" .. Kato.Version,
    Icon = "rbxassetid://110461677380547",
    ToggleKey = Enum.KeyCode.RightShift,
    Folder = "KatoHub",
    Language = "es",
    ProfileSubtitle = T("Miembro VIP", "Premium member"),
})

---------------------------------------------------------------- INICIO
Window:AddCategory(T("Principal", "Main"))
local Home = Window:CreateTab({
    Name = T("Inicio", "Home"), Icon = "home",
    Description = T("Bienvenido de nuevo a Kato Hub", "Welcome back to Kato Hub"),
})

local Overview = Home:CreateSection({
    Name = T("Resumen", "Overview"), Icon = "star", Wide = true,
    Description = T("Todo lo que necesitas, en un solo lugar.", "Everything you need, in one place."),
})
Overview:AddParagraph({
    Title = T("Kato Hub está listo", "Kato Hub is ready"), Icon = "check",
    Content = T(
        "Usa la barra lateral para cambiar de pestaña, el buscador para filtrar opciones y <b>RightShift</b> para ocultar el menú.",
        "Use the sidebar to switch tabs, the search box to filter options and <b>RightShift</b> to hide the menu."
    ),
})
local Loading = Overview:AddProgress({ Name = T("Cargando recursos", "Loading assets"), Icon = "layers", Default = 20 })

-- Granjeo
local Farm = Home:CreateSection({
    Name = T("Granjeo", "Farming"), Icon = "bolt",
    Description = T("Automatiza las partes aburridas.", "Automate the boring parts."),
})
local farming = false
Farm:AddToggle({
    Name = T("Granjeo automático", "Auto Farm"), Icon = "play", Flag = "AutoFarm",
    Tooltip = T("Farmea mientras está activo", "Farms while enabled"),
    Callback = function(v)
        farming = v
        if v then
            task.spawn(function()
                while farming do
                    -- tu lógica de farmeo aquí
                    task.wait(Kato.Flags.FarmDelay and Kato.Flags.FarmDelay.Value or 0.5)
                end
            end)
        end
    end,
})
Farm:AddToggle({
    Name = T("Recoger automático", "Auto Collect"), Flag = "AutoCollect",
    Description = T("Recoge lo que cae cerca", "Picks up nearby drops"),
})
Farm:AddSlider({
    Name = T("Espera entre acciones", "Delay"), Min = 0, Max = 2, Increment = 0.05, Default = 0.5,
    Suffix = "s", Flag = "FarmDelay",
})
Farm:AddDropdown({
    Name = T("Objetivo", "Target"), Icon = "target", Flag = "Target", Default = "Nearest",
    Options = { "Nearest", "Strongest", "Weakest", "Random" },
    Labels = {
        Nearest = T("Más cercano", "Nearest"), Strongest = T("Más fuerte", "Strongest"),
        Weakest = T("Más débil", "Weakest"), Random = T("Aleatorio", "Random"),
    },
    Callback = function(v) print("Objetivo:", v) end,
})

-- Acciones
local Actions = Home:CreateSection({
    Name = T("Acciones rápidas", "Quick Actions"), Icon = "grid",
    Description = T("Botones, diálogos y avisos.", "Buttons, dialogs and alerts."),
})
Actions:AddButton({
    Name = T("Iniciar simulación", "Run simulation"), Style = "Primary",
    Callback = function()
        task.spawn(function()
            for v = 0, 100, 5 do Loading:Set(v) task.wait(0.05) end
            Kato:Notify({ Title = T("Listo", "Done"), Content = T("Simulación terminada.", "Simulation finished."), Type = "Success" })
        end)
    end,
})
Actions:AddButton({
    Name = T("Mostrar diálogo", "Show dialog"),
    Callback = function()
        Window:Dialog({
            Title = "Kato Hub", Icon = "info",
            Content = T("¿Quieres recibir una notificación?", "Do you want a notification?"),
            Buttons = {
                { Name = T("No", "No") },
                { Name = T("Sí", "Yes"), Primary = true, Callback = function() Kato:Notify(T("¡Hola!", "Hello!")) end },
            },
        })
    end,
})
Actions:AddButton({
    Name = T("Reiniciar personaje", "Reset character"), Style = "Danger", Confirm = true,
    Callback = function()
        local hum = getHumanoid()
        if hum then hum.Health = 0 end
    end,
})
Actions:AddDivider(T("Notificaciones", "Notifications"))
for _, kind in ipairs({ "Info", "Success", "Warning", "Error" }) do
    Actions:AddButton({
        Name = kind,
        Callback = function() Kato:Notify({ Title = kind, Content = T("Notificación de prueba.", "Test notification."), Type = kind }) end,
    })
end

---------------------------------------------------------------- JUGADOR
local PlayerTab = Window:CreateTab({
    Name = T("Jugador", "Player"), Icon = "user",
    Description = T("Movimiento y controles", "Movement and controls"),
})

local Move = PlayerTab:CreateSection({ Name = T("Movimiento", "Movement"), Icon = "run", Side = "Left" })
Move:AddSlider({
    Name = T("Velocidad", "Walk speed"), Icon = "run", Min = 16, Max = 250, Default = 16, Flag = "WalkSpeed",
    Callback = function(v) local h = getHumanoid() if h then h.WalkSpeed = v end end,
})
local infJump = false
Move:AddToggle({ Name = T("Salto infinito", "Infinite jump"), Flag = "InfJump", Callback = function(v) infJump = v end })
UserInputService.JumpRequest:Connect(function()
    if infJump then
        local h = getHumanoid()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
Move:AddSlider({
    Name = T("Campo de visión", "Field of view"), Min = 50, Max = 120, Default = 70, Flag = "FOV",
    Callback = function(v) workspace.CurrentCamera.FieldOfView = v end,
})

local Inputs = PlayerTab:CreateSection({ Name = T("Entradas", "Inputs"), Icon = "key", Side = "Right" })
Inputs:AddInput({
    Name = T("Fuerza de salto", "Jump power"), Placeholder = "50", Numeric = true, Flag = "JumpPower",
    Callback = function(v)
        local h = getHumanoid()
        if h and v then h.UseJumpPower = true h.JumpPower = v end
    end,
})
Inputs:AddInput({ Name = T("Mensaje", "Message"), Icon = "chat", Placeholder = T("Escribe algo...", "Type something..."), Flag = "Message" })
Inputs:AddKeybind({
    Name = T("Tecla de prueba", "Test key"), Default = Enum.KeyCode.F, Flag = "TestKey",
    Callback = function() Kato:Notify(T("¡Tecla pulsada!", "Key pressed!")) end,
})
Inputs:AddKeybind({
    Name = T("Correr (mantener)", "Sprint (hold)"), Default = Enum.KeyCode.LeftShift, Mode = "Hold",
    Callback = function(down)
        local h = getHumanoid()
        if h then h.WalkSpeed = down and 32 or (Kato.Flags.WalkSpeed.Value or 16) end
    end,
})

---------------------------------------------------------------- VISUALES
local Visuals = Window:CreateTab({
    Name = T("Visuales", "Visuals"), Icon = "eye", Badge = T("Nuevo", "New"),
    Description = T("Colores y ESP", "Colors and ESP"),
})
local Esp = Visuals:CreateSection({ Name = "ESP", Icon = "eye", Side = "Left" })
local highlights = {}
local function clearEsp()
    for _, h in pairs(highlights) do h:Destroy() end
    highlights = {}
end
local function applyEsp()
    clearEsp()
    if not Kato.Flags.Esp.Value then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = Instance.new("Highlight")
            h.FillColor = Kato.Flags.EspColor.Value
            h.OutlineColor = Color3.new(1, 1, 1)
            h.FillTransparency = 0.6
            h.Parent = p.Character
            highlights[p] = h
        end
    end
end
Esp:AddToggle({ Name = T("Activar ESP", "Enable ESP"), Icon = "eye", Flag = "Esp", Callback = applyEsp })
Esp:AddColorPicker({
    Name = T("Color del ESP", "ESP color"), Icon = "palette", Default = Color3.fromRGB(123, 97, 255), Flag = "EspColor",
    Callback = function() applyEsp() end,
})
Esp:AddDropdown({
    Name = T("Mostrar", "Show"), Multi = true, Flag = "EspParts",
    Options = { "Box", "Name", "Distance" }, Default = { "Box" },
    Labels = { Box = T("Caja", "Box"), Name = T("Nombre", "Name"), Distance = T("Distancia", "Distance") },
})
Kato:OnUnload(clearEsp) -- limpia al cerrar la interfaz

local World = Visuals:CreateSection({ Name = T("Mundo", "World"), Icon = "globe", Side = "Right" })
World:AddSlider({
    Name = T("Brillo", "Brightness"), Min = 0, Max = 5, Increment = 0.1, Default = 2, Flag = "Brightness",
    Callback = function(v) game:GetService("Lighting").Brightness = v end,
})
World:AddToggle({
    Name = T("Siempre de día", "Always day"), Flag = "FullDay",
    Callback = function(v) if v then game:GetService("Lighting").ClockTime = 14 end end,
})

---------------------------------------------------------------- INFO
local InfoTab = Window:CreateTab({ Name = T("Info", "Info"), Icon = "info" })
local Tips = InfoTab:CreateSection({ Name = T("Consejos", "Tips"), Icon = "info", Wide = true })
Tips:AddParagraph({
    Title = T("Buscar", "Search"),
    Content = T("Usa el buscador de arriba para encontrar cualquier opción de la pestaña.", "Use the search box to find any option in the tab."),
})
Tips:AddLabel(T("Cambia el idioma en <b>Ajustes → Idioma</b>.", "Change the language in <b>Settings → Language</b>."))
Tips:AddDivider()
Tips:AddLabel(T("Minimiza el menú y vuelve a abrirlo con la barra de arriba.", "Minimize the menu and reopen it from the bar at the top."))

---------------------------------------------------------------- OTROS
Window:AddCategory(T("Otros", "Other"))
Window:CreateSettingsTab()
Window:CreateWatermark()
Window:LoadAutoloadConfig()

Kato:Notify({
    Title = T("Kato Hub cargado", "Kato Hub loaded"),
    Content = T("Pulsa RightShift para mostrar u ocultar el menú.", "Press RightShift to toggle the menu."),
    Type = "Success",
})
```

### Ejemplo 3 — Solo el Key System (y luego cargar tu script)

```lua
local KeySystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lilwero20/KatoHub/refs/heads/main/KatoKeySystem.lua"))()

local ok = KeySystem.Prompt({
    Title = "Mi Hub",
    Language = "es",
    KeyUrl = "https://raw.githubusercontent.com/TU_USUARIO/TU_REPO/main/keys.txt", -- una key por línea
    KeyLink = "https://tu-link.com",
    MaxAttempts = 5,
    Cooldown = 20,
})

if ok then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/TU_USUARIO/TU_REPO/main/hub.lua"))()
end
```

---

## 📚 Referencia rápida de la API

### Kato

| Función | Descripción |
|---|---|
| `Kato:CreateWindow(opciones)` | Crea la ventana. |
| `Kato:Notify(texto \| opciones)` | Notificación. |
| `Kato:SetTheme(nombre)` / `Kato:GetThemes()` / `Kato:AddTheme(nombre, tabla)` | Temas. |
| `Kato:SetAccent(color1, color2?)` | Color de acento. |
| `Kato:SetLanguage(code)` / `Kato:GetLanguage()` / `Kato:GetLanguages()` | Idioma. |
| `Kato:AddLanguage(code, nombre, textos)` / `Kato:OnLanguageChanged(fn)` / `Kato:Tr(texto)` | Idiomas extra. |
| `Kato:GetIcons()` | Lista de iconos. |
| `Kato:OnUnload(fn)` / `Kato:Unload()` | Limpieza al cerrar / cerrar todo. |
| `Kato.Flags` | Elementos con `Flag` (`Kato.Flags.X.Value`). |
| `Kato.Version` | Versión de la librería. |
| `Kato.Config.Animations` | `false` desactiva las animaciones. |

### Window

| Método | Descripción |
|---|---|
| `CreateTab(opciones)` / `AddCategory(texto)` | Pestañas y categorías. |
| `SelectTab(tab \| nombre)` / `GetTab(nombre)` | Navegar. |
| `Notify(opciones)` / `Dialog(opciones)` | Avisos. |
| `Toggle()` / `Show()` / `Hide()` / `SetVisible(bool)` | Visibilidad. |
| `SetTitle` / `SetSubtitle` / `SetToggleKey` / `SetScale` / `SetGlass` / `SetGlassStrength` / `SetBlur` | Ajustes. |
| `CreateSettingsTab()` / `CreateWatermark(opciones)` | Extras listos. |
| `SaveConfig` / `LoadConfig` / `DeleteConfig` / `GetConfigs` / `SetAutoload` / `GetAutoload` / `LoadAutoloadConfig` | Configs. |
| `Destroy()` | Cierra la interfaz. |

### Section

`AddButton` · `AddToggle` · `AddSlider` · `AddDropdown` · `AddInput` (`AddTextbox`) · `AddKeybind` · `AddColorPicker` · `AddProgress` · `AddLabel` · `AddParagraph` · `AddDivider` · `SetTitle` · `SetVisible`

---

## ❓ Preguntas frecuentes

**El menú no aparece.**
Revisa que tu executor soporte `loadstring` y `game:HttpGet`. Mira la consola (F9) por si hay errores.

**¿Cómo lo vuelvo a abrir si lo minimicé?**
Haz clic en la barra de arriba (si usas `CreateWatermark()`), pulsa la tecla del menú (`RightShift` por defecto) o usa el botón flotante.

**Mis textos salen en español aunque cambié a inglés.**
Ese texto está como string normal. Escríbelo como tabla: `Name = { es = "Velocidad", en = "Speed" }`.

**¿Dónde se guardan las configs?**
En la carpeta `workspace` de tu executor: `KatoHub/configs/*.json` (o la carpeta que pongas en `Folder`).

**Las configs no cargan al iniciar.**
Pon `Window:LoadAutoloadConfig()` al **final** del script, después de crear todos los elementos con `Flag`.

**¿Funciona en móvil?**
Sí. La ventana se adapta al tamaño de la pantalla, y la barra o el botón flotante sirven para abrir el menú.

**Quiero quitar la animación de entrada.**
`Kato:CreateWindow({ Intro = false, ... })`

**Quiero desactivar todas las animaciones.**
`Kato.Config.Animations = false` (o desde *Ajustes → Interfaz*).

---

<div align="center">

Hecho con 💜 para la comunidad de **Kato Hub**

</div>
