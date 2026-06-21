--!strict
--[[
	Moon UI — Theme.lua
	Centralised theme engine with global design tokens.

	* Ships Dark + Light built-ins.
	* Supports custom theme registration and runtime switching.
	* Components register binders: (token -> applyFn). On theme change the engine
	  re-applies every binder, so live theme switching needs zero rebuilds and no
	  per-component theme listeners.
]]

local Signal = require(script.Parent.Parent.Util.Signal)
local Types = require(script.Parent.Parent.Util.Types)

local Theme = {}
Theme.Changed = Signal.new() :: Types.Signal<Types.Theme>

local function c(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- Shared scalars reused by both built-in themes.
local SCALARS = {
	CornerRadius = 8,
	Padding = 12,
	StrokeThickness = 1,
	AnimationSpeed = 1,
}

local Dark: Types.Theme = {
	Name = "Dark",
	Appearance = "Dark",
	Tokens = {
		Background = c(2, 2, 2),
		Surface = c(13, 13, 15),
		SurfaceVariant = c(22, 22, 26),
		Elevated = c(30, 30, 36),
		Primary = c(96, 132, 255),
		Accent = c(120, 150, 255),
		Text = c(244, 245, 250),
		SubText = c(168, 170, 182),
		MutedText = c(110, 112, 124),
		Border = c(38, 38, 46),
		Divider = c(28, 28, 34),
		Success = c(64, 196, 132),
		Warning = c(240, 184, 72),
		Danger = c(238, 96, 102),
		Info = c(96, 156, 248),
		Hover = c(40, 40, 48),
		Pressed = c(52, 52, 62),
		Selected = c(34, 38, 58),
		CornerRadius = SCALARS.CornerRadius,
		Padding = SCALARS.Padding,
		StrokeThickness = SCALARS.StrokeThickness,
		AnimationSpeed = SCALARS.AnimationSpeed,
	},
}

local Light: Types.Theme = {
	Name = "Light",
	Appearance = "Light",
	Tokens = {
		Background = c(245, 246, 249),
		Surface = c(255, 255, 255),
		SurfaceVariant = c(243, 244, 247),
		Elevated = c(255, 255, 255),
		Primary = c(72, 104, 240),
		Accent = c(96, 128, 255),
		Text = c(24, 26, 32),
		SubText = c(92, 96, 108),
		MutedText = c(150, 154, 166),
		Border = c(224, 226, 232),
		Divider = c(232, 234, 240),
		Success = c(40, 168, 110),
		Warning = c(214, 152, 32),
		Danger = c(214, 64, 72),
		Info = c(56, 120, 224),
		Hover = c(238, 240, 246),
		Pressed = c(228, 231, 240),
		Selected = c(228, 235, 255),
		CornerRadius = SCALARS.CornerRadius,
		Padding = SCALARS.Padding,
		StrokeThickness = SCALARS.StrokeThickness,
		AnimationSpeed = SCALARS.AnimationSpeed,
	},
}

local registry: Types.Dictionary<Types.Theme> = {
	Dark = Dark,
	Light = Light,
}

local active: Types.Theme = Dark

-- Binders: each is a function that re-styles a single property when the theme
-- changes. Stored in a keyed table so they can be removed on component destroy.
type Binder = (theme: Types.Theme) -> ()
local binders: { [any]: Binder } = {}
local binderId = 0

function Theme.Get(): Types.Theme
	return active
end

function Theme.Token(name: string): any
	return (active.Tokens :: any)[name]
end

function Theme.List(): { string }
	local names = {}
	for name in registry do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function Theme.Register(theme: Types.Theme)
	registry[theme.Name] = theme
end

-- Build a custom theme by overriding tokens of an existing base.
function Theme.Create(name: string, base: string, overrides: { [string]: any }): Types.Theme
	local baseTheme = registry[base] or Dark
	local tokens = table.clone(baseTheme.Tokens)
	local mutable = tokens :: any
	for k, v in overrides do
		mutable[k] = v
	end
	local theme: Types.Theme = {
		Name = name,
		Appearance = baseTheme.Appearance,
		Tokens = tokens,
	}
	Theme.Register(theme)
	return theme
end

function Theme.Set(name: string)
	local theme = registry[name]
	if not theme or theme == active then
		return
	end
	active = theme
	for _, fn in binders do
		fn(theme)
	end
	Theme.Changed:Fire(theme)
end

-- Register a binder; returns a disconnect-style cleanup function for Maids.
function Theme.Bind(fn: Binder): () -> ()
	binderId += 1
	local id = binderId
	binders[id] = fn
	fn(active) -- apply immediately
	return function()
		binders[id] = nil
	end
end

return Theme
