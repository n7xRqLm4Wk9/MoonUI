# 🌙 Moon

A modern, high-performance, fully-typed **Roblox UI framework**. Moon is built
to feel like a professional open-source software framework — clean aesthetics,
a consistent design language, smooth motion, and an API that is a pleasure to
use — while scaling to thousands of elements across desktop, tablet and mobile.

```lua
local Moon = require(ReplicatedStorage.Moon)

local Window = Moon:CreateWindow({ Title = "Moon UI", Icon = "moon" })
local Tab    = Window:CreateTab({ Name = "Combat", Icon = "swords" })

Tab:CreateToggle({
    Name = "Kill Aura",
    Default = false,
    Callback = function(value) print(value) end,
})
```

## Highlights

- **Fully typed Luau** (`--!strict`) with a single shared `Types` module.
- **Modular architecture** — rendering, state, theming, components, icons,
  configuration, utilities and events are all separated.
- **Theme engine** with global design tokens, Dark + Light built-ins, runtime
  custom themes and zero-rebuild live switching.
- **Lucide icon system** with caching, hot-swapping and a pluggable data pack.
- **Reactive State** — components subscribe to observables; updates never rebuild
  the whole interface.
- **Centralised animation engine** (TweenService) with a consistent motion
  language and a global speed multiplier.
- **Robust config manager** — save / load / delete / import / export, auto-save,
  versioning and FNV-1a corruption protection. Degrades gracefully when no
  filesystem is available.
- **Adaptive & accessible** — touch-sized hit targets, responsive sidebar that
  collapses on mobile, keyboard/gamepad-aware input.
- **Multiple windows**, runtime element creation/destruction, and deterministic
  cleanup via per-component Maids (no leaks).

## Architecture

```
Moon/
├── init.lua                  -- returns a ready Library instance
└── src/
    ├── Util/                 -- foundations (no UI deps)
    │   ├── Types.lua         -- single source of truth for all types
    │   ├── Signal.lua        -- linked-list signal (no BindableEvents)
    │   ├── Maid.lua          -- deterministic lifecycle/cleanup
    │   ├── Create.lua        -- declarative instance builder
    │   ├── Platform.lua      -- device/input detection + adaptive sizing
    │   └── Dragger.lua       -- reusable mouse/touch drag
    ├── Systems/              -- cross-cutting engines
    │   ├── State.lua         -- observable value container
    │   ├── Theme.lua         -- tokens, themes, live binders
    │   ├── Animation.lua     -- TweenService presets & intent helpers
    │   ├── Icons.lua         -- Lucide resolution + caching
    │   ├── IconData.lua      -- pluggable Lucide pack (shape-stable)
    │   ├── Config.lua        -- versioned, checksummed persistence
    │   ├── Notification.lua  -- toast stack
    │   └── Dialog.lua        -- modal dialogs
    ├── Components/           -- view widgets
    │   ├── Base.lua          -- the canonical setting-row factory
    │   ├── Button / Toggle / Slider / Textbox / Keybind
    │   ├── Dropdown / ColorPicker
    │   └── Display.lua       -- Label, Paragraph, Divider, Badge, Progress
    └── Core/                 -- composition
        ├── Library.lua       -- the public singleton (CreateWindow, themes…)
        ├── Window.lua        -- shell: titlebar, sidebar, content, overlay
        ├── Tab.lua           -- page + sidebar button
        └── Section.lua       -- titled element group + element factories
```

**Dependency direction is strictly downward:** `Core → Components → Systems →
Util`. No module reaches "up", so there are no circular requires and any layer
can be tested in isolation.

## Installation

### Rojo
1. Clone this repo and run `rojo serve` (a `default.project.json` is included).
2. `Moon` is placed in `ReplicatedStorage`; the demo in `StarterPlayerScripts`.

### Single-file / executor
Concatenate `src` under `init.lua` or use your bundler of choice, then
`require` (or `loadstring` the bundled output).

## Public API

### Library
| Method | Description |
| --- | --- |
| `Moon:CreateWindow(opts)` | Create a window (supports many at once). |
| `Moon:CreateTheme(name, base, overrides)` | Build a custom theme at runtime. |
| `Moon:RegisterTheme(theme)` | Register a fully-specified theme. |
| `Moon:SetTheme(name)` | Switch theme live (no rebuild). |
| `Moon:GetThemes()` | List registered theme names. |
| `Moon:SetIconPack(pack)` | Swap in the full Lucide pack. |
| `Moon:Notify(opts)` | Global toast (no window required). |
| `Moon:DestroyAll()` | Tear down every window. |

### Window
`CreateTab`, `SelectTab`, `Notify`, `Dialog`, `SaveConfig`, `LoadConfig`,
`SetTheme`, `Minimize`, `ToggleMaximize`, `ToggleVisibility`, `Close`,
`Destroy`. Exposes `.Config`, `.OverlayLayer`, and a `Closed` signal.

### Tab / Section
`Tab:CreateSection(opts)` plus every `Create*` method (proxied to a default
section for convenience). Sections expose:
`CreateButton, CreateToggle, CreateSlider, CreateTextbox, CreateKeybind,
CreateDropdown, CreateColorPicker, CreateLabel, CreateParagraph,
CreateDivider, CreateBadge, CreateProgress`.

Every component returns a handle with runtime control (`:Set`, `:Get`,
`:OnChanged`, `:Destroy`, …) and, where applicable, a `.State` observable for
state binding.

## Theme tokens

`Background, Surface, SurfaceVariant, Elevated, Primary, Accent, Text, SubText,
MutedText, Border, Divider, Success, Warning, Danger, Info, Hover, Pressed,
Selected, CornerRadius, Padding, StrokeThickness, AnimationSpeed`.

```lua
Moon:CreateTheme("Amoled", "Dark", {
    Background = Color3.new(0, 0, 0),
    Primary = Color3.fromRGB(140, 120, 255),
})
Moon:SetTheme("Amoled")
```

## Icons (Lucide)

Moon ships a curated starter set wired for a 16×16 / 256px spritesheet. To embed
the **full** Lucide set, upload a generated spritesheet, then provide a pack
matching `IconData.Pack`:

```lua
Moon:SetIconPack({
    Sheets = { ["1"] = "rbxassetid://YOUR_SHEET" },
    Map = { ["moon"] = { Sheet = "1", Offset = Vector2.new(0,0), Size = Vector2.new(256,256) }, ... },
})
```

Icons accept a Lucide name (`"swords"`), a `rbxassetid://…` string, or a numeric
asset id — anywhere an `Icon` field appears (tabs, buttons, notifications,
dialogs, labels).

## Configuration

```lua
local cfg = Window.Config
cfg:SetAutoSave("default", true)   -- debounced auto-save on any flag change
cfg:Save("default"); cfg:Load("default"); cfg:Delete("old")
local raw = cfg:Export("default")  -- share/copy
cfg:Import("imported", raw)
```

Any component given a `Flag` is automatically persisted. Non-JSON values
(`Color3`, `EnumItem`) are encoded/decoded transparently. Payloads are versioned
and checksummed; corrupt or tampered files are rejected rather than applied.

## License

MIT © 2026 Moon UI.
