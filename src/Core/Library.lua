--!strict
--[[ Moon UI — Core/Library.lua
	The public singleton. Resolves a safe GUI parent (CoreGui / PlayerGui /
	gethui), exposes window creation, theme + icon management and global
	notifications. Supports MULTIPLE simultaneous windows. ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Window = require(script.Parent.Window)
local Theme = require(script.Parent.Parent.Systems.Theme)
local Icons = require(script.Parent.Parent.Systems.Icons)
local Notification = require(script.Parent.Parent.Systems.Notification)
local Signal = require(script.Parent.Parent.Util.Signal)
local Types = require(script.Parent.Parent.Util.Types)

local Library = {}
Library.__index = Library

local function resolveParent(): Instance
	-- Prefer an unobtrusive, persistent parent that survives respawns.
	local ok, hidden = pcall(function()
		return (gethui :: any)()
	end)
	if ok and hidden then
		return hidden
	end
	if RunService:IsStudio() then
		local lp = Players.LocalPlayer
		if lp then
			return lp:WaitForChild("PlayerGui")
		end
	end
	local successCore, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if successCore and coreGui then
		return coreGui
	end
	local lp = Players.LocalPlayer
	return lp and lp:WaitForChild("PlayerGui") or game:GetService("CoreGui")
end

function Library.new()
	local self = setmetatable({
		Version = "1.0.0",
		Theme = Theme,
		Icons = Icons,
		Windows = {} :: { any },
		ThemeChanged = Theme.Changed,
		_parent = resolveParent(),
	}, Library)
	return self
end

-- Create a new window. Multiple windows can coexist; each owns its own GUI.
function Library:CreateWindow(options: Types.WindowOptions?)
	local window = Window.new(self._parent, options or {})
	table.insert(self.Windows, window)
	window.Closed:Connect(function()
		local idx = table.find(self.Windows, window)
		if idx then
			table.remove(self.Windows, idx)
		end
	end)
	return window
end

-- Theme passthroughs --------------------------------------------------------
function Library:SetTheme(name: string)
	Theme.Set(name)
end
function Library:CreateTheme(name: string, base: string, overrides: { [string]: any })
	return Theme.Create(name, base, overrides)
end
function Library:RegisterTheme(theme: Types.Theme)
	Theme.Register(theme)
end
function Library:GetThemes(): { string }
	return Theme.List()
end

-- Icons ---------------------------------------------------------------------
function Library:SetIconPack(pack: any)
	Icons.SetPack(pack)
end

-- Global notification (uses the resolved parent, no window required).
function Library:Notify(options: Types.NotifyOptions)
	return Notification.push(self._parent, options)
end

-- Tear down every window this library created.
function Library:DestroyAll()
	for _, window in table.clone(self.Windows) do
		window:Destroy()
	end
	table.clear(self.Windows)
end

return Library
