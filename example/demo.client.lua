--!strict
--[[ Moon UI — example/demo.client.lua
	A LocalScript demonstrating the full public API. With Rojo this is synced
	into StarterPlayerScripts. If you are loading Moon from a single bundled
	module, replace the require line with your own path / loadstring source. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Moon = require(ReplicatedStorage:WaitForChild("Moon"))

-- A custom theme created at runtime (overrides only what differs from Dark).
Moon:CreateTheme("Amoled", "Dark", {
	Background = Color3.fromRGB(0, 0, 0),
	Surface = Color3.fromRGB(8, 8, 10),
	Primary = Color3.fromRGB(140, 120, 255),
})

local Window = Moon:CreateWindow({
	Title = "Moon UI — Demo",
	Icon = "moon",
	Theme = "Dark",
	Acrylic = true,
	ToggleKey = Enum.KeyCode.RightShift,
	ConfigFolder = "MoonDemo",
	User = { Name = "script", SubText = "Advanced User" },
})

-- ── Main tab ────────────────────────────────────────────────────────────────
local Main = Window:CreateTab({ Name = "Main", Icon = "home" })
local Combat = Main:CreateSection({ Name = "Combat" })

Combat:CreateToggle({
	Name = "Kill Aura",
	Description = "Automatically attacks nearby targets.",
	Default = false,
	Flag = "killAura",
	Callback = function(value)
		print("Kill Aura:", value)
	end,
})

Combat:CreateSlider({
	Name = "Aura Range",
	Description = "Maximum reach in studs.",
	Min = 0, Max = 100, Default = 35, Increment = 1, Suffix = " studs",
	Flag = "auraRange",
	Callback = function(v) print("Range", v) end,
})

Combat:CreateKeybind({
	Name = "Panic Key",
	Mode = "Toggle",
	Default = Enum.KeyCode.F,
	Flag = "panicKey",
	Callback = function(active) print("Panic", active) end,
})

local Visuals = Main:CreateSection({ Name = "Visuals" })
Visuals:CreateDropdown({
	Name = "ESP Mode",
	Options = { "Off", "Box", "Skeleton", "Chams" },
	Default = "Box",
	Searchable = true,
	Flag = "espMode",
	Callback = function(v) print("ESP", v) end,
})
Visuals:CreateColorPicker({
	Name = "ESP Color",
	Default = Color3.fromRGB(120, 150, 255),
	Flag = "espColor",
	Callback = function(c) print("Color", c) end,
})
Visuals:CreateButton({
	Name = "Send Test Notification",
	Description = "Fires a sample toast.",
	Callback = function()
		Window:Notify({
			Title = "Hello",
			Content = "This is a Moon notification.",
			Variant = "Success",
			Duration = 4,
		})
	end,
})

-- ── Settings tab (Interface section like the reference) ──────────────────────
local Settings = Window:CreateTab({ Name = "Settings", Icon = "settings" })
local Interface = Settings:CreateSection({ Name = "Interface" })

Interface:CreateDropdown({
	Name = "Theme",
	Description = "Changes the interface theme.",
	Options = Moon:GetThemes(),
	Default = "Dark",
	Callback = function(name)
		Moon:SetTheme(name)
	end,
})

Interface:CreateTextbox({
	Name = "Config Name",
	Placeholder = "my-config",
	Default = "default",
	Flag = "configName",
})

local cfg = Window.Config
Interface:CreateButton({
	Name = "Save Config",
	Callback = function()
		cfg:Save("default")
		Window:Notify({ Content = "Configuration saved.", Variant = "Info" })
	end,
})
Interface:CreateButton({
	Name = "Reset Settings",
	Callback = function()
		Window:Dialog({
			Title = "Reset settings?",
			Content = "This cannot be undone.",
			Icon = "alert-triangle",
			Buttons = {
				{ Text = "Cancel", Variant = "Secondary" },
				{ Text = "Reset", Variant = "Danger", Callback = function()
					print("reset confirmed")
				end },
			},
		})
	end,
})

-- Restore saved values on launch.
cfg:SetAutoSave("default", true)
cfg:Load("default")
